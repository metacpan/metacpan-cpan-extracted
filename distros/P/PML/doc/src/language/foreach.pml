@include ( ../common/common.pmlh )
@SECTION ( The @CODE(foreach) function )
@SUBSECTION ( How to loop )
The @CODE(foreach) function is used to loop over a set of
values. Let's look at an example.
@CODE_START()
	\@foreach ( 1, 2, 3, 4, 5, 6 ) {
		This is loop number \${.}\\n
	
	}
@CODE_END()
The output of the above code is:
@CODE_START()
@foreach ( 1, 2, 3, 4, 5, 6 ) {
	This is loop number ${.}\n
} @CODE_END()
Each time through the loop, the special variable @CODE(\${.}) will get
set to the current argument. That special @CODE(\\n) insterts a new line.
This is necessary to get the next loop to be on a new line. This makes
it possible to loop and keep the loop text on the same line.
#################
@SUBSECTION (Looping over variables)
You can also loop over an array you have set.
@CODE_START()
	\@set( cookiejar, peanutbutter, oatmeal, sugar )
	
	\@foreach ( \${cookiejar} ) {
		I like \${.} cookies\\n
	}
@CODE_END()
That code would output:
@CODE_START()
@set( cookiejar, peanutbutter, oatmeal, sugar )
@foreach( ${cookiejar} ) {
	I like ${.} cookies\n
} @CODE_END()
