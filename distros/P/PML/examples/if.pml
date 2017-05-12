# Lines that start with a pound sign are comments
# and are skiped by pml
#
#
#
# This is an example file to show you how to use the PML if function
#
#
# Syntax:
#
# @if ( something )
# {
#	pml code
#	pml code
# }
#
#
#
#
# Let's start with something simple
# 1 is a true value, so if we give that to IF...
#

if 1 is a true number then you sould see
a star right here
           |
	   V
@if (1)
{
	-> * <-
}

       ^
	   |
#
# This example also shows you how pml will not output the pml code
# or even a blank line, just as if it were never there
#
#
#
# What if you wanted to do something if the value to IF was false?
# Well that is where an else comes in.
#
# Syntax:
#
# @if (something)
# {
# 	this text if something is true
# }
# @else
# {
#	this code if something is false
# }
#
# Let's try this
#
#

@if (0)
{
	Oh no, you should not see this!
}
@else
{
	It appears that the number 0 is false
	
}
#
#
#
# Another way to use IF is the ELSIF function which will execute if
# the condition to the IF fails and the condition to the ELSIF passes
# 
# Syntax:
#
# @if (condition)
# {
# 	condition was true!
# }
# @elsif (condition2)
# {
# 	condition was false and condition2 was true
# }
# @elsif (condition3)
# {
#	condition was false, condition2 was false and condition3 was true
# }
# @else
# {
#	everything was false
# }
#
# let's try
#
#
@if (0)
{
	oh no, 0 is not true
}
@elsif (1)
{
	elsif seems to work if this printed
	
}
@else
{
	oh no, elsif did not work, bad PML bad.
}
#
# and one last check to show that PML is a semi-freeform language
#
@if (0) {not here} 
@elsif (1) { you should see this line }
# the current version of PML will not allow the two blocks above
# to be on the same line, maybe this will change one day
