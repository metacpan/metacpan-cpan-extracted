package PDF::FromHTML::Template::Element::Weblink;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Element);

    use PDF::FromHTML::Template::Element;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    return 1 if $context->{CALC_LAST_PAGE};

    my $url = $context->get($self, 'URL');

    unless (defined $url)
    {
        warn "Weblink: no URL defined!", $/;
        return 1;
    }

    my @dimensions = map {
        $context->get($self, $_) || 0
    } qw( X1 Y1 X2 Y2 );

    $context->{PDF}->add_weblink( @dimensions, $url );

    return 1;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Element::WebLink

=head1 PURPOSE

To provide a clickable web-link

=head1 NODE NAME

WEBLINK

=head1 INHERITANCE

PDF::FromHTML::Template::Element

=head1 ATTRIBUTES

=over 4

=item * URL
The URL to go to, when clicked

=item * X1 / X2 / Y1 / Y2

The dimensions of the clickable area

=back

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

This node is currently under review as to whether it should be removed and a
URL attribute should be added to various nodes, such as IMAGE, TEXTBOX, and ROW.

=head2 USE AT YOUR OWN RISK

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
