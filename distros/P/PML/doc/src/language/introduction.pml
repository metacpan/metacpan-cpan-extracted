@include(../common/common.pmlh)
@SECTION(Introduction)
@SUBSECTION(What\'s the Problem)
Here's the problem. You develop this really cool CGI script, you spent
months making the HTML that it generates look good. Then someone tells
you "Let's make a few changes to the interface". Well, now you have
to dig through your perl code and change all that HTML that you are
generating.@BREAK()
#
Wouldn't it be nice if you could put all your HTML in seperate files!
Then you would only have to change those files to update the interface,
and no one whould have to chnage any code. That brings a whole new problem
though, because there is some HTML that you generate on the fly and there
is no way to make it static and put it in a file. In comes PML.
#
@SUBSECTION(PML can help)
PML allows you to take all your HTML from within your script and put
it into files. Those files are mostly HTML, but also contain a little
of the PML Markup Language to do things like variabels and flow control.
Now your CGI script can have PML read a file, send it some variables
and send the results to the browser. PML is simple enough so that
you can have your HTML team edit the files, giving you more time
to code.@BREAK()
#
@SUBSECTION(Example)
The best way to describe PML is to take a quick look at some.
@CODE_START()
	@HTML_BRACKET(html)
	@HTML_BRACKET(head)
		@HTML_BRACKET(title)\${title}@HTML_BRACKET(/title)
	@HTML_BRACKET(/head)
	@HTML_BRACKET(body)
	\@if (\${i_am_frank})
	{
		\ @HTML_BRACKET(h1)Cool, you are Frank!@HTML_BRACKET(/h1)
	}
	\@else
	{
		\ @HTML_BRACKET(h1)You must not be Frank.@HTML_BRACKET(/h1)
	}
	@HTML_BRACKET(/body)
	@HTML_BRACKET(/html)
@CODE_END()
@BREAK()
The first thing you see is @CODE(\${title}). That is a PML variable.  When PML
is executing your PML file, it will replace the @CODE(\${title}) string with
the  actual value of that variable. That value can be set from the command
line, from within your perl script, from within the PML text and also from
within PML itself.@BREAK()
#
Next you will see "@CODE(\@if (\${i_am_frank}))". This should look very
familiar to a programmer. When PML is executing your PML file, is will decide
if the variable @CODE(\${i_am_frank}) is true. If it is, PML will output the
text that is in the "if block". Otherwise it will output the text in the "else
block". @BREAK()
#
PML offers a lot more then what we have seen so far. You can also
extend PML from within your perl application or by writing a PML Module
in perl.
