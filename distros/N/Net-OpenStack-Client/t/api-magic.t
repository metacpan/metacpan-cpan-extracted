use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::MockModule;

use FindBin qw($Bin);
use lib "$Bin/testapi";

#use Net::OpenStack::Client::API::Theservice::v3DOT1;
#diag "API_DATA ", explain $Net::OpenStack::Client::API::Theservice::v3DOT1::API_DATA;

use JSON::XS;

use Net::OpenStack::Client::API::Magic qw(retrieve);

use Readonly;

=head2 cache

=cut

my $data = {
    name => 'end',
    service => 'something',
    more_data => {whatever => 1}
};

my $c;
$c = Net::OpenStack::Client::API::Magic::cache($data);
is_deeply($c, $data, "cache returns data");

=head2 retrieve

=cut

my $err;

($c, $err) = retrieve('theservice', 'humanreadable', 'v3.1');
is_deeply($c, {
    service => 'theservice',
    version => version->new('v3.1'),
    name => 'humanreadable',
    method => 'POST',
    endpoint => '/some/{user}/super',
    templates => [qw(user)],
    options => {
        'int' => {'type' => 'long','path' => ['something','int'], required => 1},
        'boolean' => {'path' => ['something','boolean'],'type' => 'boolean'},
        'name' => {'type' => 'string','path' => ['something','name']},
    },
    result => '/woo',
}, 'theservice humanreadable retrieved');
ok(! defined($err), "No error");
#diag "retrieve ", explain $c, " error ", explain $err;

my $c2;
($c2, $err) = retrieve('theservice', 'humanreadable', 'v3.1');
# This is an identical test, not only content
is($c2, $c, 'user_add retrieved 2nd time is same data/instance (from cache)');
ok(! defined($err), "No error 2nd time");

($c, $err) = retrieve('noservice', 'certainlynomethod', 'v1.2.3');
is_deeply($c, {}, 'unknown service retrieves undef');
like($err,
     qr{retrieve name certainlynomethod for service noservice version v1.2.3 failed: no API module Net::OpenStack::Client::API::Noservice::v1DOT2DOT3:},
     "retrieve of unknown service returns error message");

($c, $err) = retrieve('theservice', 'nomethod', 'v3.1');
is_deeply($c, {}, 'unknown name retrieves undef');
like($err,
   qr{retrieve name nomethod for service theservice version v3.1 failed: no API data or function from client module},
   "retrieve of unknown name returns error message");

($c, $err) = retrieve('theservice', 'avar', 'v3.1');
is_deeply($c, {}, 'client module name not a function retrieves undef');
like($err,
   qr{retrieve name avar for service theservice version v3.1 failed: found in client module, but not a function},
   "retrieve of client module name not a function returns error message");

($c, $err) = retrieve('theservice', 'custom_method', 'v3.1');
my $fn = delete $c->{code};
is(ref $fn, 'CODE', 'client module function as code ref');
is_deeply($c, {service => 'theservice', name => "custom_method"}, "client module function retirved without the code");
ok(!defined $err, "no error retrieved of client module function");

# first arg shold be instance, returns the remaining args in arrayref
my $res = $fn->("a", "b", "c");
is_deeply($res, [qw(b c)], "call to custom_method function works");

=head2 flush_cache

=cut

my $cache = Net::OpenStack::Client::API::Magic::flush_cache();
is_deeply($cache, {cmd=>{}, api => {}}, "returned cache has basic empty structure");

my $c3;
($c3, $err) = retrieve('theservice', 'humanreadable', 'v3.1');
# This is an identical test, not only content
isnt($c3, $c2, 'user_add retrieved 3rd time after cache flush is not same data/instance');
is_deeply($c3, $c2, 'user_add retrieved 3rd time after cache flush has same data');

=head2 mandatory services / methods

=cut

my $mandatory = {
    identity => { v3 => [qw(tokens)]},
};

foreach my $service (sort keys %$mandatory) {
    foreach my $version (sort keys %{$mandatory->{$service}}) {
        foreach my $method (@{$mandatory->{$service}->{$version}}) {
            ($c, $err) = retrieve($service, $method, $version);
            ok(!$err, "successfully retrieved mandatory service $service version $version method $method");
        }
    }
}



done_testing;
