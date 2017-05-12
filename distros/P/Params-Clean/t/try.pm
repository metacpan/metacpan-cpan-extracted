package try;

#################################################################################################################################################################
#
#	Functions for testing PARAMS::CLEAN
#
#################################################################################################################################################################

### Declares our own "try" function for cleaner test cases ###

	use strict; use warnings;
	use Test::More 'no_plan';
	use base "Exporter";
	use Params::Clean;
	
	our @EXPORT=qw/try call get expect/;
	push @EXPORT, qw/use_ok skip diag is_deeply/;	# also export anything we use from Test::More

#—————————————————————————————————————————————————————————————————————————————————————————————
	
#Declare some subs that simply return an array ref
#We're makeing 3 different ones just so the code can be read better (self-documenting!)
sub call   { return [@_] }
sub get    { return [@_] }
sub expect { return [@_] }

#Now make our own wrapper for "is" that takes care of declaring the subs we need
#(or rather, faking the sub that would be called by resetting @_ instead!)
sub try
{
	my $name=shift;
	return diag "PENDING: $name\n" unless @_;	#if all we have is a name, it's just a reminder to add a test for it!
	
	my @call=@{+shift};		#arguments we're passing in
	my @params=@{+shift};	#parameters to look for
	my @expect=@{+shift};	#values that get parsed out
	
	#print "$name\n@call\n@params\n@expect\n";
	
	#Reset @_ and call args() directly
	@_=@call;
	is_deeply [args(@params)], [@expect], $name;
}

#—————————————————————————————————————————————————————————————————————————————————————————————
