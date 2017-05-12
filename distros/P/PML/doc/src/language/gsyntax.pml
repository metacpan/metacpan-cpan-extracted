@include(../common/common.pmlh)
@SECTION(General Syntax)
@SUBSECTION(Text and Whitespace)

All text and whitespace is preserved. The way that you alter the
output text is using PML functions and variables. PML functions
begin with an @CODE(\'\@\') symbol. PML variables begin with a
@CODE(\'\$\') sign. If you want to use a @CODE(\'\@\') or @CODE(\'\$\')
in your text, you will need to place a backslash @CODE(\'\\\') in
front of it. This also makes it so if you need to put a backslash
in your text, you will need to put in two.

@SUBSECTION(Arguments)

Most PML functions take arguments. The PML @CODE(set) function
needs to know which variable to set and what value to set. Arguments
are given inbetween  parathensis. Each argument is seperated by a
comma.  There is no need to put quotations around text, unless it
contains a comma. You may use variable, and even other PML functions
inside the argument list. The argument list can also be empty for
some PML functions.

@BREAK()

Here are some examples of arguments, using the PML @CODE(set) function:
@CODE_START()
	\# lines that START with a sharp/pound/hash are skipped
	\# how about one argument
	\@set(ThisIsTheNameOfOneVariable)

	\# And now two arguments
	\@set(myvariable, Set myvariable to this string)

	\# or three
	\@set(x, this is two, this is three)

	\# An argument that is a variable
	\@set(x, ${y})

	\# An argument that is a PML function
	\@set(x, @perl{1})
@CODE_END()

@SUBSECTION(Blocks)

Some of the PML functions need blocks of text to work with. One 
example is the PML @CODE(if) function. The @CODE(if) function takes
one argument and a block. It will output the block of text if
the argument is true.

@BREAK()

Inside of the block, you can use anything that you can use inside of a block.
These include, plain text, variables and functions. A block is the text 
inbetween braces @CODE({) and @CODE(}).

@BREAK()

Here is an example using the PML @CODE(if) function:
@CODE_START()
	\@if( this is true) {
		Then this text will get output
	}
@CODE_END()

Because the parser uses the braces as delimiters, you must use caution
that you don't use a brace unless you place a backslash before it.

@BREAK()

Here is a block inside another block:
@CODE_START()
	\@if( this is true) {
		here comes another
		\@if( this one too) {
			this is block two
		}

		back to block one
	}
@CODE_END()

@SUBSECTION(Comments)

Comments is text that is skipped by the parser. It is a great way
to document what your text is doing, or to temparily to remove text.
PML comments are started by a @CODE(#), as long as it is the first
non-whitespace charater on the line. They last until the end of the
line. To use a @CODE(#) you should put a backslash before it.

@CODE_START()
	\# This is a comment
	This # is not
	\\\# This is not either
@CODE_END()

