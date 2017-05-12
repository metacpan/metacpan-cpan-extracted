#
#
# when this file is ran through PML it should
# generate a warning
#
@warning(1)
${test}
#
# the reason that you get a warning is because
# the variable "test" does not have a value 
# assigned to it with the set function,
# therefore it is undefined or is blank.
#
# this would not generate a warning if you did
# not turn on warnings
#
# warning is a compile time option, so as
# pml is parsing your script it will change
# the warning flag right then and there,
# but if you turn warnings off again
# and you encounter a run-time warning,
# you will not see that warning because
# you turned off warnings durring the parsing phase
#
