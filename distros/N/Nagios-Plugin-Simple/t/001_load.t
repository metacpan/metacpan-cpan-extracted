# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 12;

BEGIN { use_ok( 'Nagios::Plugin::Simple' ); }

my $object = Nagios::Plugin::Simple->new ();
isa_ok ($object, 'Nagios::Plugin::Simple');

my $stdout=qx{perl -e "print q{OK};exit(1)"};
my $exit=$? >> 8;
is($stdout , "OK", "External Perl interpreter");
is($exit, "1", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->ok(q{TEST})"};
$exit=$? >> 8;
is($stdout , "OK: TEST\n", "External Perl interpreter");
is($exit, "0", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->warning(q{TEST})"};
$exit=$? >> 8;
is($stdout , "Warning: TEST\n", "External Perl interpreter");
is($exit, "1", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->critical(q{TEST})"};
$exit=$? >> 8;
is($stdout , "Critical: TEST\n", "External Perl interpreter");
is($exit, "2", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->unknown(q{TEST})"};
$exit=$? >> 8;
is($stdout , "Unknown: TEST\n", "External Perl interpreter");
is($exit, "3", "Exit Code");
