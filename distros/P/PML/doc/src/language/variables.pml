@include(../common/common.pmlh)
@SECTION(Variables)
@SUBSECTION(What\'s a variable?)
Just like in most programming languages, PML supports variables. Variables
are a way to label some data, they are like containers with names. When
you use a variable in PML it is replaced with what ever data it contains.
@BREAK()
#
Let's look at an example:
@CODE_START()
	\@set('cookiejar', 'peanutbutter')
	The cookiejar has \${cookiejar} cookies
@CODE_END()
Let me explain what just happedned. The first line put the data
@CODE(peanutbutter) into the variable (container) @CODE(cookiejar).
From this point on, when ever your make mention of @CODE(cookiejar)
PML will replace it with @CODE(peanutbutter). In order to keep PML
from replacing the word @CODE(cookiejar) when you really wanted the
word @CODE(cookiejar) it requires you to inclose your variable name
in @CODE(\${}) like on line two above. When ever PML sees something
like this: @CODE(\${word}) it will look up the word and replace that
text with the data in that variable.
@BREAK()
#
And in case you were wondering, when you run that PML code from above
this is what gets returned from PML:
@CODE_START()
	The cookiejar has peanutbutter cookies
@CODE_END()
#
@SUBSECTION(Variable Names)
All variable names must begin with either an underscore @CODE(\'_\') or
a letter. It can only contain letters, numbers and underscores.
#
@SUBSECTION(Data)
Variables can contain more then one value at a time. It is like a Perl
array (internaly it is a Perl Array Reference). You can access the different
'elements' of your variable using a subscript like this:
@CODE_START()
	\@set('cookiejar', 'peanutbutter', 'oatmeal', 'sugar')
	Cookie one is \${cookiejar[0]}
	Cookie two is \${cookiejar[1]}
	Cookie three is \${cookiejar[2]}
@CODE_END()
This prints
@CODE_START()
	Cookie one is peanutbutter
	Cookie two is oatmeal
	Cookie three is sugar
@CODE_END()
For a better way to do the above see @CODE(\@foreach). There are other
@CODE(\@set) functions too, like @CODE(\@append, \@prepend, \@concat) so
see those sections for more information.
