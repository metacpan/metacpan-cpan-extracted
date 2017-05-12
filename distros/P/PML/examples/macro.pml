#
# Example file for using the macro function in PML
#
#
#
# a macro allows you to create a new PML function that when
# called executes the PML code in it's block
# 
# let's see one in action
#
# 
@macro("MY_MACRO")
{
	This is my macro.
}
#
#
# now you can call your new macro a couple of times
@MY_MACRO()
@MY_MACRO()
#
#
# you can also make a macro with arguments
#
#
@macro("MY_MACRO_TWO", "arg1", "arg2")
{
	arg1 is ${arg1}
	arg2 is ${arg2}
}
#
#
# now we can call this guy a few times
#
@MY_MACRO_TWO("Hi", "Hello")
@MY_MACRO_TWO("Hello", "Hi")
