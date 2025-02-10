package Tags::HTML::Icon;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Scalar::Util qw(blessed);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style for list.
	$self->{'css_class'} = 'icon';

	# Process params.
	set_params($self, @{$object_params_ar});

	check_css_class($self, 'css_class');

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_icon'};

	return;
}

sub _init {
	my ($self, $icon) = @_;

	if (! defined $icon) {
		err 'Icon object is required.';
	}
	if (! blessed($icon) || ! $icon->isa('Data::Icon')) {
		err "Icon object must be a instance of 'Data::Icon'.";
	}

	$self->{'_icon'} = $icon;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_icon'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'span'],
		['a', 'class', $self->{'css_class'}],
	);
	if (defined $self->{'_icon'}->url) {
		$self->{'tags'}->put(
			['b', 'img'],
			defined $self->{'_icon'}->alt ? (
				['a', 'alt', $self->{'_icon'}->alt],
			) : (),
			['a', 'src', $self->{'_icon'}->url],
			['e', 'img'],
		);
	} else {
		my @style;
		if (defined $self->{'_icon'}->bg_color) {
			push @style, 'background-color:'.$self->{'_icon'}->bg_color.';';
		}
		if (defined $self->{'_icon'}->color) {
			push @style, 'color:'.$self->{'_icon'}->color.';';
		}
		$self->{'tags'}->put(
			@style ? (
				['b', 'span'],
				['a', 'style', (join '', @style)],
			) : (),
			['d', $self->{'_icon'}->char],
			@style ? (
				['e', 'span'],
			) : (),
		);
	}
	$self->{'tags'}->put(
		['e', 'span'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_icon'}) {
		return;
	}

	$self->{'css'}->put(
		# ['s', '.'.$self->{'css_class'}],
		# No default CSS code.
		# ['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Icon - Tags helper for HTML icon.

=head1 DESCRIPTION

L<Tags> helper to print HTML code of icon defined by L<Data::Icon>.

The HTML code contains icon defined by URL and alternate text (optional)
or by UTF-8 character with foregroun and backround colors (optional).

=head1 SYNOPSIS

 use Tags::HTML::Icon;

 my $obj = Tags::HTML::Icon->new(%params);
 $obj->cleanup;
 $obj->init($icon);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Icon->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

Default value is 'info-box'.

=item * C<lang>

Language in ISO 639-1 code.

Default value is undef.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

In this case cleanup internal representation of a set by L<init>.

Returns undef.

=head2 C<init>

 $obj->init($icon);

Process initialization in page run.

Accepted C<$icon> is L<Data::Icon>.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Do nothing in case of this object.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for HTML a element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for HTML a element to output.

Default CSS doesn't exist.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head1 ERRORS

 new():
         From Mo::utils::CSS::check_css_class():
                 Parameter '%s' has bad CSS class name.
                         Value: %s
                 Parameter '%s' has bad CSS class name (number on begin).
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Icon object is required.
         Icon object must be a instance of 'Data::Icon'.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=create_and_print_icon.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::Icon;
 use Tags::HTML::Icon;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Icon->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for icon.
 my $icon = Data::Icon->new(
         'bg_color' => 'grey',
         'char' => decode_utf8('†'),
         'color' => 'red',
 );

 # Initialize.
 $obj->init($icon);

 # Process.
 $obj->process;
 $obj->process_css;

 # Print out.
 print "HTML:\n";
 print encode_utf8($tags->flush);
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <span class="icon">
 #   <span style="background-color:grey;color:red;">
 #     †
 #   </span>
 # </span>
 # 
 # CSS:
 # 

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Mo::utils::CSS>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Icon>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
