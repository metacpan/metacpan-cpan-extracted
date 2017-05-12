#!/usr/bin/perl

###### PACKAGES ######

use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
use MySQL::Util;
use Data::Dumper;

###### CONSTANTS ######

###### GLOBAL VARIABLES ######

use vars qw($Host $DbName $User $Pass $Table $RowCount $Util $Defaults $Conf);

###### MAIN PROGRAM ######

parse_cmd_line();
init();

my %defaults = split( /,/, $Defaults ) if $Defaults;

$Util->create_data(
    table    => $Table,
    rows     => $RowCount,
    defaults => {%defaults},
    conf => $Conf
);

###### END MAIN #######

sub init {
    my $dsn = "dbi:mysql:host=$Host;dbname=$DbName";

    $Util = MySQL::Util->new(
        dsn  => $dsn,
        user => $User,
        pass => $Pass
    );
}

sub check_required {
    my $opt = shift;
    my $arg = shift;

    print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line {
    my @tmp = @ARGV;
    my $help;

    my $rc = GetOptions(
        "h=s"    => \$Host,
        "d=s"    => \$DbName,
        "u=s"    => \$User,
        "p=s"    => \$Pass,
        "n=s"    => \$Table,
        "c=s"    => \$RowCount,
        "a=s"    => \$Defaults,
        "f=s"    => \$Conf,
        "help|?" => \$help
    );

    print_usage("usage:") if $help;

    check_required( '-u', $User );
    check_required( '-h', $Host );
    check_required( '-d', $DbName );
    check_required( '-n', $Table );
    check_required( '-c', $RowCount );

    if ( !($rc) || ( @ARGV != 0 ) ) {
        ## if rc is false or args are left on line
        print_usage("parse_cmd_line failed");
    }

    @ARGV = @tmp;
}

sub print_usage {
    print STDERR "@_\n";

    print "\n$0\n"
      . "\t-u <user>\n"
      . "\t-h <host>\n"
      . "\t-d <dbname>\n"
      . "\t-n <table name>\n"
      . "\t-c <row count>\n"
      . "\t[-p <pass>]\n"
      . "\t[-a <default column values in csv key/value pair format>]\n"
      . "\t[-f <conf file>]\n"
      . "\t[-?] (usage)\n" . "\n";

    print "\nExamples:\n"
      . "\t$0 -u myself -p secret -h myhost -d mydb -n customers -c 50 \n"
      . "\t\t-a my_id,87,code,xyz\n";

    print "\n";

    exit 1;
}
