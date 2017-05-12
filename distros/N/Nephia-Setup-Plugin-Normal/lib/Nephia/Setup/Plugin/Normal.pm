package Nephia::Setup::Plugin::Normal;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Setup::Plugin::Minimal';
use File::Spec;

our $VERSION = "0.04";

sub bundle {
    qw/ Assets::Bootstrap Assets::JQuery /;
}

sub fix_setup {
    my $self = shift;
    my $chain = $self->setup->action_chain;
    $chain->delete('CreateClass');
    $chain->delete('CreatePSGI');
    $chain->after('CreateProject', CreateClass => \&create_class);
    $chain->after('CreateProject', CreatePSGI => \&create_psgi);
    $chain->append(CreateTemplate => \&create_template);

    push @{$self->setup->deps->{requires}}, (
        'Cache::Cache'                    => '0',
        'Plack::Middleware::CSRFBlock'    => '0',
        'IPC::ShareLite'                  => '0',
        'Nephia::Plugin::ResponseHandler' => '0',
    );
}

sub create_class {
    my ($setup, $context) = @_;
    my $data = $context->get('data_section')->(__PACKAGE__)->get_data_section('MyClass.pm');
    $setup->spew($setup->classfile, $setup->process_template($data));
    return $context;
}

sub create_psgi {
    my ($setup, $context) = @_;
    my $data = $context->get('data_section')->(__PACKAGE__)->get_data_section('app.psgi');
    $setup->spew('app.psgi', $setup->process_template($data));
    return $context;
}

sub create_template {
    my ($setup, $context) = @_;
    my $data = $context->get('data_section')->(__PACKAGE__)->get_data_section('index.html');
    $setup->spew('view', 'index.html', $setup->meta_tmpl->process($setup->process_template($data)));
}

1;

__DATA__

@@ MyClass.pm
package {{$self->appname}};
use strict;
use warnings;
use File::Spec;

our {{'$VERSION'}} = 0.01;

use Nephia plugins => [
    'JSON',
    'View::MicroTemplate' => {
        include_path => [File::Spec->catdir('view')],
    },
    'ResponseHandler',
    'Dispatch',
];

app {
    get '/' => sub {
        {template => 'index.html', appname => '{{$self->appname}}'};
    };

    get '/simple' => sub { 
        [200, [], 'Hello, World!']; 
    };

    get '/json' => sub { 
        {message => 'Hello, JSON World'};
    };
};

1;

:::encoding utf-8

:::head1 NAME

{{$self->appname}} - Web Application that powered by Nephia

:::head1 DESCRIPTION

An web application

:::head1 SYNOPSIS

    use {{$self->appname}};
    {{$self->appname}}->run;

:::head1 AUTHOR

clever people

:::head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

:::head1 SEE ALSO

L<Nephia>

:::cut

@@ app.psgi
use strict;
use warnings;
use Plack::Builder;
use Plack::Session::Store::Cache;
use Cache::SharedMemoryCache;
use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'), 
);
use {{$self->appname}};

my $app           = {{$self->appname}}->run;
my $root          = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__)));
my $session_cache = Cache::SharedMemoryCache->new({
    namespace          => '{{$self->appname}}',
    default_expires_in => 600,
});

builder {
    enable_if { $ENV{PLACK_ENV} =~ /^dev/ } 'StackTrace', force => 1;
    enable 'Static', (
        root => $root,
        path => qr{^/static/},
    );
    enable 'Session', (
        store => Plack::Session::Store::Cache->new(
            cache => $session_cache,
        ),
    );
    enable 'CSRFBlock';
    $app;
};

@@ index.html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>[= appname =] - powered by Nephia</title>
  <link rel="stylesheet" href="/static/bootstrap/css/bootstrap.min.css">
</head>
<body>
  <div class="navbar navbar-fixed-top">
    <div class="navbar-inner">
      <div class="container">
        <a class="brand" href="/">[= appname =]</a>
      </div>
    </div>
  </div>
  <div class="container">
    <div class="hero-unit">
      <h1>[= appname =]</h1>
      <p>An web-application that is empowered by Nephia</p>
    </div>
  </div>
  <script src="/static/js/jquery.min.js"></script>
  <script src="/static/bootstrap/js/bootstrap.min.js"></script>
</body>
</html>


__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::Plugin::Normal - Normal setup of Nephia

=head1 DESCRIPTION

Normal setup plugin.

=head1 SYNOPSIS

    $ nephia-setup YourApp --plugins Normal

=head1 BUNDLE SETUP-PLUGINS

=over 4

=item L<Nephia::Setup::Plugin::Assets::Bootstrap>

=item L<Nephia::Setup::Plugin::Assets::JQuery>

=back

=head1 ENABLED PLUGINS

=over 4

=item L<Nephia::Plugin::JSON>

=item L<Nephia::Plugin::View::MicroTemplate>

=item L<Nephia::Plugin::ResponseHandler>

=item L<Nephia::Plugin::Dispatch>

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

