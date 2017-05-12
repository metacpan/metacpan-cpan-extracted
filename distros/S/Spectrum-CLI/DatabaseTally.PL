use FindBin;
die unless ($FindBin::Script =~ m/^(.*?)\.PL$/);
open(STDOUT, ">$1") || die;
print <DATA>
__END__
#! /usr/local/bin/perl

# DatabaseTally - a reimplementation of "vnmsh/sample_scripts/database_tally"
# Copyright (C) 2000  Dave Plonka

# $Id: DatabaseTally.PL,v 1.2 2000/01/21 21:22:16 dplonka Exp $
# Dave Plonka <plonka@doit.wisc.edu>

=head1 NAME

DatabaseTally - a reimplementation of "vnmsh/sample_scripts/database_tally"

=head1 SYNOPSIS

 DatabaseTally <vnm-name>

=head1 DESCRIPTION

The script will determine how many models of each type are currently in
the database. This information can be useful when evaluating system
performance.

=head1 EXAMPLE

   $ DatabaseTally <vnm-name>

A listing of all the model types and the number of models of each
model type is displayed to the screen. It may be more useful to redirect
the output to a file.

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>

=cut

################################################################################
#									       #
#   database_tally                                                             #
#   --------------                                                             #
#   The script will determine how many models of each type are currently in    #
#   the database. This information can be useful when evaluating system        #
#   performance.    						               #
#                                                                              #
#   USAGE:                                                                     #
#   ------                                                                     #
#                                                                              #
#   database_tally <vnm-name>                                                  #
#                                                                              #
#   A listing of all the model types and the number of models of each          #
#   model type is displayed to the screen. It may be more useful to redirect   #
#   the output to a file.  				                       #
#                                                                              #
################################################################################

use Spectrum::CLI;

my $cli = new Spectrum::CLI { CLIMNAMEWIDTH => 16, verbose => 1 }, $ARGV[0];

# do the "work":
map { $total++; $_{$_->{MTypeName}}++ } $cli->show_models;

# The rest just makes the output look like that of "database_tally":
print "\n";
map { write } sort keys(%_);
print  "=================\n";
printf("%5d   total\n", $total);
print "\n";

exit;

format STDOUT =
@>>>    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$_{$_} $_
.
