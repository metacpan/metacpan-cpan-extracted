#
# This is the example file for the perl function in PML
#
# The perl function allows you to embed perl code and have it called
#
# Syntax:
#
# @perl
# {
# 	some perl code
# }
#
# 
# Let's see one in action
#
#
This is before the first perl function

@perl
{
	my $x = "test";
	return "and here we are in the perl function with x = $x";
}

And this is after the first perl function

#
#
