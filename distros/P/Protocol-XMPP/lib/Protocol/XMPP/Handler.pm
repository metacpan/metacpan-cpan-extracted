package Protocol::XMPP::Handler;
$Protocol::XMPP::Handler::VERSION = '0.006';
use strict;
use warnings;
use parent qw(XML::SAX::Base);

=head1 NAME

=head1 SYNOPSIS

=head1 VERSION

Version 0.006

=head1 DESCRIPTION

=head1 METHODS

=cut

use Module::Load ();

# mainly used for debugging / tracing which modules were loaded
my %ClassLoaded;

sub class_from_element {
	my $self = shift;
	my $name = shift;
	# Allow entries on the stack to have the first
	# go at handling the element.
	if($self->{stack} && $self->{stack}[-1]) {
		my $local = $self->{stack}[-1]->class_from_element($name);
		return $local if $local;
	}
	my $class = {
		'unknown'		=> '',

		'stream:features'	=> 'Protocol::XMPP::Element::Features',
		'iq'			=> 'Protocol::XMPP::Element::IQ',
		'feature'		=> 'Protocol::XMPP::Element::Feature',
		'bind'			=> 'Protocol::XMPP::Element::Bind',
		'session'		=> 'Protocol::XMPP::Element::Session',
		'mechanism'		=> 'Protocol::XMPP::Element::Mechanism',
		'mechanisms'		=> 'Protocol::XMPP::Element::Mechanisms',
		'auth'			=> 'Protocol::XMPP::Element::Auth',
		'challenge'		=> 'Protocol::XMPP::Element::Challenge',
		'response'		=> 'Protocol::XMPP::Element::Response',
		'success'		=> 'Protocol::XMPP::Element::Success',
		'register'		=> 'Protocol::XMPP::Element::Register',
		'starttls'		=> 'Protocol::XMPP::Element::StartTLS',
		'proceed'		=> 'Protocol::XMPP::Element::Proceed',
		'jid'			=> 'Protocol::XMPP::Element::JID',
		'presence'		=> 'Protocol::XMPP::Element::Presence',

		'html'			=> 'Protocol::XMPP::Element::HTML',

		'message'		=> 'Protocol::XMPP::Element::Message',
		'body'			=> 'Protocol::XMPP::Element::Body',
		'subject'		=> 'Protocol::XMPP::Element::Subject',
		'active'		=> 'Protocol::XMPP::Element::Active',
		'nick'			=> 'Protocol::XMPP::Element::Nick',
		'stream:stream'	=> 'Protocol::XMPP::Element::Stream',
	}->{$name || 'unknown'} or return '';
	unless($ClassLoaded{$class}) {
		Module::Load::load($class);
		++$ClassLoaded{$class};
	}
	return $class;
}

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);
	$self->{stream} = delete $args{stream};
	return $self;
}

sub stream { shift->{stream} }

sub debug {
	my $self = shift;
	$self->stream->debug(@_);
}

sub parent {
	my $self = shift;
	my ($parent) = grep { defined } reverse @{$self->{stack} ||= []};
	return $parent;
}

=head2 start_element

=cut

sub start_element {
	my $self = shift;
	my $element = shift;

# Find an appropriate class for this element
	my $v = $element->{Name};
	my $class = $self->class_from_element($v);

	if($class) {
		my $obj = $class->new(
			element => $element,
			stream => $self->{stream},
			parent => $self->parent
		);
		push @{$self->{stack}}, $obj;
	} else {
		$self->debug("Not sure about the element for $v");
		push @{$self->{stack}}, undef;
	}
	return $self->SUPER::start_element($element);
}

=head2 end_element

=cut

sub end_element {
	my $self = shift;
	my $data = shift;
	# warn "=> Element [" . $data->{Name} . "] ends";
	my $obj = pop @{$self->{stack}};
	if($obj) {
		$obj->end_element($data);
	}
	return $self->SUPER::end_element($data);
}

=head2 characters

=cut

sub characters {
	my $self = shift;
	my $data = shift;
	if(@{$self->{stack}}) {
		my $obj = $self->{stack}[-1];
		$obj->characters($data->{Data}) if $obj;
	}
	return $self->SUPER::characters($data);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
