package PDF::Template::Element::Image;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::Template::Element);

    use PDF::Template::Element;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TXTOBJ} = PDF::Template::Factory->create('TEXTOBJECT');

    return $self;
}

my %convertImageType = (
    'jpg' => 'jpeg',
);

sub begin_page
{
    my $self = shift;
    my ($context) = @_;

    return 1 if $context->{CALC_LAST_PAGE};

    my $txt = $context->get($self, 'FILENAME') ||
        $self->{TXTOBJ}->resolve($context) ||
        die "Image does not have a filename", $/;

    my $image = $context->retrieve_image($txt);
    unless ($image)
    {
        # automatically resolve type if extension is obvious and type was not specified
        my $type = $context->get($self, 'TYPE');
        unless ($type)
        {
            ($type) = $txt =~ /\.(\w+)$/o;
        }
        unless ($type)
        {
            die "Undefined type for <image> '$txt'", $/;
        }

        $type = lc $type;
        $type = $convertImageType{$type} if exists $convertImageType{$type};

        $image = pdflib_pl::PDF_open_image_file($context->{PDF}, $type, $txt, '', 0);
        $image == -1 and die "Cannot open <image> file '$txt'", $/;

        $context->store_image($txt, $image);
    }

    $self->{IMAGE_HEIGHT} = pdflib_pl::PDF_get_value($context->{PDF}, 'imageheight', $image);
    $self->{IMAGE_WIDTH}  = pdflib_pl::PDF_get_value($context->{PDF}, 'imagewidth', $image);

    die "Image '$txt' has 0 (or less) height.", $/ if $self->{IMAGE_HEIGHT} <= 0;
    die "Image '$txt' has 0 (or less) width.", $/  if $self->{IMAGE_WIDTH} <= 0;

    return 1;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    return 1 if $context->{CALC_LAST_PAGE};

    my $txt = $context->get($self, 'FILENAME') ||
        $self->{TXTOBJ}->resolve($context) ||
        die "Image does not have a filename", $/;

    my $image = $context->retrieve_image($txt);
    $image == -1 && die "Image not found for '$txt' when <image> is rendered.", $/;

    $self->set_values($context, $txt);

    my ($x, $y, $scale) = map { $context->get($self, $_) } qw(X Y SCALE);

    pdflib_pl::PDF_place_image(
        $context->{PDF},
        $image, $x, $y, $scale,
    );

    if ($context->get($self, 'BORDER'))
    {
        pdflib_pl::PDF_save($context->{PDF});

        $self->set_color($context, 'COLOR', 'both');

        my ($w, $h) = map { $context->get($self, $_) } qw(W H);

        pdflib_pl::PDF_rect(
            $context->{PDF},
            $x, $y, $w, $h,
        );
        pdflib_pl::PDF_stroke($context->{PDF});

        pdflib_pl::PDF_restore($context->{PDF});
    }

    return 1;
}

sub set_values
{
    my $self = shift;
    my ($context, $txt) = @_;

    my $scale = $context->get($self, 'SCALE');

    if (defined $scale)
    {
        die "Scale is zero or less when rendering <image> '$txt'.", $/ if $scale <= 0;
        $self->{W} = $self->{IMAGE_WIDTH}  * $scale;
        $self->{H} = $self->{IMAGE_HEIGHT} * $scale;
    }
    else
    {
        my ($w, $h) = map { $context->get($self, $_) } qw(W H);
        if (defined $w && defined $h)
        {
            die "Height of zero or less in <image> '$txt'.", $/ if $h <= 0;
            die "Width of zero or less in <image> '$txt'.", $/ if $w <= 0;

            my $test_scale = $w / $h;
            if ($test_scale == ($self->{IMAGE_WIDTH}/$self->{IMAGE_HEIGHT}))
            {
                $self->{SCALE} = $test_scale;
            }
            else
            {
                undef $h;
            }
        }

        if (defined $w)
        {
            $self->{SCALE} = $w / $self->{IMAGE_WIDTH};
            $self->{H} = $self->{IMAGE_HEIGHT} * $scale;
        }
        elsif (defined $h)
        {
            $self->{SCALE} = $h / $self->{IMAGE_HEIGHT};
            $self->{W} = $self->{IMAGE_WIDTH} * $scale;
        }
        else
        {
            $self->{SCALE} = 0.5;
            $self->{W} = $self->{IMAGE_WIDTH}  * $self->{SCALE};
            $self->{H} = $self->{IMAGE_HEIGHT} * $self->{SCALE};
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

PDF::Template::Element::Image

=head1 PURPOSE

To embed images

=head1 NODE NAME

IMAGE

=head1 INHERITANCE

PDF::Template::Element

=head1 ATTRIBUTES

=over 4

=item * FILENAME
This is the filename for the image.

=item * TYPE
If the image type is not specified in the filename, specify it here.

=item * SCALE / W / H
This is used to scale the image. SCALE is a value by which the image's height
and width will be multiplied to arrive at the final height and width. Or, you
can set W and or H, as the width (or height) you want the image to have, once
scaled.

The algorithm used to calculate scaling has changed, somewhat, from v0.05. It
should result in better calculations, as it tries more avenues. Ultimately, if
it cannot figure out what to do, it will set a SCALE of 0.5 and go from there.

=item * BORDER
This is a boolean, used to specify if you want to draw a border around the image

=item * COLOR
Ignored unless BORDER is specified. This is the color of the border.

=back 4

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <image filename="$Image1"/>

  <image><var name="Image1"/></image>

In both cases, the image specified by the parameter "Image1" will be placed at
the current X/Y position.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut
