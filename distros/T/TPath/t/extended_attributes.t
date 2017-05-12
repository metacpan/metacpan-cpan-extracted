# checks whether the extended attribute set works as expected

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 39;
use Test::Trap;
use List::MoreUtils qw(natatime);
use ToyXMLForester;
use ToyXML qw(parse);

# define a forester that can make use of these attributes
{

    package ExtendedForester;
    use Moose;
    extends 'ToyXMLForester';
    with 'TPath::Attributes::Extended';
}

my $f = ExtendedForester->new;

my $p     = parse '<foobar/>';
my $index = $f->index($p);
my $i     = natatime 2, grep /^.*[^#\s]/, <<'END' =~ /.*/mg;
//*[@s:matches(@tag, '^foo.*')] 
1

//*[@s:starts-with(@tag, 'foo')]
1

//*[@s:ends-with(@tag, 'bar')]
1

//*[@s:contains(@tag, 'ooba')] 
1
END
while ( my ( $path, $count ) = $i->() ) {
    my @c = $f->path($path)->select( $p, $index );
    is @c, $count, "received expected from $p with $path";
}

$i = natatime 2, grep /^.*[^#\s]/, <<'END' =~ /.*/mg;
//*[@log(@s:concat('a', 'b'))] 
ab

//*[@log(@s:concat('a', 'b', 'c'))]
abc

//*[@log(@s:index(@tag, 'b'))]
3

//*[@log(@m:max(3,2,1))]
3

//*[@log(@m:max(3.5,2,1))]
3.5

//*[@log(@m:min(3,2,1))]
1

//*[@log(@m:min(3,2,1.5))]
1.5

//*[@log(@m:sum(3,2,1.5))]
6.5

//*[@log(@m:prod(1,2,3))]
6

//*[@log(@s:replace-first('foo','o','e'))]
feo

//*[@log(@s:replace-all('foo','o','e'))]
fee

//*[@log(@s:replace('foo','o','e'))]
fee

//*[@log(@s:cmp('foo','o') < 0)]
1

//*[@log(@s:substr('foo',1))]
oo

//*[@log(@s:substr('foo',1,2))]
o

//*[@log(@s:len('foo'))]
3

//*[@log(@s:uc('foo'))]
FOO

//*[@log(@s:lc('FOO'))]
foo

//*[@log(@s:ucfirst('foo'))]
Foo

//*[@log(@s:trim(' foo '))]
foo

//*[@log(@s:nspace(' foo        bar '))]
foo bar

//*[@log(@s:join(',',1))]
1

//*[@log(@s:join(',', 1, 'foo'))]
1,foo

//*[@log(@s:join(@null, 1, 2))]
1null2

//*[@log(@m:abs(-1) = @m:abs(1))]
1

//*[@log(@m:ceil(1.5))]
2

//*[@log(@m:int(1.5))]
1

//*[@log(@m:int(-1.5))]
-1

//*[@log(@m:floor(-1.5))]
-2

//*[@log(@m:floor(1.5))]
1

//*[@log(@m:round(1.5))]
2

//*[@log(@s:looking-at(@tag, 'foo'))]
1

//*[@log(@s:find(@tag, 'ooba'))]
1
END
while ( my ( $path, $value ) = $i->() ) {
    trap { $f->path($path)->select( $p, $index ) };
    ( my $received = $trap->stderr ) =~ s/^\s++|\s++$//g;
    is $received, $value, "correct log output received from $p with $path";
}

my $path = q{//*[@log(@u:millis)]};
trap { $f->path($path)->select($p) };
ok $trap->stderr =~ /^\d++$/, '@u:millis gave some number of milliseconds';

$p    = parse q{<a><b/><b foo='bar' /></a>};
$path = q{//b[@u:def(@attr('foo'))]};
my @c = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

done_testing();
