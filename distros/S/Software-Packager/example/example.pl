#!/usr/bin/perl -w
=head1 NAME

example.pl - An example script on how to use the Software::Packager module.

=head1 DESCRIPTION

I created this script after a request from someone who was using this module
asked how to properly use the Software::Packager module.

There is not really much to the process.

You start in the usual way...

B< #!/usr/bin/perl
 use strict;
 use Software::Packager;
>

next we need to create an object with which to reference the Software::Packager

B< my $packager = new Software::Packager;
>

This will try to return the Software::Packager::E<lt>platformE<gt> for your current
platform.

Alternativly you can specify the Software::Packager::E<lt>sub classE<gt> that you want 
to use.

B< my $packager = new Software::Packager('tar');
>

=cut

################################################################################

####################
# Standard modules
use strict;
use Getopt::Std;
use Software::Packager;

####################
# Variables
use vars qw($opt_h);
getopts('h');

my $packager = new Software::Packager('tar');

####################
# The script

usage() if $opt_h;


################################################################################
# Function:	usage()
# Description:	Prints the usage and exits.
# Arguments:	None.
# Returns:	None.
#
sub usage
{
	exec "perldoc $0";
}



