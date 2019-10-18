package Rapi::Blog::Template::Postprocessor::TextMarkdown;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Text::Markdown 'markdown';

# This post-processor converts markdown to html using the native perl
# Text::Markdown package. The benefit of this is that the conversion
# happens on the server-side, and doesn't rely on client-side javascript.
# However, it doesn't do nearly as good a job as marked.js, which is used
# by the default post-processor MarkdownElement. 

sub process {
  shift if ($_[0] eq __PACKAGE__);
  my ($output_ref, $context) = @_;
  
  return markdown($$output_ref);
}


1;