#!/usr/bin/perl
# t/cgi-2.pl
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my $dir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $dir = dirname(abs_path($0)) =~ s/[^\/]+$/lib/r;
    push @ARGV , '-q?x=Holmes&y=Watson';
    };

use lib $dir;
use SPRAGL::Cgi_read qw(param $method $uri);

ok (param->{x} eq 'Holmes');
ok (param->{y} eq 'Watson');
ok (scalar (keys param->%*) == 2);

ok ($method eq 'GET');

ok ($uri =~ m/\?x\=Holmes\&y\=Watson$/);

__END__
