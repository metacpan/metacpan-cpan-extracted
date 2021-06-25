package Tags::HTML::GradientIndicator;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# 'CSS::Struct::Output' object.
	$self->{'css'} = undef;

	# Default gradient is left-right direction from red to violet.
	$self->{'css_background_image'} = 'linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet)';

	# Gradient CSS class.
	$self->{'css_gradient_class'} = 'gradient';

	# Height.
	$self->{'height'} = 30;

	# Unit.
	$self->{'unit'} = 'px';

	# Width.
	$self->{'width'} = 500;

	# 'Tags::Output' object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'CSS::Struct::Output' object.
	if ($self->{'css'} && ! $self->{'css'}->isa('CSS::Struct::Output')) {
		err "Parameter 'css' must be a 'CSS::Struct::Output::*' class.";
	}

	# Check to 'Tags' object.
	if (! $self->{'tags'} || ! $self->{'tags'}->isa('Tags::Output')) {
		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub process {
	my ($self, $percent_value) = @_;

	# Value.
	my $value = $percent_value * ($self->{'width'} / 100);

	# Main stars.
	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'style', 'width: '.$value.$self->{'unit'}.';overflow: hidden;'],

		['b', 'div'],
		['a', 'class', $self->{'css_gradient_class'}],
		['e', 'div'],

		['e', 'div'],
	);

	return;
}

# Process 'CSS::Struct'.
sub process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_gradient_class'}],
		['d', 'height', $self->{'height'}.$self->{'unit'}],
		['d', 'width', $self->{'width'}.$self->{'unit'}],
		['d', 'background-color', 'red'],
		['d', 'background-image', $self->{'css_background_image'}],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::GradientIndicator - Tags helper for gradient evaluation.

=head1 SYNOPSIS

 use Tags::HTML::GradientIndicator;

 my $obj = Tags::HTML::GradientIndicator->new(%params);
 $obj->process($stars_hr);
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::GradientIndicator->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

It's required.

Default value is undef.

=item * C<css_background_image>

CSS parameter for background-image of gradient.

Default value is 'linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet)'.

=item * C<css_gradient_class>

CSS class name for gradient.

Default value is 'gradient'.

=item * C<height>

Indicator height.

Default value is 30.

=item * C<unit>

Unit for height and width.

Default value is 'px'.

=item * C<width>

Indicator width.

Default value is 500.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process($percent_value);

Process Tags structure for gradient.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'tags' must be a 'Tags::Output::*' class.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::GradientIndicator;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::GradientIndicator->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process indicator.
 $obj->process_css;
 $obj->process(50);

 # Print out.
 print "CSS\n";
 print $css->flush."\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .gradient {
 #         height: 30px;
 #         width: 500px;
 #         background-color: red;
 #         background-image: linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet);
 # }
 # HTML
 # <div style="width: 250px;overflow: hidden;">
 #   <div class="gradient">
 #   </div>
 # </div>

=head1 EXAMPLE2

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::GradientIndicator;
 use Tags::Output::Indent;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 percent\n";
         exit 1;
 }
 my $percent = $ARGV[0];

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::GradientIndicator->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process indicator.
 $obj->process_css;
 $obj->process($percent);

 # Print out.
 print "CSS\n";
 print $css->flush."\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output for 30:
 # CSS
 # .gradient {
 #         height: 30px;
 #         width: 500px;
 #         background-color: red;
 #         background-image: linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet);
 # }
 # HTML
 # <div style="width: 150px;overflow: hidden;">
 #   <div class="gradient">
 #   </div>
 # </div>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Stars>

Tags helper for stars evaluation.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-GradientIndicator>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021

BSD 2-Clause License

=head1 VERSION

0.02

=cut
