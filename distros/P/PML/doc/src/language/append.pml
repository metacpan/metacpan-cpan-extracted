@include(../common/common.pmlh)
@SECTION(Append)

The @CODE(append) function appends a string to a variable. Before the append, 
the data in the variable will have spaces removed from the end of it. Then 
all the spaces will be removed from the front of the string. Finally
the sting is append to the variable with one space between.
@BREAK()

If the variable is an array, @CODE(append) will add another element to the end of the array.

@CODE_START()
	\@set(myvar, Test One)
	\@append(myvar, and Two)
	\# myvar is now "Test One and Two"

	\@set(test, 1, 2, 3)
	\@append(test, 4)
	\# test is now (1, 2, 3, 4) (array)
@CODE_END()
