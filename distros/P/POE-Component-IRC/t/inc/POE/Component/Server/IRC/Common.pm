package POE::Component::Server::IRC::Common;
BEGIN {
  $POE::Component::Server::IRC::Common::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::Common::VERSION = '1.52';
}

use strict;
use warnings FATAL => 'all';
use Crypt::PasswdMD5;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(mkpasswd chkpasswd);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

sub mkpasswd {
    my ($plain, %opts) = @_;
    return if !defined $plain || !length $plain;
    $opts{lc $_} = delete $opts{$_} for keys %opts;

    return unix_md5_crypt($plain) if $opts{md5};
    return apache_md5_crypt($plain) if $opts{apache};
    my $salt = join '', ('.','/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    return crypt($plain, $salt);
}

sub chkpasswd {
    my ($pass, $chk) = @_;
    return if !defined $pass || !length $pass;
    return if !defined $chk || !length $chk;

    my $md5 = '$1$'; my $apr = '$apr1$';
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

    return 1 if crypt( $pass, $chk ) eq $chk;
    return 1 if $pass eq $chk;
    return;
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

 my $passwd = mkpasswd( 'moocow' ); # vanilla crypt()
 my $passwd = mkpasswd( 'moocow', md5 => 1 ) # unix_md5_crypt()
 my $passwd = mkpasswd( 'moocow', apache => 1 ) # apache_md5_crypt()

=head2 C<chkpasswd>

Takes two mandatory arguments, a password string and something to check that
password against. The function first tries md5 comparisons (UNIX and Apache),
then C<crypt> and finally plain-text password check.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 SEE ALSO

L<POE::Component::Server::IRC|POE::Component::Server::IRC>

=cut
