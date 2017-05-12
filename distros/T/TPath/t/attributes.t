# checks whether attributes are working as expected

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 63;
use Test::Trap;
use Test::Exception;
use ToyXMLForester;
use ToyXML qw(parse);

my $f = ToyXMLForester->new;
my ( $p, $path, @c, $e );

$p    = parse(q{<a><b/><b foo="bar"/></a>});
$path = q{//b[@attr('foo')]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$path = q{//b[@:foo]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b><c/></b><b/></a>});
$path = q{//b[c]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b><c/><c/></b><b><c/></b><b/></a>});
$path = q{//b[c]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
$path = q{//b[@echo(c) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b foo="1"/><b foo="2"/><b foo="3"/></a>});
$path = q{//b[@log(@attr('foo'))]};
trap { @c = $f->path($path)->select($p) };
is @c, 3, "received expected from $p with $path";
is $trap->stderr, "1\n2\n3\n", 'received correct log messages';
$path = q{//b[@log(@:foo)]};
trap { @c = $f->path($path)->select($p) };
is @c, 3, "received expected from $p with $path";
is $trap->stderr, "1\n2\n3\n", 'received correct log messages';

my $message_log = '';
{

    package MyLog;
    use Moose;
    with 'TPath::LogStream';

    sub put {
        my ( $self, $msg ) = @_;
        $message_log .= "$msg\n";
    }
}
$f->log_stream( MyLog->new );
$f->path($path)->select($p);
is $message_log, "1\n2\n3\n", 'able to replace message log';
$f->log_stream( TPath::StderrLog->new );

$p    = parse(q{<a><b id="foo"><c/><c/><c/></b><b id="bar"><c/></b></a>});
$path = q{//b[@id = 'foo']/*};
@c    = $f->path($path)->select($p);
is @c, 3, "received expected from $p with $path";
$path = q{//b[@id = 'bar']/*};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse(q{<a><b id='foo'/></a>});
$path = q{//b[@log(@id = 'foo')]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "1\n",
  "attribute test evaluated as expected in $p with $path";

$p    = parse q{<a><b/><b foo='bar' /></a>};
$path = q{//b[@false]};
@c    = $f->path($path)->select($p);
is @c, 0, '@false attribute works';

$p    = parse q{<a><b/><b id='bar' /></a>};
$path = q{//b[@id = 'bar' and @index = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b id='bar' /><a/></a>};
$path = q{//a[@root]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@size(*) = 1]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@pick(*, 1) = '<c/>']};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0], '<b><c/><c/></b>', 'picked node stringifies correctly';

$p    = parse q{<a><b/><b><c/></b><b></b></a>};
$path = q{//b[@leaf]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><b/><b><c/></b><b><c/><c/></b></a>};
$path = q{//b[@pick(*, 1) == @null]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><b/><b id='bar' /></a>};
$path = q{//a[@this == @pick(/., 0)]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b foo='bar' /></a>};
$path = q{//b[@true]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";

$p    = parse q{<a><b/><c><d/><d id='foo'/></c></a>};
$path = q{//*[@id = 'foo'][@log(@uid)]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "/1/1\n", '@uid works as expected';

dies_ok { $f->path(q{a[@quux]}) } 'unknown attribute throws exception';

$p    = parse q{<a><b><c/><d/></b><b><e/><d/></b><b><c/><e/></b></a>};
$path = q{//b[child::*[1][@tag = 'e']]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path with double predicate";

$p    = parse q{<a><b/><b foo='bar'/></a>};
$path = q{//b[@\attr('foo')]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";

$p    = parse q{<a><b/><b foo='bar'/></a>};
$path = q{//*[@tsize = 1]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
is $c[0]->tag, 'b', 'first element has expected tag';

$p    = parse q{<a><b/><b foo='bar'/></a>};
$path = q{//*[@width = 2]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'a', 'first element has expected tag';

$p    = parse q{<a><b/><b foo='bar'/></a>};
$path = q{//*[@depth = 1]};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
is $c[0]->tag, 'b', 'first element has expected tag';

$p    = parse q{<a><b/><b foo='bar'/></a>};
$path = q{//*[@height = 2]};
@c    = $f->path($path)->select($p);
is @c, 1, "received expected from $p with $path";
is $c[0]->tag, 'a', 'first element has expected tag';

$p    = parse(q{<a><b/><b/><b/></a>});
$path = q{//a[@log(@card(b))]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "3\n",
  'received correct log message testing cardinality of a path';

$f->add_attribute( quux => sub { [ 1, 2, 3 ] } );
$path = q{//a[@log(@card(@quux))]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "3\n",
  'received correct log message testing cardinality of an attribute';

$path = q{//a[@log(@card(@null))]};
trap { $f->path($path)->select($p) };
is $trap->stderr, "0\n",
  'received correct log message testing cardinality of undef';

$p    = parse q{<a><b/><c/><d/><e/></a>};
$path = q{//@some(self::a, self::b)};
@c    = $f->path($path)->select($p);
is @c, 2, "received expected from $p with $path";
is $c[0]->tag, 'a', 'first element has expected tag';
is $c[1]->tag, 'b', 'second element has expected tag';

$path = q{//@some(1, 0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@some(1, 1, 0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@some(0, 0, 0)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//@all(1, 0)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//@all(1)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@all(1, 1, 1, 1)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@all(0, 0, 0, 1, 0)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//@one(1, 0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@one(1, 0, 0, 0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@one(1, 0, 0, 1)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//@none(1, 0)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//@none(0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@none(0, 0, 0, 0)};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//@none(0, 0, 0, 1)};
@c    = $f->path($path)->select($p);
is @c, 0, "received expected from $p with $path";

$path = q{//*[@tcount(1, 0) = 1]};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//*[@tcount(1, 1, 0) = 2]};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//*[@fcount(1, 0) = 1]};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$path = q{//*[@fcount(1, 0, 0) = 2]};
@c    = $f->path($path)->select($p);
is @c, 5, "received expected from $p with $path";

$p    = parse q{<a><b><c/><d/></b><b><e/><d/></b><b><c/><e/></b></a>};
$path = q{/*[@v('size', @tsize)]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{size}, 10, 'able to set @v variable';

$path = q{/*[@var('size', @tsize)]};
$e    = $f->path($path);
$e->select($p);
is $e->vars->{size}, 10, 'able to set @var variable';

$p            = parse q{<a><b><c/></b><d><e/><f/></d></a>};
$path         = q{/./*[* = @v('n')]};
$e            = $f->path($path);
$e->vars->{n} = 2;
@c            = $e->select($p);
is "$c[0]", q{<d><e/><f/></d>},
  'able to set @v and then use it in a variable test';

done_testing();
