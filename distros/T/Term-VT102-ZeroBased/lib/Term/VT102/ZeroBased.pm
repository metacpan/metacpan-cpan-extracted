package Term::VT102::ZeroBased;
use strict;
use warnings;
use base 'Term::VT102';

our $VERSION = '1.02';

sub x { shift->SUPER::x(@_) - 1 }
sub y { shift->SUPER::y(@_) - 1 }

sub status {
    my ($x, $y, @others) = shift->SUPER::status(@_);
    return ($x - 1, $y - 1, @others);
}

sub row_attr {
    my $self = shift;
    my $row   = @_ ? 1 + shift : undef;
    my $start = @_ ? 1 + shift : undef;
    my $end   = @_ ? 1 + shift : undef;

    $self->SUPER::row_attr($row, $start, $end, @_);
}

sub row_text {
    my $self = shift;
    my $row   = @_ ? 1 + shift : undef;
    my $start = @_ ? 1 + shift : undef;
    my $end   = @_ ? 1 + shift : undef;

    $self->SUPER::row_text($row, $start, $end, @_);
}

sub row_plaintext {
    my $self = shift;
    my $row   = @_ ? 1 + shift : undef;
    my $start = @_ ? 1 + shift : undef;
    my $end   = @_ ? 1 + shift : undef;

    $self->SUPER::row_plaintext($row, $start, $end, @_);
}

1;

__END__

=head1 NAME

Term::VT102::ZeroBased - Term::VT102 but with zero-based indices

=head1 SYNOPSIS

    use Term::VT102::ZeroBased;

    my $vt = Term::VT102::ZeroBased->new(cols => 80, rows => 24);
    $vt->process("\e[H");                    # move to top left
    printf "(%d, %d)!\n", $vt->x, $vt->y;    # (0, 0)!

=head1 DESCRIPTION

L<Term::VT102>, a module for terminal emulation, uses 1-based indices for
screen positions. I find this annoying. So this is a simple wrapper around
L<Term::VT102> that converts 1-based indices to 0-based indices.

Why, in particular, would you want this? Escape sequences use one-based
indices, so it makes perfect sense for L<Term::VT102> to use one-based
indices. But L<Curses> uses zero-based indices. And so do most other modules.

See L<Term::VT102> for the documentation on using these modules.

=head1 SEE ALSO

L<Term::VT102>

=head1 AUTHOR

Wrapper by Shawn M Moore, C<sartak@gmail.com>

L<Term::VT102> by Andrew Wood C<andrew.wood@ivarch.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

