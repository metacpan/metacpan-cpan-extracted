#!perl

use Test::More;
use File::Basename qw/dirname/;
use FindBin qw/$Bin/;
use File::Temp;
use IO::File;
use strict;

our $minSqliteVersion = '3.6.19';
our $sqlite = `which sqlite3` || `which sqlite`;
our $sqliteVersion;
if ($sqlite) {
    chomp $sqlite;
    ($sqliteVersion) = grep /^\d/, `$sqlite --version`;
    chomp $sqliteVersion;
    my @pieces = split /\./, $minSqliteVersion;
    unless ($sqliteVersion =~ /3\.6\.(\d+)$/ and $1 >= $pieces[-1]) {
        plan skip_all => "Sqlite version ($sqliteVersion) is less than $minSqliteVersion";
    }
    plan qw/no_plan/;
} else {
    plan skip_all => "Could not find sqlite in PATH ($ENV{PATH})";
}
diag "testing with '$sqlite' version $sqliteVersion";

ok( ( chdir $Bin ), ("chdir $Bin") );

-e "$ENV{HOME}/.sqliterc" and diag "NB: $ENV{HOME}/.sqliterc may interfere with tests";

$ENV{PERL5LIB} = join ':', @INC;

for my $in (<in/*.sql>) {
    my $dbfile = File::Temp->new();
    $ENV{SQLITE_CURRENT_DB} = "$dbfile";
    my $got = `$sqlite $dbfile < $in` or die "command failed : $!";
    my $out = $in;
    $out =~ s/in/out/;
    $out =~ s/sql$/out/;
    die "missing $out" unless -e $out;
    my $cmp = join "", IO::File->new("<$out")->getlines;
    is $got, $cmp, "output for $in matches $out";
}

1;


