#! /bin/sh

# podhtmleasy.sh < pod_file > html_file

perl -MPod::HtmlEasy -e'Pod::HtmlEasy->new->pod2html("-",title,"test.html")'
