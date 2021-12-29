use strict;
use warnings;
use Crypt::PasswdMD5;
use Crypt::Eksblowfish::Bcrypt qw[bcrypt];
use Test::More qw[no_plan];
use POE::Component::Server::IRC::Common qw(:ALL);

my $bc = '$2a$06$qqA1/Y1dmjBZP4JslFnV7eSIDN4I8skwNuu0OHCy.JAzAkaQX6ise';
my $plain = 'foocow99';

my $crypt = mkpasswd($plain);
is(crypt($plain, $crypt), $crypt, "Crypt mkpasswd: $crypt");

my $MD5Magic = '$1$';
my $md5 = mkpasswd($plain, 'md5', 1);

my $salt = $md5;
$salt =~ s/^\Q$MD5Magic//;
$salt =~ s/^(.*)\$/$1/;
$salt = substr( $salt, 0, 8 );
is(unix_md5_crypt($plain, $salt), $md5, "MD5 mkpasswd: $md5");

my $apr = mkpasswd($plain, 'apache', 1);
$salt = $apr;
$MD5Magic = '$apr1$';
$salt =~ s/^\Q$MD5Magic//;
$salt =~ s/^(.*)\$/$1/;
$salt = substr( $salt, 0, 8 );
is(apache_md5_crypt($plain, $salt), $apr, "Apache MD5 mkpasswd: $apr");

my $bcrypt = mkpasswd($plain, 'bcrypt', 1);
is(bcrypt($plain,$bcrypt), $bcrypt, "Bcrypt mkpasswd: $bcrypt");

ok(chkpasswd($plain, $plain), 'Plain-text chkpasswd');
ok(chkpasswd($plain, $crypt), 'Crypt chkpasswd');
ok(chkpasswd($plain, $md5), 'MD5 chkpasswd');
ok(chkpasswd($plain, $apr), 'Apache MD5 chkpasswd');
ok(chkpasswd($plain, $bcrypt), 'Bcrypt chkpasswd');

ok(chkpasswd($plain, $bc), 'Bcrypt chkpasswd');

my $passgen = sub {
  my @ab = ('A'..'Z', 'a'..'z');
  return join '', map { $ab[int(rand @ab)] } (0..19);
};

# Bcrypt extended
foreach my $pass ( qw[fubar barfu foo moo meep squigglebox] ) {
   my $bcrypt = mkpasswd( $pass, 'bcrypt', 1 );
   my $badpass = $passgen->();
   ok(chkpasswd($pass,$bcrypt), "Pass: $pass");
   ok(!chkpasswd($badpass,$bcrypt), "Pass not: $badpass" );
}

my $count = 0;
while ( $count <= 49 ) {
  my $pass = $passgen->();
  my %passes;
  $passes{plain}  = $pass;
  $passes{crypt}  = mkpasswd($pass);
  $passes{md5}    = mkpasswd($pass, md5 => 1);
  $passes{apache} = mkpasswd($pass, apache => 1);
  $passes{bcrypt} = mkpasswd($pass, bcrypt => 1);
  foreach my $type ( qw[plain crypt md5 apache bcrypt] ) {
    ok(chkpasswd($pass,$passes{$type}), "Chkpasswd $type: $passes{$type}");
  }
  $count++;
}
