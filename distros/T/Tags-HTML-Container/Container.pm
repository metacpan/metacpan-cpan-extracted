package Tags::HTML::Container;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Readonly;

Readonly::Array our @HORIZ_ALIGN => qw(center left right);
Readonly::Array our @VERT_ALIGN => qw(base bottom center fit top);
Readonly::Hash our %VERT_CONV => (
	'base' => 'baseline',
	'bottom' => 'flex-end',
	'center' => 'center',
	'fit' => 'stretch',
	'top' => 'flex-start',
);

our $VERSION = 0.05;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_container', 'css_inner', 'height', 'horiz_align', 'vert_align'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Container align.
	$self->{'horiz_align'} = 'center';
	$self->{'vert_align'} = 'center';

	# CSS classes.
	$self->{'css_container'} = 'container';
	$self->{'css_inner'} = 'inner';

	# Height.
	$self->{'height'} = '100vh';

	# Process params.
	set_params($self, @{$object_params_ar});

	if (! defined $self->{'horiz_align'}) {
		err "Parameter 'horiz_align' is required.";
	}
	if (none { $self->{'horiz_align'} eq $_ } @HORIZ_ALIGN) {
		err "Parameter 'horiz_align' have a bad value.",
			'Value', $self->{'horiz_align'},
		;
	}

	if (! defined $self->{'vert_align'}) {
		err "Parameter 'vert_align' is required.";
	}
	if (none { $self->{'vert_align'} eq $_ } @VERT_ALIGN) {
		err "Parameter 'vert_align' have a bad value.",
			'Value', $self->{'vert_align'},
		;
	}

	# Object.
	return $self;
}

sub _cleanup {
	my ($self, $cleanup_cb) = @_;

	if (defined $cleanup_cb) {
		$cleanup_cb->($self);
	}

	return;
}

sub _init {
	my ($self, $init_cb) = @_;

	if (defined $init_cb) {
		$init_cb->($self);
	}

	return;
}

sub _prepare {
	my ($self, $prepare_cb) = @_;

	if (defined $prepare_cb) {
		$prepare_cb->($self);
	}

	return;
}

sub _process {
	my ($self, $tags_cb) = @_;

	if (! defined $tags_cb) {
		err "There is no contained callback with Tags code.";
	}

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_container'}],
		['b', 'div'],
		['a', 'class', $self->{'css_inner'}],
	);
	$tags_cb->($self);
	$self->{'tags'}->put(
		['e', 'div'],
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my ($self, $css_cb) = @_;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_container'}],
		['d', 'display', 'flex'],
		['d', 'align-items', $VERT_CONV{$self->{'vert_align'}}],
		['d', 'justify-content', $self->{'horiz_align'}],
		['d', 'height', $self->{'height'}],
		['e'],
	);
	if (defined $css_cb) {
		$css_cb->($self);
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Container - Tags helper for container.

=head1 SYNOPSIS

 use Tags::HTML::Container;

 my $obj = Tags::HTML::Container->new(%params);
 $obj->cleanup($cleanup_cb);
 $obj->init($init_cb);
 $obj->prepare($prepare_cb);
 $obj->process($tags_cb);
 $obj->process_css($css_cb);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Container->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_container>

CSS class for container box.

Default value is 'container'.

=item * C<css_inner>

CSS class for inner box in container.

Default value is 'inner'.

=item * C<height>

Container height in CSS style.

Default value is '100vh'.

=item * C<horiz_align>

Horizontal align.

Possible values are: center left right

Default value is 'center'.

=item * C<vert_align>

Vertical align.

Possible values are: base bottom center fit top

Default value is 'center'.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup($cleanup_cb);

Cleanup L<Tags::HTML> object for container with code defined in C<$cleanup_cb> callback.
This callback has one argument and this is C<$self> of container object.

Returns undef.

=head2 C<init>

 $obj->init($init_cb);

Initialize L<Tags::HTML> object (in page run) for container with code defined in C<$init_cb> callback.
This callback has one argument and this is C<$self> of container object.

Returns undef.

=head2 C<prepare>

 $obj->prepare($prepare_cb);

Prepare L<Tags::HTML> object (in page preparation) for container with code defined in C<$prepare_cb> callback.
This callback has one argument and this is C<$self> of container object.

Returns undef.

=head2 C<process>

 $obj->process($tags_cb);

Process L<Tags> structure for container with code defined in C<$tags_cb> callback.
This callback has one argument and this is C<$self> of container object.
C<$tags_cb> is required argument.

Returns undef.

=head2 C<process_css>

 $obj->process_css($css_cb);

Process L<CSS::Struct> structure for output with code defined in C<$css_cb>
callback. This callback has one argument and this is C<$self> of container
object. C<$css_cb> is optional argument.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Parameter 'horiz_align' is required.
         Parameter 'horiz_align' have a bad value.
                 Value: %s
         Parameter 'vert_align' is required.
         Parameter 'vert_align' have a bad value.
                 Value: %s

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         There is no contained callback with Tags code.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=container_with_text.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Container;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Container->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process container with text.
 $obj->process(sub {
         my $self = shift;
         $self->{'tags'}->put(
                 ['d', 'Hello World!'],
         );
         return;
 });
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <div class="container">
 #   <div class="inner">
 #     Hello World!
 #   </div>
 # </div>
 # 
 # .container {
 #         display: flex;
 #         align-items: center;
 #         justify-content: center;
 #         height: 100vh;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>,
L<Tags::HTML>,

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Container>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
