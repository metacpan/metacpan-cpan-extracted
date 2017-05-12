#!/usr/bin/perl
use strict;
use Test::More;
use Test::Exception;
use Test::Warn;
BEGIN { plan tests => 14 }
use Net::P0f;

my $p0f = undef;

# new() diags
throws_ok {
    $p0f = new Net::P0f backend => 'machin'
} "/^fatal: Unknown value for option 'backend': machin/", 
  "passing unknown backend to new()";

is( $p0f, undef, " - object not created" );

warning_is {
    $p0f = new Net::P0f machin => 'bidule'
} "warning: Unknown option 'machin'", 
  "passing unknown option to new()";
isa_ok( $p0f, 'Net::P0f::Backend::CmdFE' );

# AUTOLOAD() diags
warning_is {
    $p0f->machin
} "warning: Unknown option 'machin'", 
  "calling an unknown option";

# loop() diags
throws_ok {
    $p0f->loop()
} "/^fatal: Option 'callback' was not set./", 
  "calling loop() without callback";

throws_ok {
    $p0f->loop(callback => \&fake)
} "/^fatal: Option 'count' was not set./", 
  "calling loop() without count";

throws_ok {
    $p0f->loop(callback => \&fake, count => 1)
} "/^fatal: No input source was defined. Please set one of 'interface' or 'dump_file'./", 
  "calling loop() with no source";

#warning_is {
#    $p0f->interface('fake');
#    $p0f->dump_file('fake');
#    $p0f->loop(callback => \&fake, count => 1)
#} "warning: Both 'interface' and 'dump_file' have been set. 'dump_file' prevails.", 
#  "options interface and dump_file were both set";

# checking the diagnostics of CmdFE backend ###################################
$p0f = undef;
warning_is {
    $p0f = new Net::P0f backend => 'cmd', machin => 'bidule'
} "warning: Unknown option 'machin'", 
  "passing unknown option to new() -- CmdFE backend";
isa_ok( $p0f, 'Net::P0f::Backend::CmdFE' );

#throws_ok {
#    $p0f->run
#} "fatal: Please set the path to p0f with the 'program_path' option", 
#  "trying to execute run() without program_path set";

# run() (backend cmdfe)
#   croak "fatal: Please set the path to p0f with the 'program_path' option"
#   croak "fatal: Can't exec '", $self->{options}{program_path}, "': $!"
#   carp "error: The callback died with the following error: $@"

# checking the diagnostics of XS backend ######################################
$p0f = undef;
warning_is {
    $p0f = new Net::P0f backend => 'xs', machin => 'bidule'
} "warning: Unknown option 'machin'", 
  "passing unknown option to new() -- XS backend";
isa_ok( $p0f, 'Net::P0f::Backend::XS' );

# checking the diagnostics of Socket backend ##################################
$p0f = undef;
warning_is {
    $p0f = new Net::P0f backend => 'socket', machin => 'bidule'
} "warning: Unknown option 'machin'", 
  "passing unknown option to new() -- Socket backend";
isa_ok( $p0f, 'Net::P0f::Backend::Socket' );

sub fake {}

