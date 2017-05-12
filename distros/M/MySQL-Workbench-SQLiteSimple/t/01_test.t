#!perl -T

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;
use File::Spec;
use IO::File;
use MySQL::Workbench::SQLiteSimple;


my $dir  = dirname __FILE__;
my $file = File::Spec->catfile( $dir, 'test.mwb' );

my $foo = MySQL::Workbench::SQLiteSimple->new(
  file        => $file,
  output_path => $dir,
);

isa_ok( $foo, 'MySQL::Workbench::SQLiteSimple', 'object is of correct type' );
is( $foo->file, $file, 'input_file' );
is( $foo->output_path, $dir, 'output_path' );

my $sql_path = File::Spec->catfile( $dir, 'sqlite.sql' );
ok !-e $sql_path;

$foo->create_sql;

ok -e $sql_path;

my $content = do { my $io = IO::File->new( $sql_path, 'r' ); join '', $io->getlines };
my $check   = _get_check();

is_string $content, $check;

done_testing();

sub _get_check {
    return q~CREATE TABLE `Gefa_User` (
    UserID INTEGER NOT NULL,
    Username TEXT,
    PRIMARY KEY (UserID)
);


CREATE TABLE `Role` (
    RoleID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Rolename TEXT
);


CREATE TABLE `UserRole` (
    UserID INTEGER NOT NULL,
    RoleID INTEGER NOT NULL,
    PRIMARY KEY (UserID, RoleID)
);
~;
}
