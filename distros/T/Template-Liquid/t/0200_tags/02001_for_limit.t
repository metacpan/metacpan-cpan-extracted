use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
use Data::Dumper;
plan tests => 2;
my $template = Template::Liquid->parse(<<'TEMPLATE');
First: {% for post in posts limit:1 %}{{ post }}{% endfor %}
---
{% for post in posts limit:10 %}{{post}},{% endfor %}
TEMPLATE
my @list   = qw( 1 2 3 4 5 6 7 8 9 10 11 );
my $result = $template->render(posts => \@list);
is $result, << 'RESULT', "We render the expected list";
First: 1
---
1,2,3,4,5,6,7,8,9,10,
RESULT

# This is a half-truth. Of course, Template::Liquid is allowed to modify the
# list passed in, but it should still contain the original number of elements
# so other template parts can still access that.
is 0 + @list, 11, "The original list remains unmodified" or
    diag Dumper \@list;
