package PMCPAuth;
use 5.010;
use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

our @EXPORT = qw(auth_app token mcp_call $SECRET);

our $SECRET = 'k' x 32;
my $n = 0;

# An application with `host`, one tool reporting who called it, and %opts for
# the plugin. Returns a Punk::Test, or dies with what booting said.
sub auth_app {
    my ($opts, %o) = @_;
    my $pkg = 'PMCPAuth::A' . ++$n;
    my $host = exists $o{host} ? $o{host} : "host 'http://localhost';";
    eval qq{
        package ${pkg}::Controller::T;
        sub who {
            my (\$c) = \@_;
            my \$o = \$c->stash->{auth}{oauth};
            return { user => \$c->mcp_user, sub => (\$o ? \$o->{sub} : undef) };
        }
        sub me { 'principal-from-' . (\$_[0]->req->header('X-User') // 'nobody') }
        sub deny { my (\$c) = \@_; (\$c->req->header('X-Pass') // '') eq 'yes' ? undef : [401, ['Content-Type' => 'text/plain'], ['no pass']] }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        $host
        @{[ $o{pre} // "" ]}
        plugin 'MCP' => { session => 0, $opts };
        mcp tool => who => 'T#who';
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

# An HS256 access token for $SECRET, with %claims over the defaults.
sub token {
    my (%claims) = @_;
    require Crypt::JWS;
    require Crypt::JWS::Key;
    my $key = Crypt::JWS::Key->from_secret($SECRET);
    my %c = (iss => 'https://id.test', aud => 'http://localhost/mcp', sub => 'user-1',
             exp => time + 300, scope => 'mcp', %claims);
    delete $c{$_} for grep { !defined $c{$_} } keys %c;
    return Crypt::JWS::sign($key, JSON::PP->new->canonical->encode(\%c), alg => 'HS256');
}

# One tools/call of `who`. Returns the Punk::Test after the request.
sub mcp_call {
    my ($t, %h) = @_;
    $t->post_ok('/mcp', body => '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"who"}}',
                type => 'application/json',
                headers => { 'MCP-Protocol-Version' => '2025-11-25', %h });
    return $t;
}

1;
