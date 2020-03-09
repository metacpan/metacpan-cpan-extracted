package Template::Liquid::Filters;
our $VERSION = '1.0.18';
use strict;
use warnings;

sub import {
    Template::Liquid::register_filter(
        qw[
            abs	append at_least at_most
            capitalize ceil compact concat
            date default divided_by downcase
            escape escape_once
            first floor
            join
            last lstrip
            map minus modulo
            newline_to_br
            plus prepend
            remove remove_first replace replace_first reverse round rstrip
            size slice sort sort_natural split strip strip_html strip_newlines
            times truncate truncatewords
            uniq upcase url_decode url_encode
            where
            money stock_price
            ]
    );
}

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Filters - Default Filters Based on Liquid's Standard Set

=head1 Synopsis

Filters are simple methods that modify the output of numbers, strings,
variables and objects. They are placed within an output tag C<{{ }}> and are
denoted by a pipe character C<|>.

    # product.title = "Awesome Shoes"
    {{ product.title | upcase }}
    # Output: AWESOME SHOES

In the example above, C<product> is the object, C<title> is its attribute, and
C<upcase> is the filter being applied.

Some filters require a parameter to be passed.

    {{ product.title | remove: "Awesome" }}
    # Output: Shoes

Multiple filters can be used on one output. They are applied from left to
right.

    {{ product.title | upcase | remove: "AWESOME"  }}
    # SHOES


=head1 Standard Filters

These are the current default filters. They have been written to behave exactly
like their Ruby Liquid counterparts accept where Perl makes improvment
irresistable.

=head2 C<abs>

Returns the absolute value of a number.

    {{  4 | abs }} => 4
    {{ -4 | abs }} => 4

=cut

sub abs { CORE::abs($_[0]) }

=head2 C<append>

Append a string.

    {{ 'foo' | append:'bar' }} => 'foobar'

=cut

sub append { my ($x, $y) = @_; return $x . (defined $y ? $y : ''); }

=head2 C<at_least>

Limits a number to a minimum value.

	{{ 4 | at_least: 5 }} => 5
	{{ 4 | at_least: 3 }} => 4

=cut

sub at_least {
    my ($value, $min) = @_;
    $min > $value ? $min : $value;
}

=head2 C<at_most>

Limits a number to a maximum value.

	{{ 4 | at_most: 5 }} => 4
	{{ 4 | at_most: 3 }} => 3

=cut

sub at_most {
    my ($value, $max) = @_;
    $max < $value ? $max : $value;
}

=head2 C<capitalize>

Capitalize words in the input sentence. This filter first applies Perl's C<lc>
function and then the C<ucfirst> function.

    {{ 'this is ONLY a test.' | capitalize }} => This is only a test.

=cut

sub capitalize { my ($x) = @_; return ucfirst lc $x; }

=head2 C<ceil>

Rounds an integer up to the nearest integer.

    {{ 4.6 | ceil }} => 5
    {{ 4.3 | ceil }} => 5

=cut

sub ceil { my ($value) = @_; int($value) + ($value > int($value) ? 1 : 0) }

=head2 C<compact>

Removes any undefined values from an array.

For this example, assume C<site.pages> is an array of content pages for a
website, and some of these pages have an attribute called category that
specifies their content category. If we map those categories to an array, some
of the array items might be undefined if any pages do not have a category
attribute.

    {% assign all_categories = site.pages | map: "category" %}

    {% for item in all_categories %}
    - {{ item }}
    {% endfor %}

The output of this template would look like this:

    - business
    - celebrities
	-
    - lifestyle
    - sports
	-
    - technology

By using compact when we create our C<site_categories> array, we can remove all
the nil values in the array.

    {% assign all_categories = site.pages | map: "category" | compact %}

    {% for item in all_categories %}
    - {{ item }}
    {% endfor %}

The output of this template would look like this:

    - business
    - celebrities
    - lifestyle
    - sports
    - technology

=cut

sub compact {
    my ($list) = @_;
    [grep { defined $_ } @$list];
}

=head2 C<concat>

Concatenates (joins together) multiple arrays. The resulting array contains all
the items from the input arrays.


  {% assign fruits = "apples, oranges, peaches" | split: ", " %}
  {% assign vegetables = "carrots, turnips, potatoes" | split: ", " %}

  {% assign everything = fruits | concat: vegetables %}

  {% for item in everything %}
  - {{ item }}
  {% endfor %}

...becomes...

  - apples
  - oranges
  - peaches
  - carrots
  - turnips
  - potatoes

