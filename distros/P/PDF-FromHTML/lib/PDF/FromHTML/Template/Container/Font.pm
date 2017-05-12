package PDF::FromHTML::Template::Container::Font;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

my @current_font = ();

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{EMBED} = 0 unless defined $self->{EMBED};

    return $self;
}

sub render
{
    my $self = shift;
    my ($context) = @_;
    my $p = $context->{PDF};

    my $size = $context->get($self, 'H') ||
        $context->get($self, 'SIZE') ||
        die "Height not set by the time <font> was rendered", $/;
    my $face = $context->get($self, 'FACE') ||
        die "Face not set by the time <font> was rendered", $/;

    my $font = $context->retrieve_font($face);
    $font == -1 && die "Font not found for '$face' by the time <font> was rendered", $/;

    $p->font($font, $size);

    push @current_font, [ $font, $size ];

    return 1 unless @{$self->{ELEMENTS}};

    my $child_success = $self->iterate_over_children($context);

    pop @current_font;

    return $child_success unless @current_font;

    $p->font(@{$current_font[-1]});

    return $child_success;
}

sub mark_as_rendered {}

sub begin_page
{
    my $self = shift;
    my ($context) = @_;

    my $face = $context->get($self, 'FACE') ||
        die "Face not set by the time <font> was rendered", $/;

    unless ($context->retrieve_font($face))
    {
        my $encoding = $context->get($self, 'PDF_ENCODING') || 'host';

        my $font = $context->{PDF}->find_font(
            $face,
            $encoding,
            $context->get($self, 'EMBED'),
        ) or die "Font not found for '$face' by the time <font> was rendered", $/;

        $context->store_font($face, $font);
    }

    return $self->SUPER::begin_page($context);
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Font

=head1 PURPOSE

To specify the font used for TEXTBOX nodes

=head1 NODE NAME

FONT

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * FACE - this is required. It must be a legal font face recognized by
PDFLib. (q.v. for more details)

=item * H - the point size of the font. 

=back

=head1 CHILDREN

None

=head1 AFFECTS

The font used when rendering a TEXTBOX

=head1 DEPENDENCIES

None

=head1 USAGE

  <font face="Times-Roman" h="8">

    ... Children will be rendered in 8-point TimesRoman font ...

  </font>

Please note that not specifying a FONT tag will result in a PDFLib error when
the first TEXTBOX attempts to render. Since not all PDF documents involve text,
PDF::FromHTML::Template does not require a FONT tag.

(I might require a FONT tag if a TEXTBOX tag exists, but only after the non-
standard behavior of FONT is fixed. q.v. the NOTE below.)

=head1 NOTE

For backwards compatability, a stand-alone FONT tag will be treated as if it is
the parent for all nodes until the end of the parent node. This behavior is
deprecated and will be removed in a future release.

  <pagedef>

    ... Children here aren't affected by the FONT tag below ...

    <font face="Times-Roman" h="8"/>

    ... Children here _ARE_ affected by the FONT tag above ...

  </pagedef>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
