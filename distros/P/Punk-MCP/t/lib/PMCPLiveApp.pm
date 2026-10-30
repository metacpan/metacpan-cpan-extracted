package PMCPLiveApp;
use 5.010;
use strict;
use warnings;
use Exporter 'import';
use File::Temp ();
use FindBin ();

our @EXPORT = qw(live_source);

# The live application's source, for PMCPSpawn: sessions in a file store, the
# MCP heartbeat shortened, the GET stream naming its worker, and tools that say
# which worker answered.
sub live_source {
    my (%o) = @_;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $spec = "$FindBin::Bin/data/books.json";
    my $max = $o{max_sessions} // 10000;
    my $extra = $o{plugin} // '';
    return <<"SRC";
use strict;
use warnings;
package LiveApp::Controller::T;
sub pid   { \$\$ }
sub touch { my (\$c) = \@_; \$c->mcp_resource_updated(\$c->param('uri') // 'books://1'); "touched \$\$" }
sub slow  { my (\$c) = \@_; \$c->mcp_progress(1, 2); \$c->timer(1.5)->then(sub { "slow done \$\$" }) }
sub book  { 'a book' }
sub hold  { select(undef, undef, undef, 1.5); \$\$ }
our %GOT;
sub selfprobe {
    my (\$c) = \@_;
    delete \$GOT{\$\$};
    \$c->publish('pmcp-selfprobe', "from \$\$");
    \$c->await(\$c->timer(0.5));
    return \$GOT{\$\$} ? 'self' : 'not self';
}
package LiveApp;
no warnings 'once';
use Punk;
use Punk::Plugin::MCP;
cache mcp => { backend => 'file', dir => '$dir' };
\$Punk::Plugin::MCP::HEARTBEAT = \$Punk::Plugin::MCP::HEARTBEAT = 0.3;
\$Punk::Plugin::MCP::_TEST_GET_HOOK = sub { my (\$c, \$s) = \@_; \$s->comment("worker \$\$") };
my %H = (getBook => sub { my (\$c) = \@_;
    \$c->timer(0.2)->then(sub { \$c->json({ id => \$c->param('id'), pid => \$\$ }) }) });
api '$spec' => { handlers => \\%H, stub => 1, security => { bearer => sub { { ok => 1 } } } };
__PACKAGE__->punk_app->subscribe('pmcp-selfprobe' => sub { \$LiveApp::Controller::T::GOT{\$\$}++ });
plugin 'MCP' => { session => 'mcp', logging => 1, max_sessions => $max,
                  openapi => '*', ops => ['getBook'], $extra };
mcp tool => \$_ => 'T#' . \$_ for qw(pid touch selfprobe hold);
mcp tool => slow => { stream => 1 } => 'T#slow';
mcp resource => 'books://{id}' => 'T#book';
SRC
}

1;
