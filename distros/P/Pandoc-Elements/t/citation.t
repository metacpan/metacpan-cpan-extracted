use strict;
use Test::More 0.96; # 0.96 for subtests
use Pandoc::Elements;

use constant STRINGLIKE => 'Pandoc::Document::Citation::Test::Stringlike';

{
    package # no index
        Pandoc::Document::Citation::Test::Stringlike;
    use overload q[""] => sub {  ${$_[0]} }, fallback => 1;
    sub new {
        my($class, $value) = @_;
        return bless \$value => $class;
    }
}

my @accessors = (
    [ hash   => "citationHash" ],
    [ id     => "citationId" ],
    [ mode   => "citationMode" ],
    [ num    => "citationNoteNum" ],
    [ prefix => "citationPrefix" ],
    [ suffix => "citationSuffix" ],
);

my @methods = qw[ new TO_JSON ], map {; @$_ } @accessors;

my $c = citation { 
        id => 'foo', 
        prefix => [ Str "see" ], 
        suffix => [ Str "p.", Space, Str "42" ]
    };

isa_ok $c, 'Pandoc::Document::Citation';

can_ok $c, @methods;

is_deeply $c, {
   citationId => 'foo',
   citationHash => 1,
   citationMode => NormalCitation,
   citationNoteNum => 0,
   citationPrefix => [ Str "see" ],
   citationSuffix => [ Str "p.", Space, Str "42" ],
}, 'structure';

subtest accessors => sub {
    for my $aliases ( @accessors ) {
        my($name, $key) = @$aliases;
        is_deeply $c->$name, $c->{$key}, $name;
        is_deeply $c->$key, $c->{$key}, $key;
        is_deeply $c->$key, $c->$name, "$key/$name";
    }
};

subtest id => sub {
    my $bar = STRINGLIKE->new('bar');
    my $baz = STRINGLIKE->new('baz');
    isa_ok $bar, STRINGLIKE, 'test object';
    my $c = citation { id => $bar };
    is $c->id, 'bar', 'initial value';
    ok !ref($c->id), 'coercion through constructor';
    $c->id($baz);
    is $c->id, 'baz', 'changed value';
    ok !ref($c->id), 'coercion through setter';
};

my $doc = pandoc_json(<<'END_OF_JSON');
{"blocks":[{"t":"Para","c":[{"t":"Cite","c":[[{"citationSuffix":[],"citationNoteNum":0,"citationMode":{"t":"NormalCitation"},"citationPrefix":[],"citationId":"foo","citationHash":0}],[{"t":"Str","c":"[@foo]"}]]}]}],"pandoc-api-version":[1,17,5,1],"meta":{}}
END_OF_JSON

subtest 'blessed by document constructor' => sub {
    my $cites = $doc->query( Cite => sub { $_ } );
    isa_ok eval { $cites->[0]->citations->[0] }, 'Pandoc::Document::Citation';
};

done_testing;
