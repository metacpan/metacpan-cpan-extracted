#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Parameter serialization: `style` and `explode`.
#
# Neither was read at all before. The compiled parameter had no slot for
# either, so an array path parameter was handed `a,b` as one string and
# refused, a spaceDelimited or pipeDelimited query arrived as a single
# element, and an unknown style was silently ignored.
#
# Two cases here are not happy paths but the design itself, and they are the
# ones to keep if this file is ever trimmed:
#
#   * `a%2Cb` under a comma style must stay ONE element containing a comma.
#     Splitting is done on the RAW text and each piece decoded afterwards; if
#     that order is ever reversed, an escaped delimiter starts splitting the
#     value and the corruption is silent.
#   * a space is the exception to that rule. It can only reach a server
#     encoded, so for spaceDelimited both %20 and + ARE the delimiter. There
#     is no way to carry a literal space inside such a list, and the spec
#     provides none.
#
# Header and cookie values are split but deliberately NOT percent-decoded:
# they never were, and decoding them now would change what every existing
# document sees.

sub api_for {
    my (%o) = @_;
    my %p = (name => 'v', in => $o{in}, schema => $o{schema});
    $p{required} = 1           if $o{in} eq 'path';
    $p{style}    = $o{style}   if defined $o{style};
    $p{explode}  = $o{explode} if defined $o{explode};
    my $path = $o{in} eq 'path' ? '/t/{v}' : '/t';
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { $path => { get => {
            operationId => 'op',
            parameters  => [ \%p ],
            responses   => { 200 => { description => 'ok' } },
        } } },
    });
}

my $LIST   = { type => 'array',  items => { type => 'string' } };
my $STR    = { type => 'string' };
my $OBJECT = { type => 'object' };

# value of the declared parameter after validation, or undef if refused
sub got {
    my (%o) = @_;
    my $api = api_for(%o);
    my %args;
    if    ($o{in} eq 'path')   { $args{path}   = { v => $o{raw} } }
    elsif ($o{in} eq 'query')  { $args{query}  = $o{raw} }
    elsif ($o{in} eq 'header') { $args{header} = { v => $o{raw} } }
    else                       { $args{header} = { cookie => "v=$o{raw}" } }
    my ($ok, $res) = $api->validate_request(op => \%args);
    return (undef, $res) unless $ok;
    return ($res->{ $o{in} }{v}, $res->{ $o{in} });
}

# ---- path -------------------------------------------------------------------
{
    my ($v) = got(in=>'path', schema=>$LIST, style=>'simple', raw=>'a,b');
    is_deeply($v, ['a','b'], 'path simple: a list is comma separated');

    ($v) = got(in=>'path', schema=>$STR, style=>'simple', raw=>'5');
    is($v, '5', 'path simple: a scalar is unchanged');

    ($v) = got(in=>'path', schema=>$STR, raw=>'plain');
    is($v, 'plain', 'path with no style declared behaves as before');

    ($v) = got(in=>'path', schema=>$STR, style=>'simple', raw=>'a%2Cb');
    is($v, 'a,b', 'path: %2C decodes to a comma in a scalar');

    ($v) = got(in=>'path', schema=>$LIST, style=>'label', explode=>0, raw=>'.a,b');
    is_deeply($v, ['a','b'], 'path label, not exploded: .a,b');

    ($v) = got(in=>'path', schema=>$LIST, style=>'label', explode=>1, raw=>'.a.b');
    is_deeply($v, ['a','b'], 'path label, exploded: .a.b');

    ($v) = got(in=>'path', schema=>$STR, style=>'label', raw=>'.5');
    is($v, '5', 'path label: the marker is stripped from a scalar too');

    ($v) = got(in=>'path', schema=>$LIST, style=>'matrix', explode=>0, raw=>';v=a,b');
    is_deeply($v, ['a','b'], 'path matrix, not exploded: ;v=a,b');

    ($v) = got(in=>'path', schema=>$LIST, style=>'matrix', explode=>1, raw=>';v=a;v=b');
    is_deeply($v, ['a','b'], 'path matrix, exploded: ;v=a;v=b');

    ($v) = got(in=>'path', schema=>$STR, style=>'matrix', raw=>';v=5');
    is($v, '5', 'path matrix: the name and marker are stripped from a scalar');
}

