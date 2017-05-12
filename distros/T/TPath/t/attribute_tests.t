# tests TPath::AttributeTest

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 45;
use Test::Trap;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);
use List::MoreUtils qw(natatime);

my $f = ToyXMLForester->new;

my $i = natatime 4, grep /\S/, <<'END' =~ /.*/mg;
<a><b/><b foo='bar'/></a>
//b[@attr('foo') = 'bar']
1
<b foo="bar"/>

<a><b/><b foo='bar'/></a>
//b['bar' = @attr('foo')] 
1
<b foo="bar"/>

<a><b/><b foo='bar'/></a>
//b[@attr('foo') < 'quux'] 
1
<b foo="bar"/>

<a><b/><b foo='bar'/></a>
//b['quux' > @attr('foo')] 
1
<b foo="bar"/>

<a><b/><b foo='1'/><b foo='2'/></a>
//b[@attr('foo') != '1'] 
1
<b foo="2"/>

<a><b/><b foo='1'/><b foo='2'/></a>
//b['1' != @attr('foo')] 
1
<b foo="2"/>

<a><e/><b><d/><c id='foo'/><d/></b><e/></a>
//*[not @id = 'foo'] 
6
<a><e/><b><d/><c id="foo"/><d/></b><e/></a><e/><b><d/><c id="foo"/><d/></b><d/><d/><e/>

<a><e/><b><d/><c id='foo'/><d/></b><e/></a>
//*[not (@id = 'foo')] 
6
<a><e/><b><d/><c id="foo"/><d/></b><e/></a><e/><b><d/><c id="foo"/><d/></b><d/><d/><e/>

<a><b><c/><c/><c/><c id="1"/></b><b><c id="2"/></b><b><c/><c id="3"/></b><b><c/><c/><c id="4"/></b></a>
//b[* > 1]
3
<b><c/><c/><c/><c id="1"/></b><b><c/><c id="3"/></b><b><c/><c/><c id="4"/></b>

<a><b><c/><c/><c/><c id="1"/></b><b><c id="2"/></b><b><c/><c id="3"/></b><b><c/><c/><c id="4"/></b></a>
//b[* % 2 = 1]
2
<b><c id="2"/></b><b><c/><c/><c id="4"/></b>

<a><b><c/><c/><c/><c id="1"/></b><b><c id="2"/></b><b><c/><c id="3"/></b><b><c/><c/><c id="4"/></b></a>
//b[* + 1 = 2]
1
<b><c id="2"/></b>
END

while ( my ( $xml, $path, $matches, $text ) = $i->() ) {
    my $p = parse $xml;
    my @c = $f->path($path)->select($p);
    is @c, $matches, "received expected number of nodes from $p with $path";
    is join( '', @c ), $text, "matches stringify as expected";
}

my $p     = parse '<a/>';
my $index = $f->index($p);
$i = natatime 2, grep /\S/, <<'END' =~ /.*/mg;
/*[@log(@true and @true)]
1

/*[@log(@true and @false)]
0

/*[@log(@false and @true)]
0

/*[@log(@false and @false)]
0

/*[@log(@true or @true)]
1

/*[@log(@true or @false)]
1

/*[@log(@false or @true)]
1

/*[@log(@false or @false)]
0

/*[@log(@true one @true)]
0

/*[@log(@true one @false)]
1

/*[@log(@false one @true)]
1

/*[@log(@false one @false)]
0

/*[@log(@false one @false one @true)]
1

/*[@log(@false;@false;@true)]
1

/*[@log(@false ; @false ; @true)]
1

/*[@log(not @true)]
0

/*[@log(not @false)]
1

/*[@log(@true and @false or @false)]
0

/*[@log(@false or @false one @true)]
1

/*[@log(@true and @false one @true)]
1

/*[@log(@true and @false one @false)]
0

/*[@log(@false and @true one @true)]
1

/*[@log(@false and (@true one @true))]
0
END

while ( my ( $path, $value ) = $i->() ) {
    trap { $f->path($path)->select( $p, $index ) };
    ( my $result = $trap->stderr ) =~ s/^\s++|\s++$//g;
    is $result, $value, "evaluated $path correctly";
}

done_testing();
