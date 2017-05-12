package Nephia::Setup::Plugin::Relax;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Setup::Plugin';
use Data::Section::Simple 'get_data_section';
use File::Spec;
use File::Basename 'dirname';

our $VERSION = "0.02";

sub bundle {
    qw/Assets::Bootstrap Assets::JQuery/;
}

sub fix_setup {
    my $self  = shift;

    my $chain = $self->setup->action_chain;
    $chain->{chain} = [];
    $chain->append('CreateApproot'     => $self->can('create_approot'));
    $chain->append('CreatePSGI'        => $self->can('create_psgi'));
    $chain->append('CreateConfig'      => $self->can('create_config'));
    $chain->append('CreateAppClass'    => $self->can('create_app_class'));
    $chain->append('CreateSomeClasses' => $self->can('create_some_classes'));
    $chain->append('CreateDBDir'       => $self->can('create_db_dir'));
    $chain->append('CreateTemplates'   => $self->can('create_templates'));
    $chain->append('CreateSQL'         => $self->can('create_sql'));
    $chain->append('CreateSetup'       => $self->can('create_setup'));
    $chain->append('CreateCPANFile'    => $self->can('create_cpanfile'));

    push @{$self->setup->deps->{requires}}, (
        'Plack::Middleware::Static'           => '0',
        'Plack::Middleware::Session'          => '0',
        'Plack::Middleware::CSRFBlock'        => '0',
        'Cache::Memcached::Fast'              => '0',
        'DBI'                                 => '0',
        'DBD::SQLite'                         => '0',
        'Data::Page::Navigation'              => '0',
        'Otogiri'                             => '0',
        'Nephia::Plugin::Dispatch'            => '0.03',
        'Nephia::Plugin::FillInForm'          => '0',
        'Nephia::Plugin::JSON'                => '0.03',
        'Nephia::Plugin::ResponseHandler'     => '0',
        'Nephia::Plugin::View::Xslate'        => '0',
        'Nephia::Plugin::ErrorPage'           => '0',
        'Nephia::Plugin::FormValidator::Lite' => '0',
        'Nephia'                              => '0.87',
    );
}

sub load_data {
    my ($class, $setup, @path) = @_;
    my $str = get_data_section(@path);
    $setup->process_template($str);
}

sub create_approot {
    my ($setup, $context) = @_;
    $setup->stop(sprintf('%s is Already exists', $setup->approot)) if -d $setup->approot;
    $setup->makepath('.');
}

sub create_psgi {
    my ($setup, $context) = @_;
    my $data = __PACKAGE__->load_data($setup, 'app.psgi');
    $setup->spew('app.psgi', $data);
}

sub create_config {
    my ($setup, $context) = @_;

    my $common = __PACKAGE__->load_data($setup, 'common.pl');
    $setup->spew('config', 'common.pl', $common);

    $setup->{dbfile} = File::Spec->catfile('var', 'db.sqlite3');
    my $data = __PACKAGE__->load_data($setup, 'config.pl');
    for my $env (qw/local dev real/) {
        $setup->spew('config', "$env.pl", $data);
    }
}

sub create_db_dir {
    my ($setup, $context) = @_;
    $setup->makepath('var');
}

sub create_app_class {
    my ($setup, $context) = @_;
    my $data = __PACKAGE__->load_data($setup, 'MyClass.pm');
    $setup->spew($setup->classfile, $data);
}

sub create_some_classes {
    my ($setup, $context) = @_; 
    for my $subclass ( qw/C::Root C::API::Member M M::DB M::DB::Member M::Cache/ ) {
        $setup->{tmpclass} = join('::', $setup->appname, $subclass);
        my $data = __PACKAGE__->load_data($setup, $subclass);
        $setup->spew('lib', split('::', $setup->{tmpclass}.'.pm'), $data);
    }
}

sub create_templates {
    my ($setup, $context) = @_;
    for my $template ( qw/index include::layout include::navbar error/ ) {
        my $file = File::Spec->catfile( split('::', $template) ). '.tt';
        my $data = __PACKAGE__->load_data($setup, $file);
        $setup->makepath('view', dirname($file));
        $setup->spew('view', $file, $data);
    }
}

sub create_sql {
    my ($setup, $context) = @_;
    for my $type ( qw/ mysql sqlite / ) {
        my $data = __PACKAGE__->load_data($setup, $type.'.sql');
        $setup->spew('sql', $type.'.sql', $data);
    }
}

sub create_setup {
    my ($setup, $context) = @_;
    my $data = __PACKAGE__->load_data($setup, 'setup.sh');
    $setup->spew('script', 'setup.sh', $data);
    chmod 0755, File::Spec->catfile($setup->approot, qw/script setup.sh/);
}

sub create_cpanfile {
    my ($setup, $context) = @_;
    $setup->spew('cpanfile', $setup->cpanfile);
}

1;
__DATA__

