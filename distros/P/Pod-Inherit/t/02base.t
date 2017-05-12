#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use Test::More tests => 7;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;
use lib 't/lib';

#$Pod::Inherit::DEBUG=1;
use_ok('Pod::Inherit');

## Non-existant file, dies in open()
my $pi = Pod::Inherit->new({ input_files => '/this/does/not/exist.pm'});
dies_ok(sub { $pi->write_pod() }, 'Dies when we pass a non-existant file');

my $pi_empty = Pod::Inherit->new({ input_files => [] });
dies_ok(sub { $pi_empty->write_pod() }, 'Dies when we pass an empty filelist');

#my $pi_nopackage = Pod::Inherit->new({ input_files => 't/auxlib/NoPackage.pm' });
#dies_ok(sub { $pi_nopackage->write_pod() }, 'XX when no package in file');

my $pi_override = Pod::Inherit->new({ input_files => [ 't/lib/OverrideSubClass.pm' ] });
$pi_override->write_pod;
ok(!-e 't/lib/OverrideSubClass.pod', "Doesn't produce unneeded pod for completely overridden base class");


SKIP: {
  skip "Moose not installed", 1 unless Test::JMM::has_moose;
  my $pi_moose = Pod::Inherit->new({ input_files => [ 't/auxlib/MooseSub.pm' ] });
  $pi_moose->write_pod;
  my $output = do { local (@ARGV, $/) = "t/auxlib/MooseSub.pod"; <> || 'NO OUTPUT' };
  $output =~ s/=item L<Moose::Object>\n\n(.+)/=item L<Moose::Object>\n\n(some methods here)/;
  eq_or_diff(
        $output,
        do { local (@ARGV, $/) = "t/baseline/auxlib/MooseSub.pod"; <> || 'NO BASELINE' },
        "MooseSub - Moose extends, existing POD - out_dir unset");
#  ok(!-e 't/lib/MooseSub.pod', "Moose extends, existing POD");
  unlink "t/auxlib/MooseSub.pod";
}

SKIP: {
  skip "Class::C3 not installed", 1 unless Test::JMM::has_c3;
  my $pi_c3 = Pod::Inherit->new({ input_files => [ 't/auxlib/ClassC3Sub.pm' ] });
  $pi_c3->write_pod;
  eq_or_diff(
        do { local (@ARGV, $/) = "t/auxlib/ClassC3Sub.pod";          <> || 'NO OUTPUT' },
        do { local (@ARGV, $/) = "t/baseline/auxlib/ClassC3Sub.pod"; <> || 'NO BASELINE' },
        'ClassC3Sub - "use base" Class::C3 class, existing POD - out_dir unset');
#  ok(!-e 't/lib/ClassC3Sub.pod', '"use base" Class::C3 class, existing POD');
  unlink "t/auxlib/ClassC3Sub.pod";
}
