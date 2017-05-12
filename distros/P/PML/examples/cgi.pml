@need(CGI)

@cgi::header()
@cgi::start_html(Test Web Page)

@cgi::h1(This is my test web page)

@cgi::p
(
	This is a cool paragraph
)

@cgi::tt
(
	This is should be a mono-spaced font
)

@cgi::startform
(
	'-action', @cgi::url()
)

@cgi::endform()
@cgi::end_html()
