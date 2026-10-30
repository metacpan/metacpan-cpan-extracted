package PMCPOA;
use 5.010;
use strict;
use warnings;
use Exporter 'import';
use FindBin ();
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

our @EXPORT = qw(oa_app oa_call oa_list $SPEC);

our $SPEC = "$FindBin::Bin/data/books.json";
our %SEEN;     # what the handlers saw, by operationId
my $n = 0;

# The handlers: each records what reached it and answers.
our %H = (
    listBooks   => sub { my ($c) = @_;
        $SEEN{listBooks} = { q => $c->param('q'), limit => $c->param('limit'),
                             tags => $c->param('tags'), trace => $c->req->header('X-Trace'),
                             inner => $c->env->{'pmcp.inner'}, tool => $c->env->{'pmcp.tool'} };
        $c->json([{ title => 'Dune' }]) },
    createBook  => sub { my ($c) = @_; $c->json({ made => $c->openapi->{body}{title} }, 201) },
    getBook     => sub { my ($c) = @_; my $id = $c->param('id');
        $id eq 'later'   ? Punk::Future->done_future($c->json({ id => 'from a future' }))
      : $id eq 'missing' ? $c->json({ error => 'no such book' }, 404) : $c->json({ id => $id }) },
    replaceBook => sub { $_[0]->json({ replaced => $_[0]->param('id') }) },
    deleteBook  => sub { [204, [], []] },
    hiddenOp    => sub { $_[0]->text('hidden') },
    adminOp     => sub { $_[0]->json({ admin => 1, who => $_[0]->stash->{auth}{bearer} }) },
    'Get.Weird-Name' => sub { $_[0]->text('weird') },
    'dup.x'     => sub { $_[0]->text('one') },
    'dup_x'     => sub { $_[0]->text('two') },
);

# An application with the books spec mounted (under $o{under} if given), the
# plugin's %opts, and $decl after it. The mount is $PMCPOA::MOUNT, so the
# plugin options can name it. Returns a Punk::Test, or dies.
our $MOUNT;
sub oa_app {
    my ($opts, %o) = @_;
    my $pkg = 'PMCPOA::A' . ++$n;
    my $sec = $o{security} // 'sub { my ($cred) = @_; $cred eq "ok" ? { who => "ok" } : undef }';
    my $mount = $o{under}
        ? "my \$s = under '$o{under}' => sub { return }; \$PMCPOA::MOUNT = \$s->api(\$PMCPOA::SPEC => { handlers => \\%PMCPOA::H, security => { bearer => $sec } });"
        : "\$PMCPOA::MOUNT = api \$PMCPOA::SPEC => { handlers => \\%PMCPOA::H, security => { bearer => $sec } };";
    eval qq{
        package ${pkg}::Controller::T; sub a { 'dsl' }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        host 'http://localhost';
        $mount
        @{[ $o{pre} // '' ]}
        plugin 'MCP' => { session => 0, $opts };
        @{[ $o{decl} // '' ]}
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

sub _post {
    my ($t, $msg, %h) = @_;
    $t->post_ok('/mcp', body => JSON::PP->new->canonical->encode($msg), type => 'application/json',
                headers => { 'MCP-Protocol-Version' => '2025-11-25', %h });
    return JSON::PP->new->utf8->decode($t->body);
}
sub oa_call {
    my ($t, $name, $args, %h) = @_;
    return _post($t, { jsonrpc => '2.0', id => 1, method => 'tools/call',
                       params => { name => $name, arguments => $args // {} } }, %h);
}
sub oa_list {
    my ($t) = @_;
    return _post($t, { jsonrpc => '2.0', id => 1, method => 'tools/list' })->{result}{tools};
}

1;
