#!/usr/bin/perl

###### PACKAGES ######

use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
use MySQL::Util;

###### CONSTANTS ######


###### GLOBAL VARIABLES ######

use vars qw($Util $Host $DbName $User $Pass);

###### MAIN PROGRAM ######

parse_cmd_line();
init();

foreach my $t (sort @{ $Util->get_tables }){
    print "$t\n";    
}

###### END MAIN #######

sub init {
    my $dsn = "dbi:mysql:host=$Host;dbname=$DbName";
    
    $Util = MySQL::Util->new(
            dsn => $dsn,
            user => $User,
            pass => $Pass 
        );
}

sub check_required
{
	my $opt = shift;
	my $arg = shift;

	print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line
{
	my @tmp = @ARGV;
    my $help;
    
    my $rc = GetOptions("h=s"    => \$Host,
    					"d=s"    => \$DbName,
                        "u=s"    => \$User,
                        "p=s"    => \$Pass,
                        "help|?" => \$help);

    print_usage("usage:") if $help;

    check_required('-u', $User);
	check_required('-h', $Host);
	check_required('-d', $DbName);
    
    if (!($rc) || (@ARGV != 0)) {
        ## if rc is false or args are left on line
        print_usage("parse_cmd_line failed");
    }
    
    @ARGV = @tmp;
}

sub print_usage
{
	print STDERR "@_\n";

	print "\n$0\n".
          "\t-u <user>\n".
		  "\t-h <host>\n".
          "\t-d <dbname>\n".
                    "\t[-p <pass>]\n".

          "\t[-?] (usage)\n".
          "\n";

	exit 1;
}
