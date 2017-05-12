# perl syntax check for all scripts

use strict;
use warnings;
use Test::More;
use Test::Strict;
use File::Find;

my @scripts = map { local $_ = $_; "script/$_" } qw(
    ciscoospf2yaml
    gated2yaml
    ospf2dot
    ospfconvert
    ospfd2yaml
    ospfview
);

plan tests => 4 * @scripts;

foreach my $file (@scripts) {
    syntax_ok($file, "$file syntax") or diag("$file syntax check failed");
    strict_ok($file, "$file strict") or diag("$file use strict missing");
    warnings_ok($file, "$file warnings") or diag("$file use warnings missing");
}

my %files = map { $_ => 1 } @scripts;
sub wanted {
    ! /[A-Z]/ && ! /\.cgi$/ && -f or return;
    ok($files{$File::Find::name}, "$File::Find::name file")
	or diag("Executable file $File::Find::name not in script list");
}
find(\&wanted, "script");