You can string togehter C<concat> filters to oin more than two array:

  {% assign furniture = "chairs, tables, shelves" | split: ", " %}
  {% assign vegetables = "carrots, turnips, potatoes" | split: ", " %}
  {% assign fruits = "apples, oranges, peaches" | split: ", " %}

  {% assign everything = fruits | concat: vegetables | concat: furniture %}

  {% for item in everything %}
  - {{ item }}
  {% endfor %}

...becomes...

  - apples
  - oranges
  - peaches
  - carrots
  - turnips
  - potatoes
  - chairs
  - tables
  - shelves

=cut

sub concat {
    my ($values, $more) = @_;
    [map {@$_} grep {defined} $values, $more];
}

=head2 C<date>

Converts a timestamp into another date format. The format for this syntax is
the same as C<strftime>.

  {{ article.published_at | date: "%a, %b %d, %y" }} => Fri, Jul 17, 15

  {{ article.published_at | date: "%Y" }} => 2015

C<date> works on strings if they contain well-formatted dates:

  {{ "March 14, 2016" | date: "%b %d, %y" }} => Mar 14, 16


Natural language dates are parsed by C<DateTime::Format::Natural>.

To get the current time, pass the special word <"now"> (or C<"today">) to date:

  This page was last updated at {{ "now" | date: "%Y-%m-%d %H:%M" }}.
	=> This page was last updated at 2019-09-19 17:48.

Note that the value will be the current time of when the page was last
generated from the template, not when the page is presented to a user if
caching or static site generation is involved.

=cut

sub date {
    CORE::state $DateTimeFormatNatural;
    my ($x, $y) = @_;
    $x = time() if lc $x eq 'now' || lc $x eq 'today';
    if (ref $x ne 'DateTime' && $x =~ m[\D]) {    # Any non-digit
        if (!defined $DateTimeFormatNatural) {
            require DateTime::Format::Natural;
            $DateTimeFormatNatural = DateTime::Format::Natural->new();
        }
        $x = $DateTimeFormatNatural->parse_datetime($x);
    }
    #
    $y = defined $y ? $y : '%c';
    return $x->strftime($y) if ref $x && $x->can('strftime');
    return                  if $x !~ m[^(\d*\.)?\d+?$]o;
    require POSIX;
    return POSIX::strftime($y, gmtime($x));
}

=head2 C<default>

Allows you to specify a fallback in case a value doesn't exist. default will
show its value if the left side is nil, false, or empty.

In this example, C<product_price> is not defined, so the default value is used.

  {{ product_price | default: 2.99 }} => 2.99

In this example, C<product_price> is defined, so the default value is not used.

  {% assign product_price = 4.99 %}
  {{ product_price | default: 2.99 }} => 4.99

In this example, C<product_price> is empty, so the default value is used.

  {% assign product_price = "" %}
  {{ product_price | default: 2.99 }} => 2.99

=cut

sub default {
    my ($x, $y) = @_;
    return length $x  ? $x : $y if !ref $x;
    return defined $x ? $x : $y;
}

=head2 C<divided_by>

Divides a number by another number.

The result is rounded down to the nearest integer (that is, the floor) if the
divisor is an integer.

  {{ 16 | divided_by: 4 }} => 4


  {{ 5 | divided_by: 3 }} = 1

=head3 Controlling rounding

C<divided_by> produces a result of the same type as the divisor -- that is, if
you divide by an integer, the result will be an integer. If you divide by a
float (a number with a decimal in it), the result will be a float.

For example, here the divisor is an integer:

  {{ 20 | divided_by: 7 }} => 2

Here it is a float:

  {{ 20 | divided_by: 7.0 }} => 2.85714285714286

Note that floats will not match thanks to how perl and ruby handle floating
point numbers.

=cut

sub divided_by {
    my ($x, $y) = @_;
    my $r = $x / $y;
    my ($_x) = $x =~ m[\.(\d+)$];
    my ($_y) = $y =~ m[\.(\d+)$];
    my ($_r) = $r =~ m[\.(\d+)$];
    $_x //= '';
    $_y //= '';
    $_r //= '';
    my $_lx = length $_x;
    my $_ly = length $_y;
    my $_lr = length $_r;
    ($_lx || $_ly)
        ? (sprintf '%0.' . ([sort $_lr, 1]->[-1]) . 'f', $r)
        : int $r;
}

=head2 C<downcase>

Makes each character in a string lowercase. It has no effect on strings which
are already all lowercase.

  {{ "Parker Moore" | downcase }} => parker moore

  {{ "apple" | downcase }} => apple

