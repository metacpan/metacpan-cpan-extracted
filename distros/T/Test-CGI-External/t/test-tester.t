use warnings;
use strict;
use Test::Tester;
use Test::More;
use Test::CGI::External;
use FindBin '$Bin';

# Edit the test script to give it the right path.
# http://stackoverflow.com/questions/10390173/getting-absolute-path-to-perl-executable-for-the-current-process#10393492

use Config;
my $perlpath = $Config{perlpath};
my $cgi = "$Bin/test.cgi";
open my $in, "<", $cgi or die "Cannot open $cgi: $!";
my @lines;
while (<$in>) {
s/^#!.*perl.*$/#!$perlpath/;
push @lines, $_;
}
close $in or die "Cannot close $cgi: $!";
open my $out, ">", $cgi or die "Cannot open $cgi: $!";
for (@lines) {
print $out $_;
}
close $out or die "Cannot close $cgi: $!";

# Now start the tests.
if ($^O eq 'MSWin32') {
    plan skip_all => "These tests not adapted for Microsoft Windows";
}

my $tester = Test::CGI::External->new ();

# Test for "not found" error.


my %options;

$options{REQUEST_METHOD} = 'GET';
my ($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable (
	    "$Bin/thisdoesnotactuallyexist.cgi"
	);
    }
);
ok (! $premature, "no premature output");
ok (! $results[0]{ok}, "failed first test because does not exist");

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable (
	    "$Bin/test-tester.t"
	);
    }
);
ok (! $premature, "no premature output");
ok ($results[0]{ok}, "passed first test because exists");
ok (! $results[1]{ok}, "failed second test because not executable");

# Test it works with options.

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--header');
    }
);
ok (! $premature);
ok ($results[0]{ok}, "passed first test because exists, with options");
ok ($results[1]{ok}, "passed second test because executable, with options");

# Test it works with an OK file.

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi");
    }
);
ok (! $premature);
ok ($results[0]{ok}, "passed first test because exists");
ok ($results[1]{ok}, "passed second test because executable");


($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    ok ($_->{ok}, "passed test '$_->{name}'");
}

# Print a bad header

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--header');
    }
);

($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    my $name = $_->{name};
    if ($name =~ /garbage/) {
	ok (! $_->{ok}, "'$_->{name}' - bad http header causes failure");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--exit');
    }
);

($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    if ($_->{name} =~ /exited with zero status/) {
	ok (! $_->{ok}, "'$_->{name}' - non-zero exit value causes failure");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}

note ("Don't send a charset");

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--charset');
	$tester->expect_charset ('EUC-JP');
    }
);

($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    if ($_->{name} =~ /charset/) {
	ok (! $_->{ok}, "'$_->{name}' - empty charset causes failure");
    }
    elsif ($_->{name} =~ /decoded from EUC-JP encoding/) {
	ok (! $_->{ok}, "Cannot decode from bogus EUC-JP encoding");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}

note ("Send a bad charset");

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--badcharset');
	$tester->expect_charset ('UTF-8');
    }
);

($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    if ($_->{name} =~ /Got expected charset/) {
	ok (! $_->{ok}, "'$_->{name}' - bad charset causes failure");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}

note ("test with compression");

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi", '--gzip');
	$tester->do_compression_test (1);
    }
);
($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    ok ($_->{ok}, "passed test '$_->{name}'");
}
($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi",
				     '--gzip', '--gzipheader');
	$tester->do_compression_test (1);
    }
);
note ("biffo");
($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
note ("boffo");
for (@results) {
    if ($_->{name} =~ /header indicating compression/) {
	ok (! $_->{ok}, "complained about lack of gzip header");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}
$tester->do_compression_test (undef);

($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi",
				     '--contenttype');
    }
);
($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");

for (@results) {
    if ($_->{name} =~ /Content-Type/) {
	ok (! $_->{ok}, "complained about Content-Type header");
    }
    else {
	ok ($_->{ok}, "passed test '$_->{name}'");
    }
}
($premature, @results) = run_tests (
    sub {
	$tester->set_cgi_executable ("$Bin/test.cgi",
				     '--contenttype');
    }
);
$tester->set_no_check_content (1);
($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature diagnostics");
for (@results) {
    ok ($_->{ok}, "passed test '$_->{name}'");
}
$tester->set_no_check_content (undef);

done_testing ();
