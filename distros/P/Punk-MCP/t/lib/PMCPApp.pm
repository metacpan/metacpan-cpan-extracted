package PMCPApp;
use 5.010;
use strict;
use warnings;
use JSON::PP ();
use Exporter 'import';
use Punk::Plugin::MCP ();
use Punk::Test;

our @EXPORT = qw(mcp_app call_tool list_tools rpc_msg list_all);

my $J = JSON::PP->new->canonical;
my $n = 0;

# An application from source, with `use Punk::Plugin::MCP`, a POST /rpc route
# that hands its body to the dispatcher with the request's context (until 07
# routes the endpoint), and whatever $body declares. Returns a Punk::Test.
sub mcp_app {
    my ($body, %o) = @_;
    my $pkg = $o{pkg} || ('PMCPApp::T' . ++$n);
    my $src = "package $pkg;\nuse Punk;\nuse Punk::Plugin::MCP;\n"
            . "post '/rpc' => sub { my (\$c) = \@_;\n"
            . ($o{pre} // '') . "\n"
            . "  my (\$s, \$b) = Punk::Plugin::MCP::_rpc(\$c, \$c->req->body,"
            . " \$c->req->header('X-Proto'));\n"
            . "  return [\$s, ['Content-Type' => 'application/json'],"
            . " [defined \$b ? \$b : '']] };\n"
            . "$body;\n1;\n";
    eval $src or die $@;
    return Punk::Test->new($pkg);
}

# One message; (status, decoded reply). $proto picks the protocol version.
sub rpc_msg {
    my ($t, $method, $params, $proto) = @_;
    $t->post_ok('/rpc', body => $J->encode({ jsonrpc => '2.0', id => 1,
                                             method => $method,
                                             (defined $params ? (params => $params) : ()) }),
                type => 'application/json',
                headers => { 'X-Proto' => $proto // '2025-11-25' });
    my $b = $t->body;
    return ($t->status, length $b ? JSON::PP->new->utf8->decode($b) : undef, $b);
}

sub call_tool {
    my ($t, $name, $args, $proto) = @_;
    return rpc_msg($t, 'tools/call',
                   { name => $name, (defined $args ? (arguments => $args) : ()) },
                   $proto);
}

sub list_tools {
    my ($t, $cursor, $proto) = @_;
    return rpc_msg($t, 'tools/list', (defined $cursor ? { cursor => $cursor } : {}),
                   $proto);
}

# Every item of a list method, following each cursor. (\@items, \@pages)
sub list_all {
    my ($t, $method, $key, $proto) = @_;
    my (@items, @pages, $cursor);
    for (1 .. 50) {
        my (undef, $r) = rpc_msg($t, $method, (defined $cursor ? { cursor => $cursor } : {}), $proto);
        my $page = $r->{result}{$key} or return ($r, []);
        push @pages, scalar @$page;
        push @items, @$page;
        $cursor = $r->{result}{nextCursor} or last;
    }
    return (\@items, \@pages);
}

1;
