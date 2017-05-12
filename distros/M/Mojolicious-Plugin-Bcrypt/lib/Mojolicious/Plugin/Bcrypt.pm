package Mojolicious::Plugin::Bcrypt;

use warnings;
use strict;

our $VERSION = '0.14';

use Mojo::Base 'Mojolicious::Plugin';
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);

sub register {
    my $self   = shift;
    my $app    = shift;
    my $config = shift || {};

    $app->helper(
        bcrypt => sub {
            my $c = shift;
            my ( $password, $settings ) = @_;
            unless ( defined $settings && $settings =~ /^\$2a\$/ ) {
                my $cost = sprintf('%02d', $config->{cost} || 6);
                $settings = join( '$', '$2a', $cost, _salt() );
            }
            return bcrypt( $password, $settings );
        }
    );

    $app->helper(
        bcrypt_validate => sub {
            my $c = shift;
            my ( $plain, $crypted ) = @_;
            return $c->bcrypt( $plain, $crypted ) eq $crypted;
        }
    );
}

sub _salt {
    my $num = 999999;
    my $cr = crypt( rand($num), rand($num) ) . crypt( rand($num), rand($num) );
    en_base64(substr( $cr, 4, 16 ));
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Bcrypt - bcrypt your passwords!

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Provides a helper for crypting and validating passwords via bcrypt.

    use Mojolicious::Plugin::Bcrypt;

    sub startup {
        my $self = shift;
        $self->plugin('bcrypt', { cost => 4 });
    }

    ...

Optional parameter C<cost> is a non-negative integer controlling the
cost of the hash function. The number of operations is proportional to 2^cost.
The current default value is 6.

=head1 HELPERS

=head2 bcrypt

Crypts a password via the bcrypt algorithm.

    $self->bcrypt( $password, $settings );

C<$settings> is an optional string which encodes the algorithm parameters, as
described in L<Crypt::Eksblowfish::Bcrypt>.

    sub signup {
        my $self = shift;
        my $crypted_pass = $self->bcrypt( $self->param('password') );
        ...
    }

=head2 bcrypt_validate

Validates a password against a crypted copy (for example from your database).

    sub login {
        my $self = shift;
        my $entered_pass = $self->param('password');
        my $crypted_pass = $self->get_password_from_db();
        if ( $self->bcrypt_validate( $entered_pass, $crypted_pass ) ) {

            # Authenticated
            ...;
        }
        else {

            # Wrong password
            ...;
        }
    }

=head1 DEVELOPMENT AND REPOSITORY

Clone it on GitHub at https://github.com/naturalist/Mojolicious--Plugin--Bcrypt

=head1 SEE ALSO

L<Crypt::Eksblowfish::Bcrypt>, L<Mojolicious>, L<Mojolicious::Plugin>

=head1 AUTHOR

Stefan G., C<< <minimal at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

