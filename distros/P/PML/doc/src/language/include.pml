@include(../common/common.pmlh)
@SECTION(The @CODE(include) function)

The PML @CODE(include) function is used to include another
file in the place of the @CODE(include) function. It takes
an argument list of files to include.

@BREAK()

To place file 'b' inside file 'a' at runtime use the following 
code:

@CODE_START()
	\# This is file a
	Blah Blah Blah
	\@include(b)
@CODE_END()

The @CODE(include) function is special in that it is a parse time
function. This means that the file you are including must exist
during the parsing of the original file, and you can not use
variables or other functions in the argument list of the
@CODE(include). One exception to this rule is if the variable
was defined outside the file, such as in a Perl script.
