use strict;
use warnings;

use JSON::XS;

use Test::More;
use Test::MockModule;

use Net::FreeIPA::API::Convert qw(process_args); # Test import

use Readonly;

Readonly my $DOMAINLEVEL_SET => '{"takes_args":[{"required":true,"autofill":false,"multivalue":false,"name":"ipadomainlevel","type":"int","class":"Int"}],"takes_options":[{"required":false,"autofill":false,"multivalue":false,"name":"version","type":"unicode","class":"Str"}],"name":"domainlevel_set"}';

=head2 convert

=cut

my $data = {
    int => 5,
    float => 10.5,
    str => 20,
    unicode => 21, # is an alias for a string, will be stringified
    bool_false => 0,
    bool_true => 1,
    bool_list => [1, 0, 1],
    bool_hash => { a=>1, b=>0, c=>1},
    not_a_type => {a => 1},
};

my $new_data = {};
foreach my $key (keys %$data) {
    my $type = $key;
    $type =~ s/_\w+$//;
    $new_data->{$key} = Net::FreeIPA::API::Convert::convert($data->{$key}, $type);
};

# Convert it in to non-pretty JSON string
my $j = JSON::XS->new();
$j->canonical(1); # sort the keys, to create reproducable results
is($j->encode($new_data),
   '{"bool_false":false,"bool_hash":{"a":true,"b":false,"c":true},"bool_list":[true,false,true],"bool_true":true,"float":10.5,"int":5,"not_a_type":{"a":1},"str":"20","unicode":"21"}',
   "JSON string of converted data");

my $value;
local $@;
eval {
    $value = Net::FreeIPA::API::Convert::convert('a', 'int');
};

like("$@", qr{^Argument "a" isn't numeric in addition}, "convert dies string->int");
ok(! defined($value), "value undefined on died convert string->int");

eval {
    $value = Net::FreeIPA::API::Convert::convert('a', 'float');
};

like("$@", qr{^Argument "a" isn't numeric in multiplication}, "convert dies string->float");
ok(! defined($value), "value undefined on died convert string->float");

=head2 check_command

=cut

sub ct
{
    my ($cmd, $value, $where, $iserr, $exp, $msg) = @_;
    my $orig;
    $orig = $j->encode($where) if ref($where);
    my $err = Net::FreeIPA::API::Convert::check_command($cmd, $value, $where);
    if ($iserr) {
        like($err, qr{$exp}, "error occurred $msg");
        is($j->encode($where), $orig, "where unmodified $msg") if ref($where);
    } else {
        is($j->encode($where), $exp, "where as expected $msg");
        ok(! defined($err), "no error $msg");
    }
}

ct({required => 1, autofill => 0, name => 'abc'}, undef, {},
   1, 'name abc mandatory with undefined value', 'missing mandatory value');
ct({required => 0, autofill => 0, name => 'abc'}, undef, {},
   0, '{}', 'missing non-required value');
ct({required => 1, autofill => 1, name => 'abc'}, undef, {},
   0, '{}', 'missing required autofilled value');

ct({required => 1, autofill => 1, name => 'abc'}, 1, '',
   1, 'name abc unknown where ref $', 'invalid where (only array and hash refs)');


ct({required => 1, autofill => 1, name => 'abc', multivalue => 1}, {}, {},
   1, 'name abc wrong multivalue \(multi 1, ref HASH\)', 'hashref value not valid multivalue=1');
ct({required => 1, autofill => 1, name => 'abc', multivalue => 0}, {}, {},
   1, 'name abc wrong multivalue \(multi 0, ref HASH\)', 'hashref value not valid multivalue=0');
ct({required => 1, autofill => 1, name => 'abc', multivalue => 1}, 1, {},
   1, 'name abc wrong multivalue \(multi 1, ref \)', 'scalar value not valid multivalue=1');
ct({required => 1, autofill => 1, name => 'abc', multivalue => 0}, [1], {},
   1, 'name abc wrong multivalue \(multi 0, ref ARRAY\)', 'list value not valid multivalue=0');

ct({required => 1, autofill => 1, name => 'abc', type => 'int', multivalue => 0}, 'a', [],
   1, 'name abc where ref ARRAY died Argument "a" isn\'t numeric in addition', 'conversion died string->int');


ct({required => 1, autofill => 1, name => 'abc', type => 'bool', multivalue => 0}, 1, [1],
   0, '[1,true]', 'added non-multi bool to where list multivalue=0');

ct({required => 1, autofill => 1, name => 'abc', type => 'bool', multivalue => 0}, 1, {xyz => 2},
   0, '{"abc":true,"xyz":2}', 'added non-multi bool to where hash multivalue=0');

ct({required => 1, autofill => 1, name => 'abc', type => 'bool', multivalue => 1}, [1,0], [1],
   0, '[1,[true,false]]', 'added non-multi bool to where list multivalue=1');

ct({required => 1, autofill => 1, name => 'abc', type => 'bool', multivalue => 1}, [1,0], {xyz => 2},
   0, '{"abc":[true,false],"xyz":2}', 'added non-multi bool to where hash multivalue=1');

=head2 process_args

=cut

sub pat
{
    my ($res, $msg, $err, $pos, $opts, $rpc, $jres) = @_;

    isa_ok($res, "Net::FreeIPA::Request", 'process_args returns Request instance');

    if($res) {
        ok(! $res->is_error(), "no error $msg");
        # Start with this before comparing individual values with is_deeply
        is($jres, $j->encode([$res->{args}, $res->{opts}]), "json/converted values $msg");

        is_deeply($res->{args}, $pos, "positional args $msg");
        is_deeply($res->{opts}, $opts, "options $msg");
        is_deeply($res->{rpc}, $rpc, "rpc options $msg");
    } else {
        like($res->{error}, qr{$err}, "error $msg");
    }
}

# Has mandatory posarg, non-mandatory option
my $cmds = $j->decode($DOMAINLEVEL_SET);
pat(process_args($cmds, undef),
    'missing mandatory pos argument',
    'domainlevel_set: 1-th argument name ipadomainlevel mandatory with undefined value');

pat(process_args($cmds, [1]),
    'pos arg check_command error propagated (no mulitvalue)',
    'domainlevel_set: 1-th argument name ipadomainlevel wrong multivalue');

# make version mandatory
$cmds->{takes_options}->[0]->{required} = 1;
pat(process_args($cmds, 1),
    'missing mandatory option',
    'domainlevel_set: option name version mandatory with undefined value');
$cmds->{takes_options}->[0]->{required} = 0;

pat(process_args($cmds, 1, version => [1]),
    'option check_command propagated (no multivalue)',
    'domainlevel_set: option name version wrong multivalue');

pat(process_args($cmds, 1, abc => 10),
    'invalid option',
    'domainlevel_set: option invalid name abc');

pat(process_args($cmds, 1, version => 2, __abc => 10),
    'process_args returns 4 element tuple (incl __ stripped rpc opt)',
    undef, [1], {version => 2}, {abc => 10}, '[[1],{"version":"2"}]');


done_testing();
