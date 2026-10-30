#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use JSON::PP ();

BEGIN {
    plan skip_all => 'Punk-APIKey required'
        unless eval { require Punk::Plugin::APIKey; require Punk::Model::ApiKey; 1 };
    plan skip_all => 'DBD::SQLite required'
        unless eval { require DBI; require DBD::SQLite; 1 };
}
use Punk::Test;
use Punk::Plugin::MCP ();

# Punk-APIKey's guard as `auth`, over its own shipped table: any Punk guard
# works, and a key's owner becomes $c->mcp_user through `principal`.

my $db = File::Spec->catfile(File::Spec->tmpdir, "pmcp-apikey-$$.db");
unlink $db;
END { unlink $db if $db }
my $dsn = "dbi:SQLite:dbname=$db";
{
    (my $dir = $INC{'Punk/Plugin/APIKey.pm'}) =~ s/\.pm\z//;
    my $file = File::Spec->catfile($dir, 'sqitch', 'sqlite', 'deploy', 'api_keys.sql');
    plan skip_all => "no shipped schema at $file" unless -f $file;
    my $sql = do { open my $fh, '<', $file or die $!; local $/; <$fh> };
    $sql =~ s/^\s*(?:BEGIN|COMMIT)\s*;\s*$//gmi;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1, PrintError => 0 });
    $dbh->do($_) for grep { /\S/ } split /;\s*\n/, $sql;
    $dbh->disconnect;
}

eval qq{
    package T41::App::Controller::T;
    sub who { { owner => \$_[0]->mcp_user } }
    package T41::App;
    use Punk;
    use Punk::Plugin::APIKey;
    use Punk::Plugin::MCP;
    database dsn => '$dsn';
    model 'Punk::Model::ApiKey';
    plugin 'APIKey' => { model => 'Punk::Model::ApiKey', owner => 'owner_id',
                         kinds => { live => 'sk_live_' }, scopes => [qw(read mcp)] };
    plugin 'MCP' => { session => 0, auth => api_key_guard(scope => 'mcp'),
                      principal => sub { \$_[0]->api_key->{owner_id} } };
    mcp tool => who => 'T#who';
    1;
} or die $@;

my $t = Punk::Test->new('T41::App');
my ($mcp_key) = Punk::Plugin::APIKey->issue_for('T41::App', owner => 7, label => 'agent',
                                                scopes => ['mcp']);
my ($read_key) = Punk::Plugin::APIKey->issue_for('T41::App', owner => 8, label => 'reader',
                                                 scopes => ['read']);
my $call = sub {
    my ($key) = @_;
    $t->post_ok('/mcp', body => '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"who"}}',
                type => 'application/json',
                headers => { 'MCP-Protocol-Version' => '2025-11-25',
                             defined $key ? (Authorization => "Bearer $key") : () });
    return $t;
};

is($call->()->status, 401, 'no key: refused by Punk-APIKey');
is($call->('sk_live_nonsense')->status, 401, 'a bad key: refused');
isnt($call->($read_key)->status, 200, 'a key without the mcp scope: refused');
$call->($mcp_key);
is($t->status, 200, 'a key with the scope: let in');
is(JSON::PP->new->decode($t->body)->{result}{structuredContent}{owner}, 7,
    "and principal makes the key's owner \$c->mcp_user");

done_testing;
