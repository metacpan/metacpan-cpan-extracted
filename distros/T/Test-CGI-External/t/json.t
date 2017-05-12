use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::Tester;
use Test::More;
use Test::CGI::External;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
eval 'use JSON::Parse ":all";';
if ($@) {
    plan skip_all => "Tests require JSON::Parse",
}
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ("$Bin/json.cgi");
$tester->expect_mime_type ('application/json');
my %options;
$options{REQUEST_METHOD} = 'GET';
$options{json} = 1;
my ($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature output");
for (@results) {
    ok ($_->{ok}, "");
}
$tester->set_cgi_executable ("$Bin/not-json.cgi");
$tester->expect_mime_type ('application/json');
($premature, @results) = run_tests (
    sub {
	$tester->run (\%options);
    }
);
ok (! $premature, "no premature output");
for my $r (@results) {
    my $name = $r->{name};
    if ($name =~ /Valid JSON|Got expected mime type/) {
	ok (! $r->{ok}, "$name not ok");
    }
    else {
	ok ($r->{ok}, "$name ok");
    }
}
done_testing ();
