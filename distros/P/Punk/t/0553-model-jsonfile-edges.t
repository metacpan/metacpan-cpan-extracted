#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Raw::JSON ();

# The JSON-file model's edges: numbers compared from strings and floats,
# keys given as strings with a sign, a float that is not a whole key, the
# filter refusals, a page asked of a keyless model, an update on a model
# with no primary key, a backend method on something else, a document that
# is a list rather than an object, a file that is not JSON, and a lock file
# that cannot be created.

BEGIN {
    plan skip_all => 'needs File::Raw::JSON with its C ABI'
        unless eval { require File::Raw::JSON; File::Raw::JSON->can('_abi_ptr') };
}

my $DIR = File::Temp->newdir;
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
my $FILE = "$DIR/data.json";
spew($FILE, File::Raw::JSON::file_json_encode({
    things => [ map { { id => $_, name => "n$_", n => $_ * 1.5 } } 1 .. 5 ],
    notes  => [ { body => 'a' }, { body => 'b' } ],
}));
{
    package JE;
    use Punk;
    database data => { backend => 'Punk::Model::JSONFile', file => $FILE };
    package JE::Model::Thing;
    use Punk::Model;
    database 'data';
    table 'things';
    field id   => { type => 'integer', primary => 1 };
    field name => { type => 'string' };
    field n    => { type => 'number' };
    package JE::Model::Note;
    use Punk::Model;
    database 'data';
    table 'notes';
    field body => { type => 'string' };
    package main;
}
JE->to_app;
my $M = JE->punk_app->model_instance('Thing');
my $N = JE->punk_app->model_instance('Note');
sub ids { [ map { $_->{id} } @{ $M->search(@_)->{rows} } ] }
sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

is_deeply(ids({ n => { '>' => '4.4' } }), [ 3, 4, 5 ], 'a number compared from a string');
is_deeply(ids({ n => { '<=' => 3.0 } }), [ 1, 2 ], 'and from a float');
is_deeply(ids({ id => { in => [ '2', 3.0, '+4', -1 ] } }), [ 2, 3, 4 ], 'keys given as strings, floats and with a sign');
is_deeply(ids({ id => 2.5 }), [], 'a float that is not a whole key matches no key');
is_deeply(ids({ id => { in => [ 'x', '', '1-2' ] } }), [], 'nor do strings that are not integers');
is_deeply(ids({ name => { like => 'n%' } }), [ 1 .. 5 ], 'like with a wildcard');
is_deeply(ids({ name => { starts_with => 'n1' } }), [ 1 ], 'starts_with');

refuses(qr/'>' on n needs a value, not undef/, 'an ordered comparison with undef', sub { $M->search({ n => { '>' => undef } }) });
refuses(qr/'>' on n takes a plain value, not a ARRAY/, 'and with a reference', sub { $M->search({ n => { '>' => [ 1 ] } }) });
refuses(qr/'in' on id takes an arrayref/, 'in without a list', sub { $M->search({ id => { in => 5 } }) });
refuses(qr/the filter on id is a plain arrayref - a list is spelled/, 'a bare list as a value', sub { $M->search({ id => [ 1 ] }) });
refuses(qr/pagination needs a primary key or an order_by/, 'a continued page of a keyless model', sub { $N->search({}, { after => 'x' }) });
refuses(qr/update needs a primary key/, 'an update on a keyless model', sub { $N->update({ body => 'c' }) });
refuses(qr/not a backend object/, 'a backend method on something else', sub { Punk::Model::JSONFile::file(bless(\(my $x = 1), 'Not::It')) });

{
    my $list = "$DIR/list.json";
    spew($list, '[1, 2, 3]');
    package JEList;
    use Punk;
    database data => { backend => 'Punk::Model::JSONFile', file => $list };
    package JEList::Model::Thing;
    use Punk::Model;
    database 'data';
    table 'things';
    field id => { type => 'integer', primary => 1 };
    package main;
    JEList->to_app;
    my $m = JEList->punk_app->model_instance('Thing');
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    is($m->count({}), 0, 'a document that is a list has no rows');
    like($warn[0] // '', qr/list\.json is unusable, so it has no rows: it is not a JSON object/, 'and says why');
}
{
    my $bad = "$DIR/bad.json";
    spew($bad, '{ not json');
    package JEBad;
    use Punk;
    database data => { backend => 'Punk::Model::JSONFile', file => $bad };
    package JEBad::Model::Thing;
    use Punk::Model;
    database 'data';
    table 'things';
    field id => { type => 'integer', primary => 1 };
    package main;
    JEBad->to_app;
    my $m = JEBad->punk_app->model_instance('Thing');
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    is($m->count({}), 0, 'a file that is not JSON has no rows');
    like($warn[0] // '', qr/bad\.json is unusable, so it has no rows: File::Raw::JSON/, 'and the decoder says why');
}
SKIP: {
    skip 'root can write anywhere', 1 if $> == 0;
    my $rodir = "$DIR/ro";
    mkdir $rodir or die;
    spew("$rodir/data.json", File::Raw::JSON::file_json_encode({ things => [] }));
    chmod 0555, $rodir;
    package JERo;
    use Punk;
    database data => { backend => 'Punk::Model::JSONFile', file => "$rodir/data.json" };
    package JERo::Model::Thing;
    use Punk::Model;
    database 'data';
    table 'things';
    field id => { type => 'integer', primary => 1 };
    package main;
    JERo->to_app;
    my $m = JERo->punk_app->model_instance('Thing');
    my $e = '';
    eval { $m->create({ id => 1 }); 1 } or $e = $@;
    like($e, qr/cannot open .*data\.json\.lock/, 'a lock file that cannot be created is refused by name');
    chmod 0755, $rodir;
}

done_testing;
