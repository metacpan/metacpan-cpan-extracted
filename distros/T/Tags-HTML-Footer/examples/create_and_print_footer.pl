#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Footer;
use Tags::HTML::Footer;
use Tags::Output::Indent;
use Unicode::UTF8 qw(encode_utf8);

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Footer->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for footer.
my $footer = Data::HTML::Footer->new(
        'author' => 'John',
        'author_url' => 'https://example.com',
        'copyright_years' => '2022-2024',
        'height' => '40px',
        'version' => '0.07',
        'version_url' => '/changes',
);

# Initialize.
$obj->init($footer);

# Process a.
$obj->process;
$obj->process_css;

# Print out.
print "HTML:\n";
print encode_utf8($tags->flush);
print "\n\n";
print "CSS:\n";
print $css->flush;

# Output:
# HTML:
# <footer>
#   <span class="version">
#     <a href="/changes">
#       Version: 0.07
#     </a>
#   </span>
#   ,&nbsp;
#   © 2022-2024
# 
#   <span class="author">
#     <a href="https://example.com">
#       John
#     </a>
#   </span>
# </footer>
# 
# CSS:
# #main {
#         padding-bottom: 40px;
# }
# footer {
#         text-align: center;
#         padding: 10px 0;
#         background-color: #f3f3f3;
#         color: #333;
#         position: fixed;
#         bottom: 0;
#         width: 100%;
#         height: 40px;
#         font-family: Arial, Helvetica, sans-serif;
# }