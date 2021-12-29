use strict;
use warnings;
use Test::More qw[no_plan];
use POE::Component::Server::IRC::Common qw[chkpasswd];
use File::Spec;

my $passgen = sub {
  my @ab = ('A'..'Z', 'a'..'z');
  return join '', map { $ab[int(rand @ab)] } (0..19);
};

my $count = 0;
while ( $count <= 49 ) {
  my $pass = $passgen->();
  my %passes;
  my %args = ( crypt => '', md5 => '--md5', apache => '--apache', bcrypt => '--bcrypt' );
  my $pmkpasswd = File::Spec->catfile('bin','pmkpasswd');
  foreach my $type ( qw[crypt md5 apache bcrypt] ) {
    my $args = $args{$type};
    my $crypt = `$^X -Ilib $pmkpasswd $args --password $pass`;
    chomp $crypt;
    ok(chkpasswd($pass,$crypt), "Chkpasswd $type: $crypt");
  }
  $count++;
}
