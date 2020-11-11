#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::FS     qw/posix_glob GLOB_NOMATCH GLOB_MARK/;
use POSIX::1003::Errno  qw/EACCES/;

$^O ne 'MSWin32'
    or plan skip_all => 'tests unix specific';

my ($err, $fns) = posix_glob('/et*');
#warn "  f=$_\n" for @$fns;
ok(!$err, 'ran glob');
cmp_ok(scalar @$fns, '>=', 1, 'found filenames');
like($fns->[0], qr!^/et!, "match $fns->[0]");

my ($err2, $fns2) = posix_glob('/xx');
cmp_ok($err2, '==', GLOB_NOMATCH);
cmp_ok(scalar @$fns2, '==', 0);

my $tmp = '/tmp/s23DSaba';
mkdir $tmp;
chmod 0, $tmp;

my ($err3, $fns3) = posix_glob($tmp);
#diag("1: $err3, @$fns3");

($err3, $fns3) = posix_glob($tmp, flags => GLOB_MARK);
#diag("2: $err3, @$fns3");

### Test "on_error" callback
if($^O eq 'cygwin')
{   # chmod is fake on cygwin
    diag("$^O tests for on_error skipped");
}
else
{   my ($callfn, $callerr);

    # Drop privileges if we are running as superuser.
    local $> = 1 if !$>;

    my ($err4, $fns4) = posix_glob($tmp.'/*'
      , on_error => sub { ($callfn, $callerr) = @_; 0});
    #warn "($err4, @$fns4)\n";
    like($callfn, qr!^\Q$tmp\E/?$!, 'error fn');
    cmp_ok($callerr, '==', EACCES, 'error rc');
    cmp_ok($err4, '==', GLOB_NOMATCH);
}
rmdir $tmp;

done_testing;