=cut

sub downcase { my ($x) = @_; return lc $x }

=head2 C<escape>

Escapes a string by replacing characters with escape sequences (so that the
string can be used in a URL, for example). It doesn't change strings that don't
have anything to escape.

  {{ "Have you read 'James & the Giant Peach'?" | escape }}
    => Have you read &#39;James &amp; the Giant Peach&#39;?

  {{ "Tetsuro Takara" | escape }} => Tetsuro Takara

=cut

sub escape {
    my ($x) = @_;
    $x =~ s/([^A-Za-z0-9\-\._~ \?])/
		my $x = ord $1;
		sprintf('&%s;',
			$1 eq '&' ? 'amp' :
			$1 eq '>' ? 'gt' :
			$1 eq '<' ? 'lt'  :
			$1 eq '"' ? 'quot'  :
			$1 eq "'" ? '#39' :
		"#$x")
	/gei;
    $x;
}

=head2 C<escape_once>

Escapes a string without changing existing escaped entities. It doesn't change
strings that don't have anything to escape.

  {{ "1 < 2 & 3" | escape_once }} => 1 &lt; 2 &amp; 3

  {{ "1 &lt; 2 &amp; 3" | escape_once }} => 1 &lt; 2 &amp; 3

=cut

sub escape_once {
    my ($x) = @_;
    $x =~ s/("|>|<|'|&(?!([a-z]+|(#\d+));))/
		sprintf('&%s;',
			$1 eq '&' ? 'amp' :
			$1 eq '>' ? 'gt' :
			$1 eq '<' ? 'lt'  :
			$1 eq '"' ? 'quot'  :
			$1 eq "'" ? '#39' :
		"#$x;")
	/gei;
    $x;
}

=head2 C<first>

Returns the first item of an array.

  {{ "Ground control to Major Tom." | split: " " | first }} => Ground


  {% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}

  {{ my_array.first }}
    => zebra

You can use C<first> with dot notation when you need to use the filter inside a
tag:

  {% if my_array.first == "zebra" %}
    Here comes a zebra!
  {% endif %}
    => Here comes a zebra!

=cut

sub first {
    my ($x) = @_;
    return ref $x eq 'ARRAY' ? @{$x}[0] : substr($x, 0, 1);
}

=head2 C<floor>

Rounds an integer down to the nearest integer.

  {{ 1.2 | floor }} => 1
  {{ 2.0 | floor }} => 2
  {{ 183.357 | floor }} => 183

Here the input value is a string:

  {{ "3.5" | floor }} => 3

=cut

sub floor { int $_[0] }

=head2 C<join>

Combines the items in an array into a single string using the argument as a
separator.

  {% assign beatles = "John, Paul, George, Ringo" | split: ", " %}
  {{ beatles | join: " and " }} => John and Paul and George and Ringo

=cut

sub join {
    my ($x, $y) = @_;
    return CORE::join($y, @{$x})      if ref $x eq 'ARRAY';
    return CORE::join($y, keys %{$x}) if ref $x eq 'HASH';
    return $x;
}

=head2 C<last>

Returns the last item of an array.

  {{ "Ground control to Major Tom." | split: " " | last }} => Tom.

  {% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}
  {{ my_array.last }} => tiger

You can use C<last> with dot notation when you need to use the filter inside a
tag:

 {% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}
 {% if my_array.last == "tiger" %}
    There goes a tiger!
  {% endif %}

=cut

sub last {
    my ($x, $y) = @_;
    my $ref = ref $x;
    return substr $x, -1 if !$ref;
    return @{$x}[-1] if $ref eq 'ARRAY';
}

=head2 C<lstrip>

Removes all whitespace (tabs, spaces, and newlines) from the left side of a
string. It does not affect spaces between words.

  {{ "          So much room for activities!          " | lstrip }}
    => So much room for activities!

=cut

sub lstrip {
    my ($x) = @_;
    $x =~ s[^\s*][];
    $x;
}

=head2 C<map>

Creates an array of values by extracting the values of a named property from
another object.

In this example, assume the object C<site.pages> contains all the metadata for
a website. Using assign with the map filter creates a variable that contains
only the values of the category properties of everything in the site.pages
object.

    {% assign all_categories = site.pages | map: "category" %}

    {% for item in all_categories %}
    - {{ item }}
    {% endfor %}

The output of this template would look like this:

    - business
    - celebrities
    - lifestyle
    - sports
    - technology

=cut

sub map {
    my ($list, $key) = @_;
    [map { $_->{$key} } @$list];
}

=head2 C<minus>

Subtracts a number from another number.

  {{ 4 | minus: 2 }} => 2

  {{ 16 | minus: 4 }} => 12

  {{ 183.357 | minus: 12 }} => 171.357

=cut

sub minus {
    my ($x, $y) = @_;
    $x ||= 0;
    return $x =~ m[^[\+-]?(\d*\.)?\d+?$]o &&
        $y =~ m[^[\+-]?(\d*\.)?\d+?$]o ? $x - $y : ();
}

=head2 C<modulo>

Returns the remainder of a division operation.

  {{ 3 | modulo: 2 }} => 1

  {{ 24 | modulo: 7 }} => 3

  {{ 183.357 | modulo: 12 }} => 3.357

=cut

sub modulo {
    my ($x, $y) = @_;
    require POSIX;
    POSIX::fmod($x, $y);
}

=head2 C<newline_to_br>

Replaces each newline (C<\n>) with html break (C<< <br />\n >>).

  {% capture string_with_newlines %}
  Hello
  there
  {% endcapture %}

  {{ string_with_newlines | newline_to_br }}

...becomes...

  <br />
  Hello<br />
  there<br />

=cut

sub newline_to_br { my ($x, $y) = @_; $x =~ s[\n][<br />\n]go; return $x; }

=head2 C<plus>

Adds a number to another number.

  {{ 154    | plus:1183 }}  => 1337
  {{ 4 | plus: 2 }} => 6
  {{ 16 | plus: 4 }} => 20
  {{ 183.357 | plus: 12 }} => 195.357

  {{ 'What' | plus:'Uhu' }} => WhatUhu

=head3 MATHFAIL!

Please note that integer behavior differs with Perl vs. Ruby so...

  {{ '1' | plus: '1' }}

...becomes C<11> in Ruby but C<2> in Perl.

=cut

sub plus {
    my ($x, $y) = @_;
    $x ||= 0;
    return $x =~ m[^[\+-]?(\d*\.)?\d+?$]o &&
        $y =~ m[^[\+-]?(\d*\.)?\d+?$]o ? $x + $y : $x . $y;
}

=head2 C<prepend>

Adds the specified string to the beginning of another string.

  {{ 'bar' | prepend:'foo' }} => 'foobar'

  {{ "apples, oranges, and bananas" | prepend: "Some fruit: " }}
    => Some fruit: apples, oranges, and bananas

  {% assign url = "example.com" %}
  {{ "/index.html" | prepend: url }} => example.com/index.html

=cut

sub prepend { my ($x, $y) = @_; return (defined $y ? $y : '') . $x; }

=head2 C<remove>

Removes every occurrence of the specified substring from a string.

  {{ 'foobarfoobar' | remove:'foo' }} => 'barbar'

  {{ "I strained to see the train through the rain" | remove: "rain" }}
    => I sted to see the t through the

=cut

sub remove { my ($x, $y) = @_; $x =~ s{$y}{}g; return $x }

=head2 C<remove_first>

Remove the first occurrence of a string.

  {{ 'barbar' | remove_first:'bar' }} => bar

  {{ "I strained to see the train through the rain" | remove_first: "rain" }}
    => I sted to see the train through the rain

=cut

sub remove_first { my ($x, $y) = @_; $x =~ s{$y}{}; return $x }

=head2 C<replace>

Replaces every occurrence of the first argument in a string with the second
argument.

The replacement value is optional and defaults to an empty string (C<''>).

  {{ 'foofoo'                 | replace:'foo','bar' }} => barbar
  {% assign this = 'that' %}
  {{ 'Replace that with this' | replace:this,'this' }} => Replace this with this
  {{ 'I have a listhp.'       | replace:'th' }}        => I have a lisp.
  {{ "Take my protein pills and put my helmet on" | replace: "my", "your" }}
    => Take your protein pills and put your helmet on

=cut

sub replace {
    my ($x, $y, $z) = @_;
    $z = defined $z ? $z : '';
    $x =~ s{$y}{$z}g if $y;
    return $x;
}

=head2 C<replace_first>

Replaces only the first occurrence of the first argument in a string with the
second argument.

The replacement value is optional and defaults to an empty string (C<''>).

  {{ 'barbar' | replace_first:'bar','foo' }} => 'foobar'

  {{ "Take my protein pills and put my helmet on" | replace_first: "my", "your" }}
    => Take your protein pills and put my helmet on

=cut

sub replace_first {
    my ($x, $y, $z) = @_;
    $z = defined $z ? $z : '';
    $x =~ s{$y}{$z};
    return $x;
}

=head2 C<reverse>

Reverses the order of the items in an array. C<reverse> cannot reverse a
string.

  {% assign my_array = "apples, oranges, peaches, plums" | split: ", " %}
  {{ my_array | reverse | join: ", " }} => plums, peaches, oranges, apples

Although C<reverse> cannot be used directly on a string, you can split a string
into an array, reverse the array, and rejoin it by chaining together filters:

  {{ "Ground control to Major Tom." | split: "" | reverse | join: "" }}
    => .moT rojaM ot lortnoc dnuorG

=cut

sub reverse {
    my ($args) = @_;
    [reverse @$args];
}

=head2 C<round>

Rounds a number to the nearest integer or, if a number is passed as an
argument, to that number of decimal places.

    {{ 4.6 | round }}        => 5
    {{ 4.3 | round }}        => 4
	{{ 1.2 | round }}        => 1
    {{ 2.7 | round }}        => 3
    {{ 4.5612 | round: 2 }}  => 4.56
	{{ 183.357 | round: 2 }} => 183.36

=cut

sub round {
    my ($x, $y) = @_;
    return if $x !~ m[^(\d*\.)?\d+?$]o;
    return sprintf '%.' . int($y || 0) . 'f', $x;
}

=head2 C<rstrip>

Removes all whitespace (tabs, spaces, and newlines) from the right side of a
string. It does not affect spaces between words.

  {{ "          So much room for activities!          " | rstrip }}
    =>          So much room for activities!

=cut

sub rstrip {
    my ($x) = @_;
    $x =~ s[\s*$][];
    $x;
}

=head2 C<size>

Returns the number of characters in a string, the number of items in an array,
or the number of keys in a hash reference. Undefined values return C<0>.

  # Where array is [1..6] and hash is { child => 'blarg'}
  {{ array     | size }} => 6
  {{ 'Testing' | size }} => 7
  {{ hash      | size }} => 1
  {{ undefined | size }} => 0
  {{ "Ground control to Major Tom." | size }} => 28

  {% assign my_array = "apples, oranges, peaches, plums" | split: ", " %}
  {{ my_array.size }} => 4

You can use C<size> with dot notation when you need to use the filter inside a
tag:

  {% if site.pages.size > 10 %}
    This is a big website!
  {% endif %}

=cut

sub size {
    my ($x, $y) = @_;
    return 0                 if !defined $x;
    return scalar @{$x}      if ref $x eq 'ARRAY';
    return scalar keys %{$x} if ref $x eq 'HASH';
    return length $x;
}

=head2 C<slice>

Returns a substring of 1 character beginning at the index specified by the
first argument. An optional second argument specifies the length of the
substring to be returned.

String indices are numbered starting from 0.

  {{ "Liquid" | slice: 0 }} => L
  {{ "Liquid" | slice: 2 }} => q
  {{ "Liquid" | slice: 2, 5 }} => quid

If the first argument is a negative number, the indices are counted from the
end of the string:

  {{ "Liquid" | slice: -3, 2 }} => ui

=cut

sub slice {
    my ($x, $pos, $len) = @_;
    $len = 1 unless defined $len;
    substr $x, $pos, $len;
}

=head2 C<sort>

Sorts items in an array in case-sensitive order.

  {% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}
  {{ my_array | sort | join: ", " }} => Sally Snake, giraffe, octopus, zebra

An optional argument specifies which property of the array's items to use for
sorting.

  {% assign products_by_price = collection.products | sort: "price" %}
  {% for product in products_by_price %}
    <h4>{{ product.title }}</h4>
  {% endfor %}

=cut

sub sort {
    my ($x, $y) = @_;
    return [sort { ($a =~ m[\D] || $b =~ m[\D]) ? $a cmp $b : $a <=> $b }
            @{$x}]
        if ref $x eq 'ARRAY';
    return
        sort { ($a =~ m[\D] || $b =~ m[\D]) ? $a cmp $b : $a <=> $b }
        keys %{$x}
        if ref $x eq 'HASH';
    return $x;
}

=head2 C<sort_natural>

Sorts items in an array in case-sensitive order.

  {% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}
  {{ my_array | sort_natural | join: ", " }}  => giraffe, octopus, Sally Snake, zebra

An optional argument specifies which property of the array's items to use for
sorting.

  {% assign products_by_company = collection.products | sort_natural: "company" %}
  {% for product in products_by_company %}
    <h4>{{ product.title }}</h4>
  {% endfor %}

=cut

sub sort_natural {
    my ($x, $y) = @_;
    return [
        sort {
            ($a->{$y} =~ m[\D] || $b->{$y} =~ m[\D])
                ? $a->{$y} cmp $b->{$y}
                : $a->{$y} <=> $b->{$y}
        } @{$x}
        ]
        if ref $x eq 'HASH' && defined $y;
    return [
        sort {
            ($a =~ m[\D] || $b =~ m[\D])
                ? lc $a cmp lc $b
                : $a <=> $b
        } @{$x}
        ]
        if ref $x eq 'ARRAY';
    return
        sort { ($a =~ m[\D] || $b =~ m[\D]) ? lc $a cmp lc $b : $a <=> $b }
        keys %{$x}
        if ref $x eq 'HASH';
    return $x;
}

=head2 C<split>

Divides a string into an array using the argument as a separator. C<split> is
commonly used to convert comma-separated items from a string to an array.

  {% assign beatles = "John, Paul, George, Ringo" | split: ", " %}
  {% for member in beatles %}
    {{ member }}
  {% endfor %}

...becomes...

  John
  Paul
  George
  Ringo

=cut

sub split {
    my ($x, $y) = @_;
    return [] if !defined $x;
    [split $y, $x];
}

=head2 C<strip>

Removes all whitespace (tabs, spaces, and newlines) from both the left and
right sides of a string. It does not affect spaces between words.

  |{{ "          So much room for activities!          " | strip }}|
    => |So much room for activities!|

=cut

sub strip {
    my ($x) = @_;
    $x =~ s[^\s+|\s+$][]g;
    $x;
}

=head2 C<strip_html>

Removes any HTML tags from a string.

  {{ '<div>Hello, <em id="whom">world!</em></div>' | strip_html }}  => Hello, world!
  '{{ '<IMG SRC = "foo.gif" ALT = "A > B">'        | strip_html }}' => ' B">'
  '{{ '<!-- <A comment> -->'                       | strip_html }}' => ' -->'
  {{ "Have <em>you</em> read <strong>Ulysses</strong>?" | strip_html }} => Have you read Ulysses?

Note that this filter uses C<s[<.*?>][]g> in emmulation of the Ruby Liquid
library's strip_html function. ...so don't email me if you (correcly) think
this is a braindead way of stripping html.

=cut

sub strip_html {
    my ($x, $y) = @_;
    $x =~ s[<.*?>][]go;
    $x =~ s[<!--.*?-->][]go;
    $x =~ s[<script.*?<\/script>][]go;
    return $x;
}

=head2 C<strip_newlines>

Removes any newline characters (line breaks) from a string.

{% capture string_with_newlines %} Hello there {% endcapture %}

{{ string_with_newlines | strip_newlines }} => Hellothere

=cut

sub strip_newlines { my ($x, $y) = @_; $x =~ s[\n][]go; return $x; }

=head2 C<times>

Simple multiplication or string repetion.

  {{ 'foo' | times: 4 }} => foofoofoofoo
  {{ 5 | times: 4 }} => 20
  {{ 3 | times: 2 }} => 6
  {{ 24 | times: 7 }} => 168
  {{ 183.357 | times: 12 }} => 2200.284

=cut

sub times {
    my ($x, $y) = @_;

    #warn sprintf '%s | %s', $x, $y;
    return unless $y;
    my $r;
    $r = $x if $y !~ m[^[\+-]?(\d*\.)?\d+?$]o;
    return $x x $y if $x !~ m[^[\+-]?(\d*\.)?\d+?$]o;
    $r = $x * $y unless defined $r;
    my ($_x) = $x =~ m[\.(\d+)$];
    my ($_y) = $y =~ m[\.(\d+)$];
    my ($_r) = $r =~ m[\.(\d+)$];
    $_x //= '';
    $_y //= '';
    $_r //= '';
    my $_lx = length $_x;
    my $_ly = length $_y;
    my $_lr = length $_r;
    (  ($_lx || $_ly || $_lr)
     ? (sprintf '%0.' . ([sort $_lx, $_ly, $_lr]->[-1]) . 'f', $r)
     : $r);
}

=head2 C<truncate>

Shortens a string down to the number of characters passed as an argument. If
the specified number of characters is less than the length of the string, an
ellipsis (...) is appended to the string and is included in the character
count.

  {{ "Ground control to Major Tom." | truncate: 20 }} => Ground control to...
  {{ 'Running the halls!!!' | truncate:19 }}          => Running the hall..
  {% assign blarg = 'STOP!' %}
  {{ 'Any Colour You Like' | truncate:10,blarg }}     => Any CSTOP!
  {{ 'Why are you running away?' | truncate:4,'?' }}  => Why?
  {{ 'Ha' | truncate:4 }}                             => Ha
  {{ 'Ha' | truncate:1,'Laugh' }}                     => Laugh
  {{ 'Ha' | truncate:1,'...' }}                       => ...

...and...

    {{ 'This is a long line of text to test the default values for truncate' | truncate }}

...becomes...

    This is a long line of text to test the default...

=head3 Custom ellipsis

C<truncate> takes an optional second argument that specifies the sequence of
characters to be appended to the truncated string. By default this is an
ellipsis (...), but you can specify a different sequence.

The length of the second argument counts against the number of characters
specified by the first argument. For example, if you want to truncate a string
to exactly 10 characters, and use a 3-character ellipsis, use B<13> for the
first argument of truncate, since the ellipsis counts as 3 characters.

  {{ "Ground control to Major Tom." | truncate: 25, ", and so on" }}
    => Ground control, and so on

=head3 No ellipsis

You can truncate to the exact number of characters specified by the first
argument and avoid showing trailing characters by passing a blank string as the
second argument:

  {{ "Ground control to Major Tom." | truncate: 20, "" }}
    => Ground control to Ma

=cut

sub truncate {
    my ($data, $length, $truncate_string) = @_;
    $length          = defined $length          ? $length          : 50;
    $truncate_string = defined $truncate_string ? $truncate_string : '...';
    return if !$data;
    my $l = $length - length($truncate_string);
    $l = 0 if $l < 0;
    return
        length($data) > $length
        ? substr($data, 0, $l) . $truncate_string
        : $data;
}

=head2 C<truncatewords>

Shortens a string down to the number of words passed as an argument. If the
specified number of words is less than the number of words in the string, an
ellipsis (...) is appended to the string.

  {{ "Ground control to Major Tom." | truncatewords: 3 }} => Ground control to...

=head3 Custom ellipsis

C<truncatewords> takes an optional second argument that specifies the sequence
of characters to be appended to the truncated string. By default this is an
ellipsis (...), but you can specify a different sequence.

  {{ "Ground control to Major Tom." | truncatewords: 3, "--" }} => Ground control to--

=head3 No ellipsis

You can avoid showing trailing characters by passing a blank string as the
second argument:

  {{ "Ground control to Major Tom." | truncatewords: 3, "" }} => Ground control to

=cut

sub truncatewords {
    my ($data, $words, $truncate_string) = @_;
    $words           = defined $words           ? $words           : 15;
    $truncate_string = defined $truncate_string ? $truncate_string : '...';
    return if !$data;
    my @wordlist = split ' ', $data;
    my $l        = $words - 1;
    $l = 0 if $l < 0;
    return $#wordlist > $l
        ? CORE::join(' ', @wordlist[0 .. $l]) . $truncate_string
        : $data;
}

=head2 C<uniq>

Removes any duplicate elements in an array.

  {% assign my_array = "ants, bugs, bees, bugs, ants" | split: ", " %}
  {{ my_array | uniq | join: ", " }} => ants, bugs, bees

=cut

sub uniq {
    my ($array) = @_;
    my @retval;
    for my $element (@$array) {
        push @retval, $element unless grep { $_ eq $element } @retval;
    }
    \@retval;
}

=head2 C<upcase>

Makes each character in a string uppercase. It has no effect on strings which
are already all uppercase.

  {{ "Parker Moore" | upcase }} => PARKER MOORE

  {{ "APPLE" | upcase }} => APPLE

=cut

sub upcase { my ($x) = @_; return uc $x }

=head2 C<url_decode>

Decodes a string that has been encoded as a URL or by C<url_encode>.

  {{ "%27Stop%21%27+said+Fred" | url_decode }} => 'Stop!' said Fred

=cut

sub url_decode {
    my ($x) = @_;
    $x =~ s[\+][ ]g;
    $x =~ s[%(\d+)][chr hex $1]gex;
    $x;
}

=head2 C<url_encode>

Converts any URL-unsafe characters in a string into percent-encoded characters.

  {{ "john@liquid.com" | url_encode }} => john%40liquid.com

  {{ "Tetsuro Takara" | url_encode }} => Tetsuro+Takara

  {{ "'Stop!'" said Fred" | url_encode }} => %27Stop%21%27+said+Fred

=cut

sub url_encode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-\.])/sprintf("%%%02X", ord($1))/seg;
    return $s;
}

