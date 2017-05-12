use Test::More;

use strict;
use warnings;

# We are going to test a command line invocation,
# do not bother if this does not look unixy enough.
plan(skip_all => "does not look like unixy enough") unless -x '/bin/ls';

my $fh;

use File::Temp;

my $tempdir = File::Temp->newdir();  # Nuked at exit.

print "# tempdir = $tempdir\n";

ok(open($fh,
        "$^X -Ilib util/ppixref --code='use utf8' --files --subs --subs_files --incs_files --cache_directory=$tempdir |"),
   "start ppixref");

my %files;
my %subs;
my %subs_files;
my %incs_files;

while(<$fh>) {
    print;
    if (m{/((?:utf8|strict)\.pm)$}) {
        $files{$1}++;
    }
    if (m{^((?:utf8|strict)::import)$}) {
        $subs{$1}++;
    }
    if (m{^((?:utf8|strict)::import)\t/.+/([^/]+)\t\d+$}) {
        $subs_files{$1}{$2}++;
    }
    if (m{^/.+/([^/]+\.p[ml])\t\d+\t/.+/([^/]+\.p[ml])\t(?:use|require)\t.+}) {
        $incs_files{$1}{$2}++;
    }
}

ok($files{'utf8.pm'}, "saw utf8.pm");
ok($files{'strict.pm'}, "saw strict.pm");
ok($subs{'utf8::import'}, "saw utf8::import");
ok($subs{'strict::import'}, "saw strict::import");
ok($subs_files{'utf8::import'}{'utf8.pm'}, "utf8::import subs_files");
ok($subs_files{'strict::import'}{'strict.pm'}, "strict::import subs_files");
ok($incs_files{'utf8.pm'}{'utf8_heavy.pl'}, "utf8.pm utf8_heavy.pl");
ok($incs_files{'warnings.pm'}{'Carp.pm'}, "warnings.pm Carp.pm");

done_testing();
