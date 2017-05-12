@include(../common/common.pmlh)
@SECTION(The if function)
@SUBSECTION(How to make a descesion)
You can use the @CODE(\@if) function to tell PML what text to output
based on some other data. Let's take a look:
@CODE_START()
	\@if(1)
	{
		This text is printed if the condition is true
	}
	\@else
	{
		This text is printed if the condition is false
	}
@CODE_END()
The @CODE(\@if) function requires that you give it a condition. 
If that condition is true then it will process the text in the 
block flowing the @CODE(\@if). If the condition is false and
you supply an @CODE(\@else) then PML will process the text in the
block following the @CODE(\@else). The @CODE(\@else) function
is optional, but if you use it, it must follow an @CODE(\@if) function.
########################
@SUBSECTION(True and false)
What is true and false is the same as what Perl considers true or false.
The very simple answer is: Blank conditions and 0 are false, everything
else is true.
########################
@SUBSECTION(Cool stuff in the condition)
Just like all other PML functions that take arguments, the @CODE(\@if)
function can take variables. Let's look at another example:
@CODE_START()
	\@set('condition', 1)
	
	\@if (\${condition}) {
		This text will get printed
	}
	
	\@set('condition', 0)
	
	\@if (\${condition}) {
		This text will NOT get printed
	}
@CODE_END()
########################
@SUBSECTION(elsif)
Just like Perl, PML has a @CODE(\@elsif) function. This function must follow
a @CODE(\@if) function, and like @CODE(\@if), it must be given a condition.
If the condition to @CODE(\@if) is false, then the condition to the next
@CODE(\@elsif) function is checked. You can have as many @CODE(\@elsif)
functions that you want. Here is an example:
@CODE_START()
	\@set('c1', 0)
	\@set('c2', 0)
	\@set('c3', 1)
	
	\@if (\${c1})
	{
		This text will be printed if c1 is true
	}
	\@elsif (\${c2})
	{
		This text will be printed if c2 is true
	}
	\@elsif (\${c3})
	{
		This text will be printed if c3 is true
		(which it is in this example)
	}
	\@else
	{
		This text will be printed if nothing above
		was true.
	}
@CODE_END()
###########################
@SUBSECTION( unless )
Another function that came from Perl is the @CODE(unless) function.
@CODE(unless) is just like @CODE(if) except that the code in the
@CODE(unless) block is executed when the condition is false not
true. @CODE(unless) supports @CODE(elsif) and @CODE(else) just like
@CODE(if).
@CODE_START()
	\@set( condition, 0 )
	
	\@unless ( \${condition} ) {
		This text will get output because
		the condition is false
	} \@else {
		This text would get output if the
		condition was true
	}
@CODE_END()
