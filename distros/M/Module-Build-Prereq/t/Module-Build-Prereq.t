#-*- mode: cperl -*-#
use strict;
use warnings;
use File::Path 'remove_tree';

use Test::More tests => 5;
BEGIN { use_ok('Module::Build::Prereq') };

chdir 't' if -d 't';

mkdir 'testlib';
mkdir 'testlib/Foo';

open my $fh, ">", "testlib/Foo.pm";
print $fh <<_FILE_;
use Glarch;
use Bananas qw(platano_alternative);
use Newspaper ();  ## the good kind
use Buckets ();

1;
_FILE_
close $fh;

open $fh, ">", "testlib/Foo/Bar.pm";
print $fh <<_FILE_;
use Horsey;
use strict;
use warnings;
use lib 'huhh';

1;
_FILE_
close $fh;

open $fh, ">", "testlib/Foo/setup.pl";
print $fh <<_FILE_;
use Jackets;
use strict;
use warnings;

1;
_FILE_
close $fh;

eval {
    assert_modules(prereq_pm => { Glarch => '1.0' },
                   module_paths => ['testlib'],
                   pm_extension => qr(\.p[ml]$));
};

like( $@, qr(^\s*Bananas.*
^\s*Buckets.*
^\s*Horsey.*
^\s*Jackets.*
^\s*Newspaper.*)sm, "missing modules" );

eval {
    assert_modules(prereq_pm => { Glarch => '1.0',
                                  Jackets => '0',
                                  Newspaper => '0',
                                  Horsey => '0' },
                   module_paths => ['testlib'],
                   pm_extension => qr(\.p[ml]$));
};

like( $@, qr(^\s*Bananas.*
^\s*Buckets.*)sm, "missing module" );

unlike( $@, qr(^\s*Horsey.*
^\s*Jackets.*
^\s*Newspaper.*)sm, "not missing modules" );

ok(assert_modules(prereq_pm => { Glarch => '1.0',
                                 Bananas => '0',
                                 Buckets => '0',
                                 Jackets => '0',
                                 Newspaper => '0',
                                 Horsey => '0' },
                  module_paths => ['testlib'],
                  pm_extension => qr(\.p[ml]$)),
   "all modules found");

END {
    remove_tree('testlib');
}
