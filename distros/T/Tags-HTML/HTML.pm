package Tags::HTML;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# 'CSS::Struct::Output' object.
	$self->{'css'} = undef;

	# No CSS support.
	$self->{'no_css'} = 0;

	# 'Tags::Output' object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'CSS::Struct::Output' object.
	if (! $self->{'no_css'} && defined $self->{'css'}
		&& ! $self->{'css'}->isa('CSS::Struct::Output')) {

		err "Parameter 'css' must be a 'CSS::Struct::Output::*' class.";
	}

	# Check to 'Tags' object.
	if (defined $self->{'tags'} && ! $self->{'tags'}->isa('Tags::Output')) {
		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub process {
	my ($self, @params) = @_;

	if (! defined $self->{'tags'}) {
		err "Parameter 'tags' isn't defined.";
	}

	$self->_process(@params);

	return;
}

# Process 'CSS::Struct'.
sub process_css {
	my ($self, @params) = @_;

	# No CSS support.
	if ($self->{'no_css'}) {
		return;
	}

	if (! defined $self->{'css'}) {
		err "Parameter 'css' isn't defined.";
	}

	$self->_process_css(@params);

	return;
}

sub _process {
	my ($self, @params) = @_;

	err "Need to be implemented in inherited class in _process() method.";

	return;
}

sub _process_css {
	my ($self, @params) = @_;

	err "Need to be implemented in inherited class in _process_css() method.";

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML - Tags helper abstract class.

=head1 SYNOPSIS

 use Tags::HTML;

 my $obj = Tags::HTML->new(%params);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML->new(%params);

Constructor.

Returns instance of class.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<no_css>

No CSS support flag.
If this flag is set to 1, L<process_css()> returns undef.

Default value is 0.

=item * C<tags>

'Tags::Output' object for L<process> processing.

Default value is undef.

=back

=head2 C<process>

 $obj->process;

Process Tags structure.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         Need to be implemented in inherited class in _process() method.
         Parameter 'tags' isn't defined.

 process_css():
         Need to be implemented in inherited class in _process_css() method.
         Parameter 'css' isn't defined.

=head1 EXAMPLE

 use strict;
 use warnings;

 package Foo;

 use base qw(Tags::HTML);

 sub _process {
         my ($self, $value) = @_;

         $self->{'tags'}->put(
                 ['b', 'div'],
                 ['d', $value],
                 ['e', 'div'],
         );

         return;
 }

 sub _process_css {
         my ($self, $color) = @_;

         $self->{'css'}->put(
                 ['s', 'div'],
                 ['d', 'background-color', $color],
                 ['e'],
         );

         return;
 }

 package main;

 use CSS::Struct::Output::Indent;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Foo->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process indicator.
 $obj->process_css('red');
 $obj->process('value');

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # div {
 # 	background-color: red;
 # }
 #
 # HTML
 # <div>
 #   value
 # </div>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Plack::App::Tags::HTML>

Plack application for Tags::HTML objects.

=item L<Plack::Component::Tags::HTML>

Plack component for Tags with HTML output.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021-2022

BSD 2-Clause License

=head1 VERSION

0.03

=cut
