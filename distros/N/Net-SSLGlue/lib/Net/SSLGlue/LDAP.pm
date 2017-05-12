use strict;
use warnings;
package Net::SSLGlue::LDAP;
our $VERSION = '1.01';
use Net::LDAP;
use IO::Socket::SSL 1.19;

# can be reset with local
our %SSLopts;

# add SSL_verifycn_scheme to the SSL CTX args returned by
# Net::LDAP::_SSL_context_init_args

my $old = defined &Net::LDAP::_SSL_context_init_args
    && \&Net::LDAP::_SSL_context_init_args
    || die "cannot find Net::LDAP::_SSL_context_init_args";
no warnings 'redefine';
*Net::LDAP::_SSL_context_init_args = sub {
    my %arg = $old->(@_);
    $arg{SSL_verifycn_scheme} ||= 'ldap' if $arg{SSL_verify_mode};
    while ( my ($k,$v) = each %SSLopts ) {
	$arg{$k} = $v;
    }
    return %arg;
};

1;

=head1 NAME

Net::SSLGlue::LDAP - proper certificate checking for ldaps in Net::LDAP

=head1 SYNOPSIS

    use Net::SSLGlue::LDAP;
    local %Net::SSLGlue::LDAP = ( SSL_verifycn_name => $hostname_in_cert );
    my $ldap = Net::LDAP->new( $hostname, capath => ... );
    $ldap->start_tls;


=head1 DESCRIPTION

L<Net::SSLGlue::LDAP> modifies L<Net::LDAP> so that it does proper certificate
checking using the C<ldap> SSL_verify_scheme from L<IO::Socket::SSL>.

Because L<Net::LDAP> does not have a mechanism to forward arbitrary parameters for
the construction of the underlying socket these parameters can be set globally
when including the package, or with local settings of the
C<%Net::SSLGlue::LDAP::SSLopts> variable.

All of the C<SSL_*> parameters from L<IO::Socket::SSL> can be used; the
following parameter is especially useful:

=over 4

=item SSL_verifycn_name

Usually the name given as the hostname in the constructor is used to verify the
identity of the certificate. If you want to check the certificate against
another name you can specify it with this parameter.

=back

C<SSL_ca_path>, C<SSL_ca_file> for L<IO::Socket::SSL> can be set with the
C<capath> and C<cafile> parameters of L<Net::LDAP::new> and C<SSL_verify_mode>
can be set with C<verify>, but the meaning of the values differs (C<none> is 0,
e.g. disable certificate verification).

=head1 SEE ALSO

IO::Socket::SSL, LWP, Net::LDAP

=head1 COPYRIGHT

This module is copyright (c) 2008, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

