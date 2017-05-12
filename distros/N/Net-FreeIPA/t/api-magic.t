use strict;
use warnings;

use Test::More;
use Test::MockModule;

use JSON::XS;

use Net::FreeIPA::API::Magic qw(retrieve version);
use Types::Serialiser; # is used by JSON::XS

use Readonly;

Readonly my $TRUE => Types::Serialiser::true;
Readonly my $FALSE => Types::Serialiser::false;

# JSON command data

Readonly my $JDOMAINLEVEL_GET => '{"takes_args":[],"takes_options":[{"alwaysask":false,"attribute":false,"required":false,"csv":false,"deprecated_cli_aliases":[],"doc":"Client version. Used to determine if server will accept request.","autofill":false,"cli_name":"version","multivalue":false,"primary_key":false,"flags":["no_option","no_output"],"query":false,"name":"version","sortorder":2,"type":"unicode","class":"Str","label":"<version>","noextrawhitespace":true,"exclude":["webui"]}],"name":"domainlevel_get","doc":"Query current Domain Level.","NO_CLI":true}';

Readonly my $JDOMAINLEVEL_SET => '{"takes_args":[{"alwaysask":false,"attribute":false,"minvalue":0,"required":true,"csv":false,"deprecated_cli_aliases":[],"doc":"Domain Level","autofill":false,"cli_name":"level","multivalue":false,"primary_key":false,"flags":[],"query":false,"name":"ipadomainlevel","maxvalue":2147483647,"sortorder":2,"type":"int","class":"Int","label":"Domain Level"}],"takes_options":[{"alwaysask":false,"attribute":false,"required":false,"csv":false,"deprecated_cli_aliases":[],"doc":"Client version. Used to determine if server will accept request.","autofill":false,"cli_name":"version","multivalue":false,"primary_key":false,"flags":["no_option","no_output"],"query":false,"name":"version","sortorder":2,"type":"unicode","class":"Str","label":"<version>","noextrawhitespace":true,"exclude":["webui"]}],"name":"domainlevel_set","doc":"Change current Domain Level.","NO_CLI":true}';

Readonly my $JENV => '{"takes_args":["variables*"],"takes_options":[{"alwaysask":false,"attribute":false,"required":false,"csv":false,"deprecated_cli_aliases":[],"doc":"Forward to server instead of running locally","autofill":true,"cli_name":"server","truths":["1",1,"true","TRUE"],"multivalue":false,"primary_key":false,"flags":[],"query":false,"name":"server","default":false,"falsehoods":[0,"0","false","FALSE"],"sortorder":2,"type":"bool","class":"Flag","label":"<server>"},{"alwaysask":false,"attribute":false,"required":true,"csv":false,"deprecated_cli_aliases":[],"doc":"retrieve and print all attributes from the server. Affects command output.","autofill":true,"cli_name":"all","truths":["1",1,"true","TRUE"],"multivalue":false,"primary_key":false,"flags":["no_output"],"query":false,"name":"all","default":true,"falsehoods":[0,"0","false","FALSE"],"sortorder":2,"type":"bool","class":"Flag","label":"<all>","exclude":["webui"]},{"alwaysask":false,"attribute":false,"required":false,"csv":false,"deprecated_cli_aliases":[],"doc":"Client version. Used to determine if server will accept request.","autofill":false,"cli_name":"version","multivalue":false,"primary_key":false,"flags":["no_option","no_output"],"query":false,"name":"version","sortorder":2,"type":"unicode","class":"Str","label":"<version>","noextrawhitespace":true,"exclude":["webui"]}],"name":"env","doc":"Show environment variables.","NO_CLI":false}';

=head2 cache

=cut

my $c;
$c = Net::FreeIPA::API::Magic::cache(decode_json($JDOMAINLEVEL_GET));
is_deeply($c, {
    'name' => 'domainlevel_get',
    'takes_args' => [],
    'takes_options' => [
        {
            'autofill' => $FALSE,
            'class' => 'Str',
            'multivalue' => $FALSE,
            'name' => 'version',
            'required' => $FALSE,
            'type' => 'unicode'
        }
    ],
}, "cache returns filtered version of JSON metadata");


$c = Net::FreeIPA::API::Magic::cache(decode_json($JDOMAINLEVEL_SET));
is_deeply([sort keys %$c], [sort @Net::FreeIPA::API::Magic::CACHE_KEYS], "only CACHE_KEYS as keys");
is_deeply([sort keys %{$c->{takes_args}->[0]}], [sort @Net::FreeIPA::API::Magic::CACHE_TAKES_KEYS], "only CACHE_TAKES_KEYS as keys for takes_args");
is_deeply([sort keys %{$c->{takes_options}->[0]}], [sort @Net::FreeIPA::API::Magic::CACHE_TAKES_KEYS], "only CACHE_TAKES_KEYS as keys for takes_options");


$c = Net::FreeIPA::API::Magic::cache(decode_json($JENV));
is_deeply($c->{takes_args},[{
      'autofill' => $FALSE,
      'class' => 'unknown_class',
      'multivalue' => $FALSE,
      'name' => 'variables',
      'required' => $FALSE,
      'type' => 'unknown_type'
}], "Handle string value with defaults");

=head2 version

=cut

is(version(), $Net::FreeIPA::API::Data::VERSION, "version returns data version");

=head2 retrieve

=cut

my $err;

($c, $err) = retrieve('user_add');
is($c->{name}, 'user_add', 'user_add retrieved');
ok(! defined($err), "No error");

my $c2;
($c2, $err) = retrieve('user_add');
# This is an identical test, not only content
is($c2, $c, 'user_add retrieved 2nd time is same data/instance (from cache)');
ok(! defined($err), "No error 2nd time");

($c, $err) = retrieve('no_real_method');
is_deeply($c, {}, 'unknown method retrieves undef');
is($err, 'retrieve name no_real_method failed: no JSON data',
     "retrieve of unknown method returns error message");

=head2 flush_cache

=cut

my $cache = Net::FreeIPA::API::Magic::flush_cache();
is_deeply($cache, {}, "returned cache is emty");

my $c3;
($c3, $err) = retrieve('user_add');
# This is an identical test, not only content
isnt($c3, $c2, 'user_add retrieved 3rd time after cache flush is not same data/instance');
is_deeply($c3, $c2, 'user_add retrieved 3rd time after cache flush has same data');

=head2 all_command_names

=cut

is_deeply([Net::FreeIPA::API::Magic::all_command_names()],
          [sort keys %Net::FreeIPA::API::Data::API_DATA],
          "return sorted command_names");

done_testing;
