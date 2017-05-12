@include(../common/common.pmlh)
@SECTION(PML Macros)
@SUBSECTION(What is a macro?)

A macro is a way to repeat text over and over again without having 
to type it over and over again. It lets you group some text together
and give it a name. Then to use that text you just call it by name.

@SUBSECTION(Defining a macro)

Use the PML @CODE(macro) function to define a macro. The @CODE(macro)
function takes arguments and a block. The first argument is the name
to call the macro and the block is the actual text. Example:

@CODE_START()
	\@macro( mymacro ) {
		This text is called mymacro
	}
@CODE_END()

@SUBSECTION(Using the macro)

To insert the text from above macro use call it by it's name:

@CODE_START()
	Some text before the call to the macro
	\@mymacro() 
	Some text after the call to the macro
@CODE_END()

After that text is processed, it will look like:

@CODE_START()
	Some text before the call to the macro
	This text is called mymacro
	Some text after the call to the macro
@CODE_END()

@SUBSECTION(Macro arguments)

PML macros can take arguments. Here is an example:

@CODE_START()
	\@macro( mymacro, myvariable ) {
		The variable you passed was \${myvariable}
	}
@CODE_END()

Then to call that macro you just:

@CODE_START()
	\@mymacro(test)
@CODE_END()

@SUBSECTION(The ARGV Variable)

If your macro was given more arguments then you declared
in your macro definition, they will be avaliable in the
@CODE(\${ARGV}) varible which is an array.
