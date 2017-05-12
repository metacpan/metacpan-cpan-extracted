use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More tests => 2;
use Test::SharedFork;
use Panda::NSS;

my $vfytime = 1404206968;

my $tmpdir = tempdir(CLEANUP => 1);
note "NSS DB dir = $tmpdir";

Panda::NSS::init($tmpdir);
Panda::NSS::add_builtins();

my $cert_data = slurp('t/has_aia.cer');

my $pid = fork();
if ($pid == 0) {
    Panda::NSS::reinit();
    Panda::NSS::reinit();
    my $cert = Panda::NSS::Cert->new($cert_data);
    ok !!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Check cert in child';
}
else {
    my $cert = Panda::NSS::Cert->new($cert_data);
    ok !!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Check cert in parent';
    waitpid($pid, 0);
}

sub slurp {
  local $/;
  open my $file, $_[0] or die "Couldn't open file: $!";
  return <$file>;
}
