package Myriad::Role;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Role - common pragmata for L<Myriad> rôles

=head1 SYNOPSIS

 package Example::Role;
 use Myriad::Role;

 requires startup;

 1;

=cut

require Myriad::Class;

sub import {
    my $called_on = shift;

    # Unused, but we'll support it for now.
    my $version = 1;
    if(@_ and $_[0] =~ /^:v([0-9]+)/) {
        $version = $1;
        shift;
    }
    my %args = (
        version => $version,
        @_
    );

    my $class = __PACKAGE__;
    my $pkg = delete($args{target}) // caller(0);
    $args{type} = 'role';
    $args{target} //= $pkg;
    return Myriad::Class->import(%args);
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

