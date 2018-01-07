# Template for writing a new tests

use 5.006;
use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use Data::Printer;
$Data::Dumper::Maxdepth = 3;

use Moo::Google;

use Test::More;

my $default_file = $ENV{'GOOGLE_TOKENSFILE'} || 'gapi.conf';
my $user         = $ENV{'GMAIL_FOR_TESTING'} || 'pavel.p.serikov@gmail.com';
my $gapi = Moo::Google->new( debug => 0 );

if ( $gapi->auth_storage->file_exists($default_file) ) {
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user($user);

    my $acl_rule_id;
    my $inserted_acl_rule_id;

    # list of rules for primary calendar
    subtest 'Acl->list' => sub {
        my $t = $gapi->Calendar->Acl->list(
            { calendarId => 'primary', options => { maxResults => 2 } } )->json;
        ok( ref( $t->{items} ) eq 'ARRAY', "returned an ARRAY" );
        ok( scalar @{ $t->{items} } == 2,  "maxResults option is working" );
        ok( scalar @{ $t->{items} } > 0,
            "ARRAY isn't empty (Acl must have at least one owner)" );
        ok(
            $t->{items}[0]{kind} eq 'calendar#aclRule',
            "kind seems like OK - calendar#calendarListEntry"
        );
        $acl_rule_id =
          $t->{items}[0]{id};    # will be like 'user:pavel.p.serikov@gmail.com'
    };

    # warn $acl_rule_id;

    subtest 'Acl->get' => sub {
        my $t = $gapi->Calendar->Acl->get(
            { calendarId => 'primary', ruleId => $acl_rule_id } )->json;
        ok( ref($t) eq 'HASH', "returned single item" );
        ok(
            $t->{kind} eq 'calendar#aclRule',
            "kind seems like OK - calendar#aclRule"
        );
        ok( $t->{id} eq $acl_rule_id,
            "got Acl id with right id (previously listed first)" );
    };

    subtest 'Acl->insert' => sub {
        my $t = $gapi->Calendar->Acl->insert(
            {
                calendarId => 'primary',
                options    => {
                    role  => 'freeBusyReader',
                    scope => { type => 'user', value => 'pavesr@cpan.org' },
                }
            }
        )->json;
        ok( ref($t) eq 'HASH', "returned single item" );
        ok(
            $t->{kind} eq 'calendar#aclRule',
            "kind seems like OK - calendar#aclRule"
        );
        $inserted_acl_rule_id = $t->{id};

#ok($t->{id} eq $acl_rule_id, "got Acl id with right id (previously listed first)");
    };

    warn $inserted_acl_rule_id;

    subtest 'Acl->update' => sub {
        my $t = $gapi->Calendar->Acl->update(
            {
                calendarId => 'primary',
                ruleId     => $inserted_acl_rule_id,
                options    => {
                    role  => 'freeBusyReader',
                    scope => { type => 'user', value => 'serikov@it.rksi.ru' }
                }
            }
        )->json;
        warn Dumper $t;
        ok( ref($t) eq 'HASH', "returned single item" );
        ok(
            $t->{kind} eq 'calendar#aclRule',
            "kind seems like OK - calendar#aclRule"
        );

#ok($t->{id} eq $acl_rule_id, "got Acl id with right id (previously listed first)");
    };

# subtest 'Acl->update' => sub {
#   my $t = $gapi->Calendar->Acl->insert({
#     calendarId => 'primary',
#     options => {
#       role => 'freeBusyReader',
#       scope => { type => 'user', value => 'pavesr@cpan.org' },
#   }})->json;
#   ok(ref($t) eq 'HASH', "returned single item");
#   ok($t->{kind} eq 'calendar#aclRule', "kind seems like OK - calendar#aclRule");
#   #ok($t->{id} eq $acl_rule_id, "got Acl id with right id (previously listed first)");
# };

}
else {
    say 'Cant run test cause json file with tokens not exists!';
}

done_testing();