=head2 C<where>

Creates an array including only the objects with a given property value, or any
truthy value by default.

In this example, assume you have a list of products and you want to show your
kitchen products separately. Using C<where>, you can create an array containing
only the products that have a C<"type"> of C<"kitchen">.

  All products:
  {% for product in products %}
  - {{ product.title }}
  {% endfor %}

  {% assign kitchen_products = products | where: "type", "kitchen" %}

  Kitchen products:
  {% for product in kitchen_products %}
  - {{ product.title }}
  {% endfor %}

...rendered with this data...

  products => [
        { title => 'Vacuum',       type => 'carpet', },
        { title => 'Spatula',      type => 'kitchen' },
        { title => 'Television',   type => 'den' },
        { title => 'Garlic press', type => 'kitchen' },
    ]

...becomes...

  All products:
  - Vacuum
  - Spatula
  - Television
  - Garlic press

  Kitchen products:
  - Spatula
  - Garlic press

Say instead you have a list of products and you only want to show those that
are available to buy. You can where with a property name but no target value to
include all products with a truthy "available" value.

  All products:
  {% for product in products %}
  - {{ product.title }}
  {% endfor %}

  {% assign available_products = products | where: "available" %}

  Available products:
  {% for product in available_products %}
  - {{ product.title }}
  {% endfor %}

