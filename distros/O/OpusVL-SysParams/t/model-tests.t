use Test::Most;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::DBIx::Class {
    schema_class => 'OpusVL::SysParams::Schema',
}, 'SysInfo';
use OpusVL::SysParams;

SysInfo->set('test.param', 1);
is SysInfo->get('test.param'), 1;
my @keys = SysInfo->key_names;
eq_or_diff \@keys, [ 'test.param' ];

my $params = OpusVL::SysParams->new({ schema => SysInfo->result_source->schema });

is $params->get('test.param'), 1;

$params->set('test.array', [ 1, 2, 3 ]);
eq_or_diff $params->get('test.array'), [ 1, 2, 3 ];

@keys = $params->key_names;
eq_or_diff \@keys, [ 'test.array', 'test.param' ];

$params->del('test.param');
@keys = $params->key_names;
eq_or_diff \@keys, [ 'test.array' ];

subtest 'get_or_set' => sub {
    $params->set('test.already_got', 'hello');
    my @keys = $params->key_names;
    ok( ! defined($params->get('test.defaulted')), 'PRE: getting test.defaulted returns undef');
    is( $params->get('test.already_got'), 'hello', 'PRE: getting test.already_got returns "hello"');
    is(
        $params->get_or_set('test.already_got', sub { 'goodbye' }),
        'hello',
        'get_or_set an existing key returns the stored value'
    );

    is(
        $params->get_or_set('test.defaulted', sub { 'goodbye' }),
        'goodbye',
        'get_or_set on new key returns the default value "goodbye"'
    );

    is(
        $params->get('test.defaulted'),
        'goodbye',
        'get on that same new key should now returns "goodbye"'
    );
};

my $json = $params->get_json('test.array');
$params->set_json('test.array', $json);

$params->set_json("json.encoding","[1,2,3]");
is $params->get_json("json.encoding"), "[1,2,3]";
eq_or_diff $params->get('json.encoding'), [1,2,3];

subtest "data types" => sub {
    my $json_result = SysInfo->find({ name => 'json.encoding' });
    is $json_result->data_type, 'array', "JSON result was auto-set to array type";

    $params->set('text.textarea', "Short text", 'textarea');
    is SysInfo->find({ name => 'text.textarea'})->data_type, 'textarea', "Param was told it was a textarea";

    $params->set('json.encoding', $json_result->convert_to('textarea'), 'textarea');
    $json_result->discard_changes;
    is $json_result->data_type, 'textarea', "JSON setting was converted to textarea";
    is $params->get('json.encoding'), "1\n2\n3", "Setting was converted correctly";
};

my $setting = SysInfo->create({ name => 'old.setting', value => '"carpet"' });
is $params->get('old.setting'), "carpet", "Setting was retrieved correctly";
# NOTE: seems to return in array context, probably some TT oddity.
eq_or_diff [$setting->convert_to('textarea')], ["carpet"], "Setting was retrieved correctly";


done_testing;
