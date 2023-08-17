#!/usr/bin/perl
# t/cgi-3.pl
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my $dir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $dir = dirname(abs_path($0)) =~ s/[^\/]+$/lib/r;
    push @ARGV , '-q?n=12;n=4&n=89;n=5;m=0';
    push @ARGV , '-H' , 'X_TEST: testheader';
    };

use lib $dir;
use SPRAGL::Cgi_read;

ok (param->{n} == 12);
ok (param->{m} == 0);
ok (not exists param->{o});
ok (scalar (keys param->%*) == 2);

ok (param_all('n')->[0] == 12);
ok (param_all('n')->[1] == 4);
ok (param_all('n')->[2] == 89);
ok (param_all('n')->[3] == 5);
ok (param_all('m')->[0] == 0);
ok (scalar param_all('n')->@* == 4);
ok (scalar param_all('m')->@* == 1);
ok (scalar param_all('o')->@* == 0);

ok (header('X-test') eq 'testheader');
ok (header('x_TeSt') eq 'testheader');

__END__