...rendered with this data...

  products => [
        { title => 'Coffee mug',               available => 1},
        { title => 'Limited edition sneakers', available => 0},
        { title => 'Boring sneakers',          available => 1}
    ]

...becomes...

  All products:
  - Coffee mug
  - Limited edition sneakers
  - Boring sneakers

  Available products:
  - Coffee mug
  - Boring sneakers

The C<where> filter can also be used to find a single object in an array when
combined with the C<first> filter. For example, say you want to show off the
shirt in your new fall collection.

  {% assign new_shirt = products | where: "type", "shirt" | first %}

  Featured product: {{ new_shirt.title }}

...rendered with the following data...

  products => [
            { title => 'Limited edition sneakers',    type => 'shoes' },
            { title => 'Hawaiian print sweater vest', type => 'shirt' },
            { title => 'Tuxedo print tshirt',         type => 'shirt' },
            { title => 'Jorts',                       type => 'shorts' }
        ]

...becomes...

  Featured product: Hawaiian print sweater vest

=cut

sub where {
    my ($list, $key, $value) = @_;
    [grep { defined $value ? $_->{$key} eq $value : !!$_->{$key} } @$list];
}

=head2 C<money>

Formats floats and integers as if they were money.

    {{  4.6    | money }} => $4.60
    {{ -4.3    | money }} => -$4.30
    {{  4.5612 | money }} => $4.56

