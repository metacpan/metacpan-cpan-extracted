# parse() Handlers argument test
# $Id: handlers.t,v 1.3 2000/07/19 23:13:24 mfowler Exp $

# This script verifies the Handlers argument to parse() works as advertised.
# Verifies it accepts a code or hash reference, properly calls the given code
# reference, and properly sets the referred hash.


use Parse::PerlConfig;

use lib qw(t);
use parse::testconfig qw(ok);

use strict;
use vars qw($tconf $test_handler %test_handler);


$tconf = parse::testconfig->new('test.conf');

$tconf->tests(4 + $tconf->verify_parsed() * 4);
$tconf->ok_object();


# test a hash handler
Parse::PerlConfig::parse(
    File            =>      $tconf->file_path(),
    Handler         =>      \%test_handler,
);

$tconf->verify_parsed(\%test_handler);



# test a code handler
Parse::PerlConfig::parse(
    File            =>      $tconf->file_path(),
    Handler         =>      \&test_handler,
);

ok(defined $test_handler);
ok($test_handler);



undef %test_handler;
undef $test_handler;



# test a code and a hash handler
Parse::PerlConfig::parse(
    File            =>      $tconf->file_path(),
    Handlers        =>      [\%test_handler, \&test_handler],
);

$tconf->verify_parsed(\%test_handler);
ok(defined $test_handler);
ok($test_handler);




sub test_handler {
    $test_handler = 1;
    $tconf->verify_parsed(shift);
}
