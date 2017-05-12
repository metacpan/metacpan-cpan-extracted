# -*- perl -*-

use Test::More tests => 10;

BEGIN { use_ok( 'Nagios::Plugin::Simple' ); }

my $object = Nagios::Plugin::Simple->new ();
isa_ok ($object, 'Nagios::Plugin::Simple');

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->status(OK=>q{TEST})"};
$exit=$? >> 8;
is($stdout , "OK: TEST\n", "External Perl interpreter");
is($exit, "0", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->status(Warning=>q{TEST})"};
$exit=$? >> 8;
is($stdout , "Warning: TEST\n", "External Perl interpreter");
is($exit, "1", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->code(2=>q{TEST})"};
$exit=$? >> 8;
is($stdout , "Critical: TEST\n", "External Perl interpreter");
is($exit, "2", "Exit Code");

$stdout=qx{perl -e "use blib;use Nagios::Plugin::Simple;Nagios::Plugin::Simple->new->code(3=>q{TEST})"};
$exit=$? >> 8;
is($stdout , "Unknown: TEST\n", "External Perl interpreter");
is($exit, "3", "Exit Code");
