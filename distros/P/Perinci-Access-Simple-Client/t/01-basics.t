#!perl

use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Temp qw(tempdir);
use Perinci::Access::Simple::Client;
use Test::More 0.98;

# on Windows, abs_path() requires that path actually exists
my $tempdir = tempdir(CLEANUP => 1);
$CWD = $tempdir;
{
    my $fh;
    open $fh, ">", "path1";
    open $fh, ">", "path 2";
}

my $pa = Perinci::Access::Simple::Client->new;

test_parse(
    name   => 'unknown scheme = 400',
    args   => [call => "riap+foo://localhost:1234/"],
    status => 400,
);
test_parse(
    name   => 'invalid riap+tcp 1',
    args   => [call => "riap+tcp:xxx"],
    status => 400,
);
test_parse(
    name   => 'riap+tcp requires port',
    args   => [call => "riap+tcp://localhost/"],
    status => 400,
);
test_parse(
    name   => 'riap+tcp ok 1',
    args   => [call => "riap+tcp://localhost:1234/Foo/Bar"],
    result => {args=>undef, host=>'localhost', path=>undef, port=>1234, scheme=>'riap+tcp', uri=>'/Foo/Bar'},
);
test_parse(
    name   => 'riap+tcp ok 2 (uri via extra)',
    args   => [call => "riap+tcp://localhost:1234", {uri=>'/Foo/Bar'}],
    result => {args=>undef, host=>'localhost', path=>undef, port=>1234, scheme=>'riap+tcp', uri=>'/Foo/Bar'},
);

test_parse(
    name   => 'invalid riap+unix 1',
    args   => [call => "riap+unix:"],
    status => 400,
);
test_parse(
    name   => 'riap+unix ok 1',
    args   => [call => "riap+unix:$tempdir/path1//Foo/Bar"],
    result => {args=>undef, host=>undef, path=>"$tempdir/path1", port=>undef, scheme=>'riap+unix', uri=>'/Foo/Bar'},
);
test_parse(
    name   => 'riap+unix ok 2 (uri via extra, path is unescaped)',
    args   => [call => "riap+unix:$tempdir/path%202", {uri=>'/Foo/Bar'}],
    result => {args=>undef, host=>undef, path=>"$tempdir/path 2", port=>undef, scheme=>'riap+unix', uri=>'/Foo/Bar'},
);

test_parse(
    name   => 'invalid riap+pipe 1',
    args   => [call => "riap+pipe:"],
    status => 400,
);
test_parse(
    name   => 'riap+pipe ok 1',
    args   => [call => "riap+pipe:$tempdir/path%202//arg1/arg%202//Foo/Bar"],
    result => {args=>['arg1', 'arg 2'], host=>undef, path=>"$tempdir/path 2", port=>undef, scheme=>'riap+pipe', uri=>'/Foo/Bar'},
);
test_parse(
    name   => 'riap+pipe ok 2 (uri via extra)',
    args   => [call => "riap+pipe:$tempdir/path%202//arg1/arg%202", {uri=>'/Foo/Bar'}],
    result => {args=>['arg1', 'arg 2'], host=>undef, path=>"$tempdir/path 2", port=>undef, scheme=>'riap+pipe', uri=>'/Foo/Bar'},
);
test_parse(
    name   => 'riap+pipe ok 2 (uri via extra, no args)',
    args   => [call => "riap+pipe:$tempdir/path%202", {uri=>'/Foo/Bar'}],
    result => {args=>[], host=>undef, path=>"$tempdir/path 2", port=>undef, scheme=>'riap+pipe', uri=>'/Foo/Bar'},
);

subtest "parse_url()" => sub {
    plan skip_all => "/var/run does not exist" unless -d "/var/run";

    my $pa = Perinci::Access::Simple::Client->new;
    is_deeply($pa->parse_url("riap+unix:/var/run/apid.sock//Foo/bar"),
              {proto=>"riap+unix", path=>"/Foo/bar", unix_sock_path=>"/var/run/apid.sock"},
              "riap+unix");
    is_deeply($pa->parse_url("riap+tcp://localhost:5000/Foo/bar"),
              {proto=>"riap+tcp" , path=>"/Foo/bar", host=>"localhost", port=>5000},
              "riap+tcp");
    is_deeply($pa->parse_url("riap+pipe:/path/to/prog//a1/a2//Foo/bar"),
              {proto=>"riap+pipe", path=>"/Foo/bar", prog_path=>"/path/to/prog", args=>["a1", "a2"]},
              "riap+pipe");
};

DONE_TESTING:
done_testing();

sub test_parse {
    my %args = @_;

    my $name = $args{name} // "parse $args{args}[1]";
    subtest $name => sub {
        my $res = $pa->_parse(@{ $args{args} });

        my $status = $args{status} // 200;
        is($res->[0], $status, "status") or diag explain $res;

        if ($args{result}) {
            is_deeply($res->[2], $args{result}, "result") or
                diag explain $res->[2];
        }
    };
}
