package Myriad::Role;

use strict;
use warnings;

our $VERSION = '0.010'; # VERSION
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
    Myriad::Class->import(%args);
    if(my $class = $args{class} || $pkg) {
        # For history here, see this:
        # https://rt.cpan.org/Ticket/Display.html?id=132337
        # At the time of writing, ->begin_class is undocumented
        # but can be seen in action in this test:
        # https://metacpan.org/source/PEVANS/Object-Pad-0.21/t/70mop-create-class.t#L30
        Object::Pad->import_into($pkg);
        return Object::Pad::MOP::Class->begin_role(
            $pkg
        );
    }
    return $pkg;
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

