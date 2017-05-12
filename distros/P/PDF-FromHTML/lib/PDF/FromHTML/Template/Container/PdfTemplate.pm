package PDF::FromHTML::Template::Container::PdfTemplate;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # The default color is black
    $self->{COLOR} = '0,0,0' unless exists $self->{COLOR};

    return $self;
}

sub should_render {
#    my $self = shift;
#    my ($context) = @_;

    return 1;
}

sub render {
    my $self = shift;
    my ($context) = @_;

    $self->enter_scope($context);

    my $child_success = $self->SUPER::render($context)
        if $self->should_render($context);

    $self->exit_scope($context);

    return $child_success;
}

#sub preprocess {
#    my $self = shift;
#    my ($context) = @_;
#
#    $self->enter_scope($context);
#
#    $context->{PARAM_MAP}[0]{__LAST_PAGE__} = 0;
#    unless ($context->get($self, 'NOLASTPAGE')) {
#        my $old_PDF = $context->{PDF};
#
#        my $p = PDF::Writer->new;
#        $p->open() or die "Could not open buffer.", $/;
#
#        $context->{PDF} = $p;
#
#        $context->{CALC_LAST_PAGE} = 1;
#        $self->SUPER::render($context);
#        $context->{CALC_LAST_PAGE} = 0;
#
#        $p->close;
#        $self->reset;
#        $context->delete_fonts;
#
#        $context->{PDF} = $old_PDF;
#        $context->{PARAM_MAP}[0]{__LAST_PAGE__} = $context->{PARAM_MAP}[0]{__PAGE__} - 1;
#        $context->{PARAM_MAP}[0]{__PAGE__} = 1;
#        $context->{PARAM_MAP}[0]{__PAGEDEF__} = 0;
#    }
#
#    $self->exit_scope($context, 1);
#
#    return 1;
#}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::PdfTemplate

=head1 PURPOSE

The root node

=head1 NODE NAME

PDFTEMPLATE

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * NOLASTPAGE - If this is set to true, then __LAST_PAGE__ will not be
calculated. This can provide a decent speed improvement.

=back

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <pdftemplate>
    ... Children here ...
  </pdftemplate>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