@@ app.psgi
use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'), 
);
use {{ $self->appname }};

use Plack::Builder;
use Plack::Session::Store::Cache;
use Cache::Memcached::Fast;

my $run_env       = $ENV{PLACK_ENV} eq 'development' ? 'local' : $ENV{PLACK_ENV};
my $basedir       = dirname(__FILE__);
my $config_file   = File::Spec->catfile($basedir, 'config', $run_env.'.pl');
my $config        = require($config_file);
my $cache         = Cache::Memcached::Fast->new($config->{'Cache'});
my $session_store = Plack::Session::Store::Cache->new(cache => $cache);
my $app           = {{ $self->appname }}->run(%$config);

builder {
    enable_if { $ENV{PLACK_ENV} =~ /^($:local|dev)$/ } 'StackTrace', force => 1;
    enable 'Static', (
        root => $basedir,
        path => qr{^/static/},
    );
    enable 'Session', (cache => $session_store);
    enable 'CSRFBlock';
    $app;
};

@@ common.pl
{
    appname => '{{ $self->appname }}',
    'Plugin::FormValidator::Lite' => {
        function_message => 'en',
        constants => [qw/Email/],
    },
    ErrorPage => {
        template => 'error.tt',
    },
};

@@ config.pl 
use File::Basename 'dirname';
use File::Spec;
my $common = require(File::Spec->catfile(dirname(__FILE__), 'common.pl'));
my $conf = {
    %$common,
    'Cache' => { 
        servers   => ['127.0.0.1:11211'],
        namespace => '{{ $self->appname }}',
    },
    'DBI' => {
        connect_info => [
            'dbi:SQLite:dbname={{ $self->{dbfile} }}', 
            '', 
            '',
        ],
    },
    
};
$conf;

@@ MyClass.pm
package {{ $self->appname }};
use strict;
use warnings;
use Data::Dumper ();
use URI;
use Nephia::Incognito;
use Nephia plugins => [
    'FillInForm',
    'FormValidator::Lite',
    'JSON' => {
        enable_api_status_header => 1,
    },
    'View::Xslate' => {
        syntax => 'TTerse',
        path   => [ qw/view/ ],
        function => {
            c    => \&c,
            dump => sub {
                local $Data::Dumper::Terse = 1;
                Data::Dumper::Dumper(shift);
            },
            uri_for => sub {
                my $path = shift;
                my $env = c()->req->env;
                my $uri = URI->new(sprintf(
                    '%s://%s%s',
                    $env->{'psgi.url_scheme'},
                    $env->{'HTTP_HOST'},
                    $path
                ));
                $uri->as_string;
            },
        },
    },
    'ErrorPage',
    'ResponseHandler',
    'Dispatch',
];

sub c () {Nephia::Incognito->unmask(__PACKAGE__)}

### To avoid to create duplicate cookies.
c->action_chain->delete('Nephia::Action::CookieImprinter');

app {
    get  '/' => Nephia->call('C::Root#index');
    get  '/api/member/create' => Nephia->call('C::API::Member#create');
    get  '/api/member/:id' => Nephia->call('C::API::Member#fetch');
};

1;

@@ C::Root
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use utf8;

sub index {
    my $c = shift;
    { template => 'index.tt' };
}

1;

@@ C::API::Member
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use utf8;
use {{ $self->appname }}::M::DB::Member;
use {{ $self->appname }}::M::Cache;

sub create {
    my $c = shift;
    my $valid = $c->form(
        name  => ['NOT_NULL', ['LENGTH', 1, 16]],
        email => ['NOT_NULL', 'EMAIL_LOOSE'],
    );

    return {status => 400, message => $valid->get_error_messages} if $valid->has_error;

    my $member = {{ $self->appname }}::M::DB::Member->create(
        name  => $c->param('name'),
        email => $c->param('email'),
    );
    return {member => $member};
}

sub fetch {
    my $c = shift;
    my $id = $c->path_param('id');

    return {status => 403, message => 'id is required'} unless $id;

    my $member = {{ $self->appname }}::M::Cache->get("member:$id") || {{ $self->appname }}::M::DB::Member->fetch($id);
    {{ $self->appname }}::M::Cache->set("member:$id", $member, 300) if $member;
    return $member ? {member => $member} : {status => 404, message => 'member not found'};
}

1;

@@ M
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use Nephia::Incognito;

sub c {
    my $class = shift;
    Nephia::Incognito->unmask('{{ $self->appname }}');
}

1;

@@ M::DB
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use parent '{{ $self->appname }}::M';
use Otogiri;
use Data::Page::Navigation;

my $db;

sub table {
    my $class = shift;
    die "do not call directly $class";
}

sub db {
    my $class = shift;
    my $config = $class->c->{config}{DBI};
    $db ||= Otogiri->new(%$config);
    unless($db->dbh->ping) {
        $db = Otogiri->new(%$config);
    }
    $db;
}

