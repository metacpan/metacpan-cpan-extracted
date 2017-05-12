#!/usr/bin/perl
#*
#* Name: PidFile.t
#* Info: Test for: PidFile
#* Author: Lukasz Romanowski (lr5013|roman) <lroman@cpan.org>
#*

use strict;
use warnings;

#=------------------------------------------------------------------------ ( use )

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Test::Most 'defer_plan'; # for tests

use File::Slurp;    # read / write file
use File::Basename; # basename()

#=------------------------------------------------------------------------ ( prepare data )

my $name = basename( $0 );
my $dir  = '/var/tmp';
my $path = "$dir/$name.pid";

my $t_pid  = 15;
my $t_name = 'test.1.t';
my $t_path = "$dir/$t_name.pid";

my $suffix = 'suff';

system "rm $path"   if -f $path;
system "rm $t_path" if -f $t_path;

#=------------------------------------------------------------------------ ( tests )

use_ok 'PidFile';
map { can_ok('PidFile', $_) } qw(
    Write
    Read
    Delete
    Check
    Suffix
    Dir
);

# --- Dir ---
is( PidFile->Dir( $dir ), $dir, 'Dir' ) or die 'Wrong Dir !!!';

# --- Path ---
is( PidFile->Path, $path, 'Path' );
is( PidFile->Path( 'name' => $t_name ), $t_path, 'Path - custom' );

# --- Write ---
ok( PidFile->Write, 'Write' );
ok( PidFile->Write( 'pid' => $t_pid, 'name' => $t_name ), 'Write - custom' );
ok( -f $path,   'default file exists' );
ok( -f $t_path, 'custom  file exists' );
is( read_file( $path ),   "$$",     'check default file content' );
is( read_file( $t_path ), "$t_pid", 'check custom  file content' );
warning_like { ok( PidFile->Write, 'Write 2' ) } { carped => qr{find old pid file: $path at} }, ' and warn';
throws_ok { warning_like { PidFile->Write( 'pid' => $t_pid ) } { carped => qr{find old pid file: $path at} }, 'Write 3 warn' } qr{old process \(pid: $$\) arleady running! at}, ' and die';

# --- Read ---
is( PidFile->Read, $$, 'Read' );
is( PidFile->Read( 'name' => $t_name ), $t_pid, 'Read - custom' );
warning_like { is( PidFile->Read( 'name' => '/not/exists/script' ), undef, 'Read - not exists pid file' ) } { carped => qr{missing pid file: $dir/script.pid at} }, ' and warn';

# --- Check ---
is( PidFile->Check, $$, 'Check' );
is( PidFile->Check( 'pid'  => $$ ), $$, 'Check - by pid' );
is( PidFile->Check( 'name' => $0 ), $$, 'Check - by name' );
is( PidFile->Check( 'pid'  => $t_pid  ), 0, 'Check - custom pid'  );
is( PidFile->Check( 'name' => $t_name ), 0, 'Check - custom name' );
warning_like { is( PidFile->Check( 'name' => '/not/exists/script' ), undef, 'Check - not exists pid file' ) } { carped => qr{missing pid file: $dir/script.pid at} }, ' and warn';

# --- Delete ---
ok( PidFile->Delete, 'Delete' );
ok( PidFile->Delete( 'name' => $t_name ), 'Delete - custom' );
ok( ! -f $path,   'default file not exists' );
ok( ! -f $t_path, 'custom  file not exists' );

# --- Suffix ---
is( PidFile->Suffix( $suffix), $suffix, 'Suffix' );
is( PidFile->Path, "$dir/${name}_${suffix}.pid", 'Suffix - Path' );
is( PidFile->Path( 'name' => $t_name ), "$dir/${t_name}_${suffix}.pid", 'Suffix - Path - custom' );

#=------------------------------------------------------------------------ ( clean )

system "rm $path"   if -f $path;
system "rm $t_path" if -f $t_path;

#=------------------------------------------------------------------------ ( all done )

ok( 1, 'Have a Niice Day ;)' );
all_done;

