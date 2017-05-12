package Net::Async::HTTP::DAV::XML;
$Net::Async::HTTP::DAV::XML::VERSION = '0.001';
use strict;
use warnings;

use parent qw(XML::SAX::Base);

use Date::Parse qw(str2time);

my %handler = (
	'D:response'	=> {
		start	=> sub {
			my ($self, $tag, $data) = @_;
			$self->{item} = {};
		},
		end	=> sub {
			my ($self, $tag, $data) = @_;
			my $item = $self->{item};
			$item->{modified} ||= str2time(delete $item->{lastmodifieddate}) if exists $item->{lastmodifieddate};
			$item->{modified} ||= str2time(delete $item->{getlastmodifieddate}) if exists $item->{getlastmodifieddate};
			$item->{modified} ||= str2time(delete $item->{getlastmodified}) if exists $item->{getlastmodified};
			$item->{size} = delete $item->{getcontentlength} if exists $item->{getcontentlength};
			$item->{type} = ((delete $item->{resourcetype}) // '' eq 'collection') ? 'directory' : 'file';
			$item->{path} = delete $item->{href} if exists $item->{href};
			$item->{displayname} = '.' if $item->{path} eq ($self->{path} // '');
			($item->{displayname}) = $item->{path} =~ m{([^/]+)$} unless defined $item->{displayname};
			$self->maybe_invoke('on_item', $item);
			delete $self->{item};
		},
	},
	'D:multistatus'	=> {
		end	=> sub { my ($self, $tag, $data) = @_; $self->maybe_invoke('on_complete'); }
	},
	'D:collection'	=> {
		start	=> sub {
			my ($self, $tag, $data) = @_;
			(my $name = $tag->{Name}) =~ s/^D://;
			$self->{item}->{resourcetype} = $name if $self->{stack}[1]{Name} eq 'D:resourcetype';
		}
	},
);

foreach my $type (qw(
	creationdate
	getlastmodified
	getetag
	displayname
	getcontentlanguage
	getcontentlength
	getcontenttype
	immutable
	lastmodifieddate
	resourceid
	resourcetype
	src
	dst
	read-only
	href
)) {
	$handler{"lp1:$type"} = $handler{"D:$type"} = {
		start	=> sub { my $self = shift; $self->{item}->{$type} = ''; },
		end	=> sub { my $self = shift; $self->maybe_invoke('on_item_property', $self->{item}, $type, $self->{item}->{$type}); },
		content	=> sub { my $self = shift; $self->{item}->{$type} .= $_[0]; },
	};
}


sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);
	$self->{$_} = delete $args{$_} for grep { /^on_/ } keys %args;
	$self->{dav} = delete $args{dav};
	$self->{href} = delete $args{href};
	$self->{stack} = [];
	return $self;
}

sub dav { shift->{dav} }

sub debug {
	my $self = shift;
	$self->dav->debug(@_);
}

=head2 start_element

=cut

sub start_element {
	my $self = shift;
	my $element = shift;
	unshift @{$self->{stack}}, $element;
	if(my $handler = $handler{$element->{Name}}->{start}) {
		$handler->($self, $element);
		return $self->SUPER::start_element($element);
	}

# Find an appropriate class for this element
	my $v = $element->{Name};
#	warn "Had unhandled $v\n";
	return $self->SUPER::start_element($element);
}

=head2 end_element

=cut

sub end_element {
	my $self = shift;
	my $element = shift;
	shift @{$self->{stack}};
	if(my $handler = $handler{$element->{Name}}->{end}) {
		$handler->($self);
		return $self->SUPER::end_element($element);
	}
	return $self->SUPER::end_element($element);
}

=head2 characters

=cut

sub characters {
	my $self = shift;
	my $element = $self->{stack}->[0];
	if(my $handler = $handler{$element->{Name}}->{content}) {
		$handler->($self, $_[0]->{Data});
		return $self->SUPER::characters(@_);
	}
	return $self->SUPER::characters(@_);
}

sub on_item_property {
	my $self = shift;
	my ($item, $k, $v) = @_;
	$v //= '';
#	warn " $k => $v\n";
}

sub maybe_invoke {
	my $self = shift;
	my $type = shift;
	my $code = $self->{$type} || $self->can($type);
	return unless $code;
	return $code->(@_);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2014. Licensed under the same terms as Perl itself.

