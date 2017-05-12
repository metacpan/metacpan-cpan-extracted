package PDF::FromHTML::Template::Container::PageDef;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;

}
use PDF::FromHTML::Template::Constants qw( %Verify );

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{NOPAGENUMBER} = 0 unless defined $self->{NOPAGENUMBER};

    $self->{MARGINS} = 0 unless exists $self->{MARGINS};
    $self->{$_} = $self->{MARGINS} for grep !exists $self->{$_}, qw(LEFT_MARGIN RIGHT_MARGIN);

    return $self;
}

sub find_margin_heights
{
    my $self = shift;
    my ($context) = @_;

    my ($header_height, $footer_height) = (undef, undef);

    my $sub;
    $sub = sub {
        my $obj = shift;

        $obj->enter_scope($context) unless $obj->isa('PAGEDEF');

        if ($obj->isa('HEADER'))
        {
            die "Cannot have two <header> tags in the same <pagedef>", $/ if defined $header_height;
            $header_height = $context->get($obj, 'HEADER_HEIGHT');
        }
        elsif ($obj->isa('FOOTER'))
        {
            die "Cannot have two <footer> tags in the same <pagedef>", $/ if defined $footer_height;
            $footer_height = $context->get($obj, 'FOOTER_HEIGHT');
        }
        else
        {
            $sub->($_) for grep { $_->isa('CONTAINER') } @{$obj->{ELEMENTS}};
        }

        $obj->exit_scope($context, 1) unless $obj->isa('PAGEDEF');
    };

    $sub->($self);

    $header_height ||= 0;
    $footer_height ||= 0;

    return ($header_height, $footer_height);
}

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    $self->SUPER::enter_scope( $context );

    my ($pheight, $pwidth) = map { $context->get($self, $_) } qw(PAGE_HEIGHT PAGE_WIDTH);
    unless (defined $pheight && defined $pwidth)
    {
        my $psize = $context->get($self, 'PAGESIZE');
        $self->_validate_option('PAGESIZE', \$psize);

        for my $attr (qw(PAGE_HEIGHT PAGE_WIDTH))
        {
            $self->{$attr} = $Verify{PAGESIZE}{$psize}{$attr};
        }
        ($pheight, $pwidth) = @{$self}{qw(PAGE_HEIGHT PAGE_WIDTH)};
    }

    # swap dimensions if landscape
    if ($context->get($self, 'LANDSCAPE'))
    {
        ($pheight, $pwidth) = ($pwidth, $pheight);

        @{$self}{qw(PAGE_HEIGHT PAGE_WIDTH)}
            = @{$self}{qw(_ORIG_WIDTH _ORIG_HEIGHT)}
            = @{$self}{qw(PAGE_WIDTH PAGE_HEIGHT)}
    }

    return 1;
}

sub exit_scope
{
    my $self = shift;
    my ($context) = @_;

    @{$self}{qw(PAGE_HEIGHT PAGE_WIDTH)} = delete @{$self}{qw(_ORIG_HEIGHT _ORIG_WIDTH)}
        if exists $self->{_ORIG_HEIGHT};

    return $self->SUPER::exit_scope($context);
}

sub begin_page
{
    my $self = shift;
    my ($context) = @_;

    $context->{X} = 0;
    $context->{Y} = $context->get($self, 'START_Y');

    $context->reset_pagebreak;

    return $self->SUPER::begin_page($context);
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    my ($header_h, $footer_h) = $self->find_margin_heights($context);

    my ($pheight, $pwidth) = map { $context->get($self, $_) } qw(PAGE_HEIGHT PAGE_WIDTH);

    $self->{START_Y} = $pheight - $header_h;
    $self->{END_Y}   = $footer_h;

    $context->new_page_def;

    my $done = 0;
    while (!$done)
    {
        last if $::x++ > 10;
        $self->begin_page($context);
        $context->{PDF}->begin_page($pwidth, $pheight);

        $done = $self->iterate_over_children($context);

        $context->{PDF}->end_page;
        $self->end_page($context);

        $context->increment_pagenumber unless $context->get($self, 'NOPAGENUMBER');
    }

    return $done;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::PageDef

=head1 PURPOSE

To provide the page definition for a given page. Without a pagedef, nothing
renders

=head1 NODE NAME

PAGEDEF

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * MARGINS / LEFT_MARGIN / RIGHT_MARGIN - This determines any space kept
empty on the left and right margins. MARGINS is a shortcut for specifying both
the left and right margins to the same value.

=item * PAGE_HEIGHT / PAGE_WIDTH - the height and width of the paper you want
this pagedef to render to. If both are not specified, the value in PAGESIZE will
be used.

=item * PAGESIZE - This is the paper size you want this pagedef to render to.
Choices are: Letter, Legal, A0, A1, A2, A3, and A4. This attribute will only be
used if PAGE_HEIGHT and PAGE_WIDTH are not set.

=item * LANDSCAPE - The default orientation is portrait. If LANDSCAPE is set to
a true value, then PAGE_HEIGHT and PAGE_WIDTH will be swapped.

=item * NOPAGENUMBER - If this is set to a true value, then this pagedef will
not increment the __PAGE__ parameter. Useful for title pages and the like.

=back

=head1 CHILDREN

None

=head1 AFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

  <pagedef pagesize="Legal" landscape="1">
    ... Children will render to a Legal-sized paper in landscape orientation ...
  </pagedef>

=head1 NOTE

It is very possible, and often useful, to have more than one pagedef in a given
template. Also, the PAGEDEF does not have to be the direct child of the
PDFTEMPLATE node. It is sometimes useful to have something like:

  <pdftemplate>
    <loop name="PAGEDEFS">
      <pagedef
        pagesize="$PaperSize"
        landscape="$Orientation"
        nopagenumber="$TitlePage"
      >
        ... Children here ...
      </pagedef>
    </loop>
  </pdftemplate>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