You may pass a currency symbol to override the default dollar sign (C<$>).

    {{  4.6    | money:'€' }} => €4.60

=cut

sub money {
    my ($x, $y) = @_;
    return if $x !~ m[^[\+-]?(\d*\.)?\d+?$]o;
    return (($x < 0 ? '-' : '') . (defined $y ? $y : '$') . sprintf '%.2f',
            CORE::abs($x));
}

=head2 C<stock_price>

Formats floats and integers as if they were stock prices.

    {{ 4.6    | stock_price }} => $4.60
    {{ 0.30   | stock_price }} => $0.3000
    {{ 4.5612 | stock_price }} => $4.56

You may pass a currency symbol to override the default dollar sign (C<$>).

    {{  4.6    | stock_price:'€' }} => €4.60

=cut

sub stock_price {
    my ($x, $y) = @_;
    return if $x !~ m[^[\+-]?(\d*\.)?\d+?$]o;
    return (($x < 0 ? '-' : '') . (defined $y ? $y : '$') .
                sprintf '%.' . (int(CORE::abs($x)) > 0 ? 2 : 4) . 'f',
            CORE::abs($x)
    );
}

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2020 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of L<The Artistic License
2.0|http://www.perlfoundation.org/artistic_license_2_0>. See the F<LICENSE>
file included with this distribution or L<notes on the Artistic License
2.0|http://www.perlfoundation.org/artistic_2_0_notes> for clarification.

When separated from the distribution, all original POD documentation is covered
by the L<Creative Commons Attribution-Share Alike 3.0
License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>. See the
L<clarification of the
CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
