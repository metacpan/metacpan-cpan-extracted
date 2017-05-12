from sources import *
from content import *
from formatter import *

import time

# The following defines the HTML header used by all generated pages.
#
html_header_1 = """\
<html>
<header>
<title>"""

html_header_2= """ API Reference</title>
<basefont face="Verdana,Geneva,Arial,Helvetica">
<style content="text/css">
  P { text-align=justify }
  H1 { text-align=center }
  LI { text-align=justify }
</style>
</header>
<body text=#000000
      bgcolor=#FFFFFF
      link=#0000EF
      vlink=#51188E
      alink=#FF0000>
<center><h1>"""

html_header_3=""" API Reference</h1></center>
"""



# The HTML footer used by all generated pages.
#
html_footer = """\
</body>
</html>"""

# The header and footer used for each section.
#
section_title_header = "<center><h1>"
section_title_footer = "</h1></center>"

# The header and footer used for code segments.
#
code_header = "<font color=blue><pre>"
code_footer = "</pre></font>"

# Paragraph header and footer.
#
para_header = "<p>"
para_footer = "</p>"

# Block header and footer.
#
block_header = "<center><table width=75%><tr><td>"
block_footer = "</td></tr></table><hr width=75%></center>"

# Description header/footer.
#
description_header = "<center><table width=87%><tr><td>"
description_footer = "</td></tr></table></center><br>"

# Marker header/inter/footer combination.
#
marker_header = "<center><table width=87% cellpadding=5><tr bgcolor=#EEEEFF><td><em><b>"
marker_inter  = "</b></em></td></tr><tr><td>"
marker_footer = "</td></tr></table></center>"

# Source code extracts header/footer.
#
source_header = "<center><table width=87%><tr bgcolor=#D6E8FF width=100%><td><pre>\n"
source_footer = "\n</pre></table></center><br>"

# Chapter header/inter/footer.
#
chapter_header = "<br><center><table width=75%><tr><td><h2>"
chapter_inter  = "</h2><ul>"
chapter_footer = "</ul></td></tr></table></center>"


# source language keyword coloration/styling
#
keyword_prefix = '<font color="darkblue">'
keyword_suffix = '</font>'

section_synopsis_header = '<h2>Synopsys</h2><font color="cyan">'
section_synopsis_footer = '</font>'

# Translate a single line of source to HTML.  This will convert
# a "<" into "&lt.", ">" into "&gt.", etc.
#
def html_quote( line ):
    result = string.replace( line,   "&", "&amp;" )
    result = string.replace( result, "<", "&lt;" )
    result = string.replace( result, ">", "&gt;" )
    return result


# same as 'html_quote', but ignores left and right brackets
#
def html_quote0( line ):
    return string.replace( line, "&", "&amp;" )


def dump_html_code( lines, prefix = "" ):
    # clean the last empty lines
    #
    l = len( self.lines )
    while l > 0 and string.strip( self.lines[l - 1] ) == "":
        l = l - 1

    # The code footer should be directly appended to the last code
    # line to avoid an additional blank line.
    #
    print prefix + code_header,
    for line in self.lines[0 : l+1]:
        print '\n' + prefix + html_quote(line),
    print prefix + code_footer,



class HtmlFormatter(Formatter):

    def __init__( self, processor, project_title, file_prefix ):

        Formatter.__init__( self, processor )

        global html_header_1, html_header_2, html_header_3, html_footer

        if file_prefix:
            file_prefix = file_prefix + "-"
        else:
            file_prefix = ""

        self.project_title = project_title
        self.file_prefix   = file_prefix
        self.html_header   = html_header_1 + project_title + html_header_2 + \
                             project_title + html_header_3

        self.html_footer = "<p><center><font size=""-2"">generated on " +   \
                            time.asctime( time.localtime( time.time() ) ) + \
                           "</font></p></center>" + html_footer

        self.columns = 3

     def  markup_enter( self, markup, block ):
        if markup.tag == "description":
            print description_header
        else:
            print marker_header + markup.tag + marker_inter

        self.print_html_markup( markup )

    def  markup_exit( self, markup, block ):
        if markup.tag == "description":
            print description_footer
        else:
            print marker_footer

    def  block_exit( self, block ):
        print block_footer


    def  section_exit( self, section ):
        print html_footer


    def section_dump_all( self ):
        for section in self.sections:
            self.section_dump( section, self.file_prefix + section.name + '.html' )
        