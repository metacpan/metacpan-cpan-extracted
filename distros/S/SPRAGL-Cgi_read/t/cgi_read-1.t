#!/usr/bin/perl
# t/cgi-1.pl
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my $dir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $dir = dirname(abs_path($0)) =~ s/[^\/]+$/lib/r;
    push @ARGV , '-q?a=5;b=';
    };

use lib $dir;
use SPRAGL::Cgi_read;

ok (param->{a} == 5);
ok (param->{b} eq '');
ok (scalar (keys param->%*) == 2);

__END__
