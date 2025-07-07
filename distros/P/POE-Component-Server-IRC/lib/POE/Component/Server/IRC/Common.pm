package POE::Component::Server::IRC::Common;
$POE::Component::Server::IRC::Common::VERSION = '1.66';
use strict;
use warnings FATAL => 'all';
use Crypt::PasswdMD5;
use Crypt::Eksblowfish::Bcrypt ();

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(mkpasswd chkpasswd);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

sub mkpasswd {
    my ($plain, %opts) = @_;
    return if !defined $plain || !length $plain;
    $opts{lc $_} = delete $opts{$_} for keys %opts;

    return _bcrypt($plain) if $opts{bcrypt};
    return unix_md5_crypt($plain) if $opts{md5};
    return apache_md5_crypt($plain) if $opts{apache};
    my $salt = join '', ('.','/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    my $alg = '';
    $alg = '$5$' if !defined(crypt("ab", $alg."cd"));
    $alg = '$2b$12$FPWWO2RJ3CK4FINTw0Hi' if !defined(crypt("ab", $alg."cd"));
    $alg = '' if !defined(crypt("ab", $alg."cd"));
    return crypt($plain, $alg.$salt);
}

sub chkpasswd {
    my ($pass, $chk) = @_;
    return if !defined $pass || !length $pass;
    return if !defined $chk || !length $chk;

    my $md5 = '$1$'; my $apr = '$apr1$'; my $bcr = '$2a$';
    if (index($chk,$apr) == 0) {
        my $salt = $chk;
        $salt =~ s/^\Q$apr//;
        $salt =~ s/^(.*)\$/$1/;
        $salt = substr( $salt, 0, 8 );
        return 1 if apache_md5_crypt($pass, $salt) eq $chk;
    }
    elsif ( index($chk,$md5) == 0 ) {
        my $salt = $chk;
        $salt =~ s/^\Q$md5//;
        $salt =~ s/^(.*)\$/$1/;
        $salt = substr( $salt, 0, 8 );
        return 1 if unix_md5_crypt($pass, $salt) eq $chk;
    }
    elsif ( index($chk,$bcr) == 0 ) {
        return 1 if _bcrypt( $pass, $chk ) eq $chk;
    }

    my $crypt = crypt( $pass, $chk );
    return 1 if $crypt && $crypt eq $chk;
    return 1 if $pass eq $chk;
    return;
}

sub _bcrypt {
  my $plain = shift;
  my $salt  = shift;
  if ( !defined $salt ) {
    my $cost = sprintf('%02d', 6);
    my $alg = '';
    $alg = '$5$' if !defined(crypt("ab", $alg."cd"));
    $alg = '$2b$12$FPWWO2RJ3CK4FINTw0Hi' if !defined(crypt("ab", $alg."cd"));
    $alg = '' if !defined(crypt("ab", $alg."cd"));
    my $salty = sub {
      my $num = 999999;
      my $cr = crypt( rand($num), $alg.rand($num) ) . crypt( rand($num), $alg.rand($num) );
      Crypt::Eksblowfish::Bcrypt::en_base64(substr( $cr, 4, 16 ));
    };
    $salt = join( '$', '$2a', $cost, $salty->() );
  }
  return Crypt::Eksblowfish::Bcrypt::bcrypt($plain,$salt);
}

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Common - provides a set of common functions for the POE::Component::Server::IRC suite.

=head1 SYNOPSIS

 use strict;
 use warnings;

 use POE::Component::Server::IRC::Common qw( :ALL );

 my $passwd = mkpasswd( 'moocow' );


=head1 DESCRIPTION

POE::Component::IRC::Common provides a set of common functions for the
L<POE::Component::Server::IRC|POE::Component::Server::IRC> suite.

=head1 FUNCTIONS

=head2 C<mkpasswd>

Takes one mandatory argument a plain string to 'encrypt'. If no further
options are specified it uses C<crypt> to generate the password. Specifying
'md5' option uses L<Crypt::PasswdMD5|Crypt::PasswdMD5>'s C<unix_md5_crypt>
function to generate the password. Specifying 'apache' uses
Crypt::PasswdMD5 C<apache_md5_crypt> function to generate the password.
Specifying 'bcrypt' option uses L<Crypt::Eksblowfish::Bcrypt> to generate
the password (recommended).

 my $passwd = mkpasswd( 'moocow' ); # vanilla crypt()
 my $passwd = mkpasswd( 'moocow', md5 => 1 ) # unix_md5_crypt()
 my $passwd = mkpasswd( 'moocow', apache => 1 ) # apache_md5_crypt()
 my $passwd = mkpasswd( 'moocow', bcrypt => 1 ) # bcrypt() # recommended

=head2 C<chkpasswd>

Takes two mandatory arguments, a password string and something to check that
password against. The function first tries md5 comparisons (UNIX and Apache)
and bcrypt, then C<crypt> and finally plain-text password check.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 SEE ALSO

L<POE::Component::Server::IRC>
L<Crypt::PasswdMD5>
L<Crypt::Eksblowfish::Bcrypt>
L<Mojolicious::Plugin::Bcrypt>

=cut
