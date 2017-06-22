package Rapi::Blog::Template::Postprocessor::MarkdownElement;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use String::Random;

# This post-processor should only be used when the content is being rendered within
# an html document which has loaded the marked.js based markdown_elements.js script

sub process {
  shift if ($_[0] eq __PACKAGE__);
  my ($output_ref, $context) = @_;
  
  # instead of doing this here, we're now doing it in the AccessStore. But leaving this
  # commented-out for future reference.
  ## If we're being processed (i.e. included within) from another Markdown template,
  ## return the output as-is, since we only want to process at the top-level
  #return $$output_ref if ($context->next_template_post_processor||'' eq __PACKAGE__);
  
  my $markedId = 'markdown-el-'. String::Random->new->randregex('[a-z0-9]{6}');
  
  return join("\n",
    '<xmp style="display:none;" id="'.$markedId.'">',
      $$output_ref,
    '</xmp>',
    # New: now self-contained, accessing our own copy of marked.js/markdown_elements.js
    '<script src="_ra-rel-mnt_/assets/local/misc/static/js/marked-el.js"></script>',
    '<script>',
    '  processMarkdownElementById("'.$markedId.'")',
    '</script>'
  );
}


1;