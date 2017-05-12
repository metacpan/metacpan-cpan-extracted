#
# This is the example file for the set family of PML functions
#
#
# The set function let's you set a variables value
#
#
# Syntax:
#
# @set(variable_name, value)
#
# Let's give it a try
#

Here we are before the first set
@set("test1", "This is a test set")
And then after the set we can use the variable like so "${test1}"

#
# There is also a way to set a variable as long as it is not already set
#
# Syntax:
#
# @setif(variable_name, value)
#
# Let's see

@set("test2", "A")
Before the setif our variable is ${test2}

@setif("test2", "B")
After the setif our variable is ${test2}

#
# And yet another set allows you to append instead of replace
#
#
# Syntax:
#
# @append(variable_name, value_to_append)
#
#
#

@set("test3", "This is a")
Before the append the value was ${test3}

@append("test3", "test")
After the append the value was ${test3}

#
#
# one last set is the prepend
#
# Syntax:
#
# @prepend(variable_name, value)
#
#
# and

@set("test4", "test")
Before the prepend the value was ${test4}

@prepend("test4", "This is a")
After the prepend the value was ${test4}

#