# ---- header and cookie ------------------------------------------------------
{
    my ($v) = got(in=>'header', schema=>$LIST, style=>'simple', raw=>'a,b');
    is_deeply($v, ['a','b'], 'header simple: a list is comma separated');

    ($v) = got(in=>'header', schema=>$STR, raw=>'solo');
    is($v, 'solo', 'header scalar unchanged');

    ($v) = got(in=>'cookie', schema=>$LIST, style=>'form', explode=>0, raw=>'a,b');
    is_deeply($v, ['a','b'], 'cookie form: a list is comma separated');

    ($v) = got(in=>'cookie', schema=>$STR, raw=>'solo');
    is($v, 'solo', 'cookie scalar unchanged');
}

# ---- query ------------------------------------------------------------------
{
    my ($v) = got(in=>'query', schema=>$LIST, raw=>'v=a&v=b');
    is_deeply($v, ['a','b'],
              'query with no style: repeat keys still accumulate (the default)');

    ($v) = got(in=>'query', schema=>$LIST, style=>'form', explode=>1, raw=>'v=a&v=b');
    is_deeply($v, ['a','b'], 'query form exploded: repeat keys');

    ($v) = got(in=>'query', schema=>$LIST, style=>'form', explode=>0, raw=>'v=a,b');
    is_deeply($v, ['a','b'], 'query form not exploded: one comma separated value');

    ($v) = got(in=>'query', schema=>$LIST, style=>'form', explode=>0, raw=>'v=a%2Cb');
    is_deeply($v, ['a,b'],
              'an ESCAPED comma stays inside its element: raw split, decode after');

    ($v) = got(in=>'query', schema=>$LIST, style=>'spaceDelimited', explode=>0,
               raw=>'v=a%20b');
    is_deeply($v, ['a','b'], 'spaceDelimited: %20 is the delimiter');

    ($v) = got(in=>'query', schema=>$LIST, style=>'spaceDelimited', explode=>0,
               raw=>'v=a+b');
    is_deeply($v, ['a','b'], 'spaceDelimited: + is the delimiter too');

    ($v) = got(in=>'query', schema=>$LIST, style=>'pipeDelimited', explode=>0,
               raw=>'v=a|b');
    is_deeply($v, ['a','b'], 'pipeDelimited: a literal pipe');

    ($v) = got(in=>'query', schema=>$LIST, style=>'pipeDelimited', explode=>0,
               raw=>'v=a%7Cb');
    is_deeply($v, ['a','b'], 'pipeDelimited: an encoded pipe');

    ($v) = got(in=>'query', schema=>$STR, raw=>'v=hello%20world');
    is($v, 'hello world', 'a scalar query value is still decoded whole');
}

# ---- deepObject -------------------------------------------------------------
{
    my ($v) = got(in=>'query', schema=>$OBJECT, style=>'deepObject', explode=>1,
                  raw=>'v[a]=1&v[b]=2');
    is_deeply($v, { a => '1', b => '2' }, 'deepObject: members collect into a hash');

    ($v) = got(in=>'query', schema=>$OBJECT, style=>'deepObject', explode=>1,
               raw=>'v[a]=hello%20world');
    is_deeply($v, { a => 'hello world' }, 'deepObject: member values are decoded');

    # The negative that keeps the new lookup honest: a bracketed key must not
    # be swallowed when no deepObject parameter is declared.
    my (undef, $all) = got(in=>'query', schema=>$STR, raw=>'other[x]=1');
    is($all->{'other[x]'}, '1',
       'a bracketed key passes through when no deepObject parameter is declared');
}

# ---- form + explode on an object, and the ambiguity it carries --------------
#
# `R=100&G=200` spreads an object's members as top-level query keys, so nothing
# on the wire says which parameter they belong to - the declared property names
# are the only link. That collides when a member name is ALSO a parameter name,
# and the specification leaves it open. Resolved here in favour of the declared
# parameter: it is the one the document named explicitly.
{
    my $api = Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { get => {
            operationId => 'op',
            parameters  => [
                { name => 'color', in => 'query', style => 'form', explode => \1,
                  schema => { type => 'object',
                              properties => { R => { type => 'integer' },
                                              G => { type => 'integer' } } } },
                { name => 'R', in => 'query', schema => { type => 'string' } },
            ],
            responses => { 200 => { description => 'ok' } } } } } });

    my ($ok, $res) = $api->validate_request(op => { query => 'R=zzz&G=200' });
    ok($ok, 'a member name colliding with a parameter name still validates');
    is($res->{query}{R}, 'zzz',
       'the DECLARED parameter wins the colliding key');
    is_deeply($res->{query}{color}, { G => 200 },
       'and the object takes only the members nothing else claimed');
}

done_testing;
