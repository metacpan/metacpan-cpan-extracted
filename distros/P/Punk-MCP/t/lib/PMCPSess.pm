package PMCPSess;
use 5.010;
use strict;
use warnings;
use JSON::PP ();
use File::Temp ();
use Exporter 'import';
use Punk::Test;
use Punk::Plugin::MCP ();

our @EXPORT = qw(sess_app send_msg init_session);

my $DIR = File::Temp::tempdir(CLEANUP => 1);
my $J = JSON::PP->new->canonical;
my $n = 0;
our $LAST;   # the class sess_app built last

# An application with a file store `mcp` and sessions on, unless $opts says
# otherwise. Returns a Punk::Test, or dies with what booting said.
sub sess_app {
    my ($opts, %o) = @_;
    my $pkg = 'PMCPSess::A' . ++$n;
    $LAST = $pkg;
    my $store = $o{store} // "cache mcp => { backend => 'file', dir => '$DIR/$n' };";
    eval qq{
        package ${pkg}::Controller::T;
        sub echo { my (\$c) = \@_; return { level => 'n/a', q => \$c->param('q') } }
        sub book { my (\$c) = \@_; return { id => \$c->param('id') } }
        sub secret { 's' }
        sub logs { my (\$c) = \@_; join ',', map { \$c->mcp_log(\$_, \$_) } qw(info error) }
        sub probe {
            my (\$c) = \@_;
            my \$own = \$c->mcp->session;
            my \$cancel = '{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":9}}';
            Punk::Plugin::MCP::_rpc(\$c, \$cancel, undef, \$c->param('other'));
            my \$after_other = \$c->mcp->cancelled;
            Punk::Plugin::MCP::_rpc(\$c, \$cancel, undef, \$own);
            return { session => \$own, after_other => \$after_other, after_own => \$c->mcp->cancelled };
        }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        $store
        plugin 'MCP' => { session => 'mcp', logging => 1, $opts };
        mcp tool => echo => 'T#echo';
        mcp tool => logs => { stream => 1 } => 'T#logs';
        mcp tool => probe => { stream => 1 } => 'T#probe';
        mcp resource => 'books://{id}' => 'T#book';
        mcp resource => 'books://catalog' => 'T#book';
        mcp resource => 'vault://secret' => { guard => sub { [403, [], ['no']] } } => 'T#secret';
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

# One message. %o: sid, version (the header; undef sends none), auth, accept,
# method for HTTP, env. Returns (status, decoded reply or undef, raw body).
sub send_msg {
    my ($t, $msg, %o) = @_;
    my %h = (Accept => $o{accept} // 'application/json, text/event-stream');
    $h{'Mcp-Session-Id'} = $o{sid} if defined $o{sid};
    $h{'MCP-Protocol-Version'} = $o{version} if defined $o{version};
    $h{Authorization} = $o{auth} if defined $o{auth};
    if (($o{http} // 'POST') eq 'DELETE') {
        $t->request_ok('DELETE', '/mcp', headers => \%h, env => $o{env} || {});
    }
    else {
        $t->post_ok('/mcp', body => ref $msg ? $J->encode($msg) : $msg,
                    type => 'application/json', headers => \%h, env => $o{env} || {});
    }
    my $b = $t->body;
    my $r;
    if (length $b && ($t->header('Content-Type') // '') eq 'application/json') {
        $r = JSON::PP->new->utf8->decode($b);
    }
    return ($t->status, $r, $b);
}

# initialize, and the session id it gave (or undef).
sub init_session {
    my ($t, %o) = @_;
    my ($s, $r) = send_msg($t, { jsonrpc => '2.0', id => 1, method => 'initialize',
        params => { protocolVersion => $o{proto} // '2025-11-25', capabilities => {},
                    clientInfo => { name => 'test', version => '1' } } }, %o);
    return ($t->header('Mcp-Session-Id'), $s, $r);
}

1;
