use strict;
use warnings;
use FindBin;
use Path::Class;

use Test::More;
use Test::Fatal;

use Test::Apache::RewriteRules;

my $rewrite_conf = file("$FindBin::Bin/conf/rewrite.conf");
my $alias_conf   = file("$FindBin::Bin/conf/alias.conf");

if (!Test::Apache::RewriteRules->available) {
    plan skip_all => "Can't exec httpd";
}

subtest 'instantiate' => sub {
    my $rewrite = Test::Apache::RewriteRules->new(args => {});

    ok        $rewrite;
    isa_ok    $rewrite, 'Test::Apache::RewriteRules';
    is_deeply $rewrite, { backends => [], args => {} };
};

subtest 'add_backend' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test', port => 8080);

    is scalar(@{$rewrite->{backends}}), 1;
    is $rewrite->{backends}[0]{name}, 'test';
    is $rewrite->{backends}[0]{port}, 8080;

    ok     $rewrite->{backends}[0]{apache};
    isa_ok $rewrite->{backends}[0]{apache}, 'Test::Httpd::Apache2';
};

subtest 'proxy_port' => sub {
    my $rewrite    = Test::Apache::RewriteRules->new;
    my $proxy_port = $rewrite->proxy_port;

    ok        $proxy_port;
    like      $proxy_port, qr/\d+/;
    is_deeply $rewrite, {
        backends   => [],
        proxy_port => $proxy_port,
    };
};

subtest 'proxy_host' => sub {
    my $rewrite    = Test::Apache::RewriteRules->new;
    my $proxy_host = $rewrite->proxy_host;
    my $proxy_port = $rewrite->proxy_port;

    ok        $proxy_host;
    is        $proxy_host, "localhost:$proxy_port";
    is_deeply $rewrite, {
        backends   => [],
        proxy_port => $proxy_port,
    };
};

subtest 'proxy_http_url' => sub {
    my $rewrite        = Test::Apache::RewriteRules->new;
    my $proxy_http_url = $rewrite->proxy_http_url;
    my $proxy_host     = $rewrite->proxy_host;
    my $proxy_port     = $rewrite->proxy_port;

    ok        $proxy_http_url;
    is        $proxy_http_url, "http://$proxy_host/";
    is_deeply $rewrite, {
        backends   => [],
        proxy_port => $proxy_port,
    };

    $proxy_http_url = $rewrite->proxy_http_url('/foo/bar');

    is $proxy_http_url, "http://$proxy_host/foo/bar";
};

subtest 'backend_port' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test1', port => 8080);
       $rewrite->add_backend(name => 'test2');

    my $backend1_port = $rewrite->backend_port('test1');
    my $backend2_port = $rewrite->backend_port('test2');

    is   $backend1_port, 8080;
    like $backend1_port, qr/\d+/;
    like exception {$rewrite->backend_port('test3')}, qr/Can't find backend by name: test3/;
};

subtest 'backend_host' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test', port => 8080);
    my $backend_host = $rewrite->backend_host('test');
    my $backend_port = $rewrite->backend_port('test');

    is   $backend_host, "localhost:$backend_port";
};

subtest 'get_backend_name_by_port' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test', port => 8080);
    my $backend_name = $rewrite->get_backend_name_by_port(8080);

    is $backend_name, 'test';
    ok !$rewrite->get_backend_name_by_port(8081);
};

subtest 'rewrite_conf' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;

    ok    !$rewrite->rewrite_conf;
    is     $rewrite->rewrite_conf('apache.conf'), 'apache.conf';
    is     $rewrite->rewrite_conf, 'apache.conf';
    isa_ok $rewrite->rewrite_conf, 'Path::Class::File';
};

subtest 'rewrite_conf_f (for backward compatibility)' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;

    ok    !$rewrite->rewrite_conf_f;
    is     $rewrite->rewrite_conf_f('apache.conf'), 'apache.conf';
    is     $rewrite->rewrite_conf_f, 'apache.conf';
    isa_ok $rewrite->rewrite_conf_f, 'Path::Class::File';
};

subtest 'copy_config (just copying)' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
    my $new_conf = $rewrite->copy_config($rewrite_conf);

    isnt $new_conf->stringify, $rewrite_conf->stringify;
    is   scalar $new_conf->slurp, scalar $rewrite_conf->slurp;
};

subtest 'copy_config (simple filter)' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
    my $new_conf = $rewrite->copy_config($rewrite_conf, [
        RewriteRule => '# RewriteRule',
    ]);

    my $expected = $rewrite_conf->slurp;
       $expected =~ s/RewriteRule/# RewriteRule/g;

    is scalar $new_conf->slurp, $expected;
};

subtest 'copy_config (regexp)' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
    my $new_conf = $rewrite->copy_config($rewrite_conf, [
        qr/Backend(\w+)/ => sub { $1 },
    ]);

    my $expected = $rewrite_conf->slurp;
       $expected =~ s/BackendFoo/Foo/g;
       $expected =~ s/BackendBar/Bar/g;

    is scalar $new_conf->slurp, $expected;
};

subtest 'copy_conf_as_f (for backward compatibility)' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
    my $new_conf = $rewrite->copy_conf_as_f($rewrite_conf);

    isnt $new_conf->stringify, $rewrite_conf->stringify;
    is   scalar $new_conf->slurp, scalar $rewrite_conf->slurp;
};

subtest 'server_root' => sub {
    my $rewrite     = Test::Apache::RewriteRules->new;
    my $server_root = $rewrite->server_root;

    ok     $server_root;
    isa_ok $server_root, 'Path::Class::Dir';
    is     $server_root, $rewrite->apache->server_root;
};

