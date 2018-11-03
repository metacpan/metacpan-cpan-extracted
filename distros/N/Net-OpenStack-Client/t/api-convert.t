use strict;
use warnings;

use JSON::XS;

use Test::More;
use Test::Warnings;
use Test::MockModule;

use Net::OpenStack::Client::API::Convert qw(process_args convert); # Test import

use Readonly;

=head2 convert

=cut

my $data = {
    long => 5,
    double => 10.5,
    string => 20,
    boolean_false => 0,
    boolean_true => 1,
    boolean_list => [1, 0, 1],
    boolean_hash => { a=>1, b=>0, c=>1},
    not_a_type => {a => 1},
};

my $new_data = {};
foreach my $key (keys %$data) {
    my $type = $key;
    $type =~ s/_\w+$//;
    $new_data->{$key} = convert($data->{$key}, $type);
};

# Convert it in to non-pretty JSON string
my $j = JSON::XS->new();
$j->canonical(1); # sort the keys, to create reproducable results
is($j->encode($new_data),
   '{"boolean_false":false,"boolean_hash":{"a":true,"b":false,"c":true},"boolean_list":[true,false,true],"boolean_true":true,"double":10.5,"long":5,"not_a_type":{"a":1},"string":"20"}',
   "JSON string of converted data");

my $value;
local $@;
eval {
    $value = convert('a', 'long');
};

like("$@", qr{^Argument "a" isn't numeric in addition}, "convert dies string->long");
ok(! defined($value), "value undefined on died convert string->long");

eval {
    $value = convert('a', 'double');
};

like("$@", qr{^Argument "a" isn't numeric in multiplication}, "convert dies string->double");
ok(! defined($value), "value undefined on died convert string->double");

=head2 check_command

=cut

sub ct
{
    my ($cmd, $value, $where, $iserr, $exp, $msg) = @_;
    my $orig;
    $orig = $j->encode($where) if ref($where);
    my $err = Net::OpenStack::Client::API::Convert::check_option($cmd, $value, $where);
    if ($iserr) {
        like($err, qr{$exp}, "error occurred $msg");
        is($j->encode($where), $orig, "where unmodified $msg") if ref($where);
    } else {
        is($j->encode($where), $exp, "where as expected $msg");
        ok(! defined($err), "no error $msg");
    }
}

ct({required => 1, name => 'abc'}, undef, {},
   1, 'name abc mandatory with undefined value', 'missing mandatory value');
ct({required => 0, name => 'abc'}, undef, {},
   0, '{}', 'missing non-required value');

ct({required => 1, name => 'abc'}, 1, '',
   1, 'name abc unknown where ref $', 'invalid where (only array and hash refs)');


ct({required => 1, name => 'abc', type => 'long'}, 'a', [],
   1, 'name abc where ref ARRAY died Argument "a" isn\'t numeric in addition', 'conversion died string->long');


ct({required => 1, name => 'abc', type => 'boolean'}, 1, [1],
   0, '[1,true]', 'added boolean to where list');

ct({required => 1, name => 'abc', type => 'boolean'}, 1, {xyz => 2},
   0, '{"abc":true,"xyz":2}', 'added bool to where hash');

=head2 process_args

=cut

sub pat
{
    my ($res, $msg, $err, $tpls, $params, $opts, $paths, $rest, $jres) = @_;

    isa_ok($res, "Net::OpenStack::Client::Request", 'process_args returns Request instance');

    if($res) {
        ok(! $res->is_error(), "no error $msg");
        # Start with this before comparing individual values with is_deeply
        is($jres, $j->encode([$res->{tpls}, $res->{params}, $res->{opts}]), "json/converted values $msg");

        is_deeply($res->{tpls}, $tpls, "templates $msg");
        is_deeply($res->{params}, $params, "parameters $msg");
        is_deeply($res->{opts}, $opts, "options $msg");
        is_deeply($res->{paths}, $paths, "paths $msg");
        is_deeply($res->{rest}, $rest, "rest options $msg");
    } else {
        $err = 'WILLNEVERMATCH' if ! defined($err);
        like($res->{error}, qr{$err}, "error $msg");
    }
}

# Has mandatory posarg, non-mandatory option
my $cmdhs = {
    method => 'POST',
    endpoint => '/do_{user}_something?domain=1',
    templates => [qw(user)],
    parameters => [qw(domain)],
    options => { test => {
        name => 'test',
        type => 'long',
        path => ['some', 'path'],
    }},
};

pat(process_args($cmdhs),
    'templates check_option error propagated (no templates for endpoint)',
    'endpoint template user name user mandatory with undefined value');

# make version mandatory
$cmdhs->{options}->{test}->{required} = 1;
pat(process_args($cmdhs, user => 'auser'),
    'missing mandatory option',
    'option test name test mandatory with undefined value');
$cmdhs->{options}->{test}->{required} = 0;

pat(process_args($cmdhs, user => 'auser', test => 'a', abc => 10),
    'invalid option value conversion',
    'option test name test where ref HASH died Argument.*numeric in addition');

pat(process_args($cmdhs, user => 'auser', test => 2, abc => 10),
    'invalid option',
    'option invalid name abc');

pat(process_args($cmdhs, user => 'auser', domain => 'adomain', test => 2, __abc => 10),
    'process_args returns 4 element tuple (incl __ stripped rest opt)',
    undef, {user => 'auser'}, {domain => 'adomain'}, {test => 2},
    {test => ['some', 'path']}, {abc => 10}, '[{"user":"auser"},{"domain":"adomain"},{"test":2}]');


done_testing();
