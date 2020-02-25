package Promise::XS::Promise;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Promise::XS::Promise - promise object

=head1 SYNOPSIS

See L<Promise::XS>.

=head1 DESCRIPTION

This is L<Promise::XS>’s actual promise object class. It implements
these methods:

=over

=item * C<then()>

=item * C<catch()>

=item * C<finally()>

=back

… which behave as they normally do in promise implementations.

=head1 NOTES

Subclassing this class won’t work because the above-named methods always
return instances of (exactly) this class. That may change eventually,
but for now this is what’s what.

=cut

sub _warn_unhandled {
    my (@reasons) = @_;

    my $class = __PACKAGE__;

    if (1 == @reasons) {
        warn "$class: Unhandled rejection: $reasons[0]\n";
    }
    else {
        my $total = 0 + @reasons;

        for my $i ( 0 .. $#reasons ) {
            my $num = 1 + $i;

            warn "$class: Unhandled rejection ($num of $total): $reasons[$i]\n";
        }
    }
}

1;