subtest 'server_root_d (for backward compatibility)' => sub {
    my $rewrite     = Test::Apache::RewriteRules->new;
    my $server_root = $rewrite->server_root_d;

    ok     $server_root;
    isa_ok $server_root, 'Path::Class::Dir';
    is     $server_root, $rewrite->apache->server_root;
};

subtest 'proxy_document_root_d' => sub {
    my $rewrite     = Test::Apache::RewriteRules->new;
    my $server_root = $rewrite->proxy_document_root_d;

    ok     $server_root;
    isa_ok $server_root, 'Path::Class::Dir';
    is     $server_root, $rewrite->apache->server_root;
};

subtest 'receiver' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
    my $receiver = $rewrite->receiver;

    ok     $receiver;
    isa_ok $receiver, 'Path::Class::File';
    is     $receiver->slurp, <<'EOS';
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS;

print "Content-Type: application/json;\n\n";
print encode_json({
    host            => $ENV{HTTP_HOST},
    path            => $ENV{REQUEST_URI},
    path_translated => $ENV{PATH_TRANSLATED} . ($ENV{REQUEST_URI} =~ /\?/ ? "?$ENV{QUERY_STRING}" : '')
});
EOS
};

subtest 'custom_conf' => sub {
    my $rewrite  = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test1', port => 8080);
       $rewrite->add_backend(name => 'test2', port => 8081);
       $rewrite->rewrite_conf($rewrite_conf);

    is $rewrite->custom_conf, <<"EOS";
SetEnvIf Request_URI .* test1=localhost:8080
SetEnvIf Request_URI .* test2=localhost:8081
ServerName   proxy.test:@{[$rewrite->proxy_port]}
DocumentRoot @{[$rewrite->server_root]}

RewriteRule ^/url\\.cgi/ - [L]

Include "@{[$rewrite->rewrite_conf]}"

Action default-proxy-handler /@{[$rewrite->receiver->basename]} virtual
SetHandler default-proxy-handler

<Location /@{[$rewrite->receiver->basename]}>
  SetHandler cgi-script
</Location>
EOS
};

subtest 'apache' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'test1');
       $rewrite->add_backend(name => 'test2');
       $rewrite->rewrite_conf($rewrite_conf);

    ok     $rewrite->apache;
    isa_ok $rewrite->apache, 'Test::Httpd::Apache2';
    is     $rewrite->apache->tmpdir, $rewrite->apache->server_root;
    ok    !$rewrite->apache->auto_start;
    ok    !$rewrite->apache->pid;

    $rewrite->start_apache;

    ok $rewrite->apache->pid;
    ok $_->{apache}->pid for @{$rewrite->{backends}};

    $rewrite->stop_apache;

    ok !$rewrite->apache->pid;
    ok !$_->{apache}->pid for @{$rewrite->{backends}};
};

subtest 'create_backend_apache' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
    my $backend_apache  = $rewrite->create_backend_apache(
        name => 'test',
        port => 8080,
    );

    ok     $backend_apache;
    isa_ok $backend_apache, 'Test::Httpd::Apache2';
    is     $backend_apache->server_root, $rewrite->apache->server_root;
    ok    !$backend_apache->pid;
    is     $backend_apache->listen, 8080;
    is     $backend_apache->custom_conf, <<"EOS";
ServerName   test.test:8080
DocumentRoot @{[$backend_apache->server_root]}

AddHandler cgi-script .cgi
<Location @{[$backend_apache->server_root]}>
  Options +ExecCGI
</Location>

RewriteEngine on
RewriteRule /(.*) /@{[$rewrite->receiver->basename]}/\$1 [L]
EOS
};

subtest 'is_host_path' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo', port => 8080);
       $rewrite->add_backend(name => 'BackendBar', port => 8081);
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    # to backend
    $rewrite->is_host_path('/foo/abc'     => 'BackendFoo', '/abc');
    $rewrite->is_host_path('/foo/abc?xyz' => 'BackendFoo', '/abc?xyz');
    $rewrite->is_host_path('/bar/abc'     => 'BackendBar', '/abc');

    # proxy
    $rewrite->is_host_path('/baz/abc'      => '', $rewrite->server_root->file('/baz/abc')->stringify);
    $rewrite->is_host_path(q</baz/abc?foo> => '', $rewrite->server_root->file('/baz/abc?foo')->stringify);

    $rewrite->stop_apache;
};

subtest 'is_redirect' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_redirect('/hoge/abc?foo' => 'http://hoge.test/abc?foo');
    $rewrite->is_redirect('/hoge/301?foo' => 'http://hoge.test/301?foo', undef, code => 301);

    $rewrite->stop_apache;
};

subtest 'host_in_path' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->add_backend(name => 'BackendBar');
       $rewrite->rewrite_conf($rewrite_conf);
       $rewrite->start_apache;

    $rewrite->is_redirect('//abc:40/host/'     => 'http://hoge.test/host=abc:40');
    $rewrite->is_redirect('//abc.test/host/'   => 'http://hoge.test/host=abc.test');
    $rewrite->is_host_path('//abc:40/bhost/'   => 'BackendFoo', '/host=abc:40');
    $rewrite->is_host_path('//abc.test/bhost/' => 'BackendFoo', '/host=abc.test');

    $rewrite->stop_apache;
};

subtest 'alias' => sub {
    my $rewrite = Test::Apache::RewriteRules->new;
       $rewrite->add_backend(name => 'BackendFoo');
       $rewrite->rewrite_conf($alias_conf);
       $rewrite->start_apache;

    $rewrite->is_host_path('/foofoo' => 'BackendFoo', '/foofoo');
    $rewrite->is_host_path('/local/foofoo' => '', '/path/to/local/repository/foofoo');

    $rewrite->stop_apache;
};

done_testing;