sub create {
    my ($class, %opts) = @_;
    $class->db->insert($class->table, {%opts});
}

sub update {
    my ($class, $set, $cond) = @_;
    $class->db->update($class->table, $set, $cond);
}

sub search {
    my ($class, $cond, $opts) = @_;
    $class->db->select($class->table, $cond, $opts);
}

sub search_with_pager {
    my ($class, $cond, $opts) = @_;
    my $items_per_page = delete $opts->{rows}  || 10;
    my $current_page   = delete $opts->{page}  || 1;
    my $pages_per_nav  = delete $opts->{pages} || 10;
    my ($total_query, @total_bind) = $class->db->maker->($class->table, ['COUNT(*) AS total'], $cond);
    my ($total) = $class->db->search_by_sql($total_query, [@total_bind], $class->table);
    my @rows = $class->search($class->table, $cond, $opts);
    my $pager = Data::Page->new(
        $total->{total},
        $items_per_page,
        $current_page
    );
    (\@rows, $pager);
}

sub single {
    my ($class, %cond) = @_;
    $class->db->single($class->table, {%cond});
}

sub delete {
    my ($class, %cond) = @_;
    $class->db->delete($class->table, {%cond});
}

sub txn {
    my $class = shift;
    $class->db->txn_scope;
}

sub last_insert_id {
    my ($class, $args) = @_;
    $class->db->last_insert_id($class);
}

1;

@@ M::DB::Member
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use parent '{{ $self->appname }}::M::DB';

sub table { 'member' }

sub create {
    my ($class, %opts) = @_;
    my $now = time();
    $opts{created_at} = $now;
    $opts{updated_at} = $now;
    $class->SUPER::create(%opts);
}

sub fetch {
    my ($class, $id) = @_;
    $class->single(id => $id);
}

1;

@@ M::Cache
package {{ $self->{tmpclass} }};
use strict;
use warnings;
use parent '{{ $self->appname }}::M';
use Cache::Memcached::Fast;

our $AUTOLOAD;

my $cache;

sub AUTOLOAD {
    my $class = shift;
    my ($method) = $AUTOLOAD =~ m/::([a-z_]+)$/;
    $class->cache->$method(@_);
}

sub cache {
    my $class = shift;
    my $config = $class->c->{config}{Cache};
    $cache ||= Cache::Memcached::Fast->new($config);
    $cache;
}

1;

@@ index.tt 
[% WRAPPER 'include/layout.tt' %]
<p>index</p>
[% END %]

@@ error.tt
[% WRAPPER 'include/layout.tt' WITH title = code _ ' ' _ message %]
  <div class="alert alert-block">
     <h2 class="alert-heading">[% code %]</h1>
     [% message %]
  </div>
[% END %]

@@ include/layout.tt
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>[% title || 'Top' %] | {{ $self->appname }}</title>
  <link rel="stylesheet" href="/static/bootstrap/css/bootstrap.min.css">
  <script src="/static/js/jquery.min.js"></script>
  <script src="/static/bootstrap/js/bootstrap.min.js"></script>
</head>
<body>
  <div class="navbar">
    <div class="navbar-inner">
      <div class="container">
      [% INCLUDE 'include/navbar.tt' %]
      </div>
    </div>
  </div>
  <div class="container">
  [% content %]
  </div>
</body>
</html>

@@ include/navbar.tt
<a class="brand" href="/">{{ $self->appname }}</a>
<ul class="nav">
  <li><a href="/">top</a></li>
</ul>

@@ sqlite.sql
CREATE TABLE member (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT,
    created_at INT,
    updated_at INT
);

@@ mysql.sql
CREATE TABLE member (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(140) NOT NULL,
    email VARCHAR(140) NOT NULL,
    created_at INT UNSIGNED NOT NULL,
    updated_at INT UNSIGNED NOT NULL,
    index (email)
) ENGINE=InnoDB, DEFAULT CHAR SET=utf8; 

@@ setup.sh
#!/bin/sh
carton install &&
sqlite3 ./var/db.sqlite3 < ./sql/create.sql &&
echo 'SETUP DONE.'

__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::Plugin::Relax - Xslate(TTerse) + Otogiri + alpha

=head1 SYNOPSIS

    $ nephia-setup Your::App --plugins Relax

=head1 DESCRIPTION

Relax style setup

=head1 BUNDLE SETUP-PLUGINS

L<Nephia::Setup::Plugin::Assets::Bootstrap>

L<Nephia::Setup::Plugin::Assets::JQuery>

=head1 ENABLED PLUGINS

L<Nephia::Plugin::JSON>

L<Nephia::Plugin::View::Xslate>

L<Nephia::Plugin::ResponseHandler>

L<Nephia::Plugin::Dispatch>

L<Nephia::Plugin::FillInForm>

L<Nephia::Plugin::ErrorPage>

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

