#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Pager;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Pager->new(
        'css' => $css,
        'tags' => $tags,
        'url_page_cb' => sub {
                my $page = shift;
                return 'https://example.com/?page='.$page;
        }
);

# Process pager.
$obj->process({
        'actual_page' => 1,
        'pages_num' => 1,
});
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# <div class="pager">
#   <p class="pager-paginator">
#     <strong class="pager-paginator-selected">
#      1
#     </strong>
#   </p>
# </div>
#
# .pager a {
#         text-decoration: none;
# }
# .pager-paginator {
#         display: flex;
#         flex-wrap: wrap;
#         justify-content: center;
#         padding-left: 130px;
#         padding-right: 130px;
#         float: both;
# }
# .pager-prev_next {
#         display: flex;
# }
# .pager-paginator a, .pager-paginator strong, .pager-paginator span, .pager-next,
# .pager-next-disabled, .pager-prev, .pager-prev-disabled {
#         display: flex;
#         height: 55px;
#         width: 55px;
#         justify-content: center;
#         align-items: center;
#         border: 1px solid black;
#         margin-left: -1px;
# }
# .pager-prev, .pager-next {
#         display: inline-flex;
#         align-items: center;
#         justify-content: center;
# }
# .pager-paginator a:hover, .pager-prev_next a:hover {
#         color: white;
#         background-color: black;
# }
# .pager-paginator a {
#         color: black;
# }
# .pager-paginator-selected {
#         background-color: black;
#         color: white;
# }