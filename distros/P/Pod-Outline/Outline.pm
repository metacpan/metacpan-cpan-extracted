package Pod::Outline;

use strict;
use Pod::Simple::Text ();
use Text::Wrap;
our @ISA = qw( Pod::Simple::Text );

=head1 NAME

Pod::Outline - For generating outlines of POD files

=cut

use warnings;
use strict;

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Subclass of L<Pod::Simple::Text> designed for outlines.

=cut

our $INDENT = 4;

sub handle_text {  $_[0]{'Thispara'} .= $_[1] }

sub start_Para  {  $_[0]{'Thispara'} = '' }
sub start_head1 { _start_head(1,@_) }
sub start_head2 { _start_head(2,@_) }
sub start_head3 { _start_head(3,@_) }
sub start_head4 { _start_head(4,@_) }
sub _start_head {
    my $depth = shift;
    my $self = shift;
    $self->{Depth} = $depth;
    $self->{Thispara} = " " x ($INDENT * ($depth-1));
}

sub start_Verbatim    { $_[0]{'Thispara'} = ''   }
sub start_item_bullet { $_[0]{'Thispara'} = '* ' }
sub start_item_number { $_[0]{'Thispara'} = "$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'Thispara'} = ''   }

# . . . . . Now the actual formatters:

sub end_head1       { $_[0]->emit_par(-1 * $INDENT) }
sub end_head2       { $_[0]->emit_par(-2 * $INDENT) }
sub end_head3       { $_[0]->emit_par(-3 * $INDENT) }
sub end_head4       { $_[0]->emit_par(-4 * $INDENT) }
sub end_Para        { $_[0]->emit_par() }
sub end_item_bullet { $_[0]->emit_par() }
sub end_item_number { $_[0]->emit_par() }
sub end_item_text   { $_[0]->emit_par(int(.5*$INDENT))}

sub emit_par {
    my $self = shift;
    my $tweak_indent = shift;

    my $nspaces = ($INDENT * $self->{'Depth'}) + ($tweak_indent||0);

    my $indent = ' ' x $nspaces; # Yes, 'STRING' x NEGATIVE gives '', same as 'STRING' x 0

    $self->{'Thispara'} =~ tr{\xAD}{}d if Pod::Simple::ASCII;
    my $out = Text::Wrap::wrap($indent, $indent, $self->{'Thispara'} .= "\n");
    $out =~ tr{\xA0}{ } if Pod::Simple::ASCII;
    print {$self->{'output_fh'}} $out, "\n";
    $self->{'Thispara'} = '';

    return;
} # emit_par

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pod-outline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Andy Lester, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Pod::Outline
