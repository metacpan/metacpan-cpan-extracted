use strict;
use warnings;
use Test::More;
use Nephia::Core;
use t::Util 'mock_env';

my $env = mock_env;

my $app = sub {
    my ($self, $context) = @_;
    [200, ['Content-Type' => 'text/plain'], [sprintf('Hello, World! %s %s', ref($self), ref($context))]];
};

subtest normal => sub {
    my $v = Nephia::Core->new(app => $app);

    isa_ok $v, 'Nephia::Core';
    is $v->caller_class, __PACKAGE__;
    isa_ok $v->loaded_plugins, 'Nephia::Chain';
    isa_ok $v->action_chain, 'Nephia::Chain';
    isa_ok $v->filter_chain, 'Nephia::Chain';
    is $v->dsl, $v->{dsl};
    is_deeply [ map {ref($_)} $v->loaded_plugins->as_array ], [qw[Nephia::Plugin::Basic Nephia::Plugin::Cookie]], 'Basic and Cookie plugins loaded';
    is ref($v->loaded_plugins->fetch('Nephia::Plugin::Basic')), 'Nephia::Plugin::Basic', 'Fetch Basic plugin object';
    is $v->loaded_plugins->fetch('Nephia::Plugin::UnknownPlugin'), undef, 'Failed fetch (plugin does not exists)';
    is $v->app, $app;


    my $psgi = $v->run;
    isa_ok $psgi, 'CODE';

    $v->export_dsl;
    can_ok __PACKAGE__, qw/run app req param redirect/;

    isa_ok $v->run, 'CODE';
    my $res = $v->run->($env);
    isa_ok $res, 'ARRAY';
    is_deeply $res, [200, ['Content-Type' => 'text/plain'], ['Hello, World! Nephia::Core Nephia::Context']];
};

subtest caller_class => sub {
    my $v = Nephia::Core->new(app => $app, caller => 'MyApp');
    isa_ok $v, 'Nephia::Core';
    is $v->caller_class, 'MyApp';
};

subtest load_plugin => sub {
    {
        package Nephia::Plugin::Test;
        use parent 'Nephia::Plugin';
        sub new {
            my ($class, %opts) = @_;
            my $self = $class->SUPER::new(%opts);
            $self->app->filter_chain->append(slate => sub {
                my $content = shift;
                my $world = $opts{world};
                $content =~ s/World/$world/g;
                return $content;
            });
            return $self;
        };
    };

    my $v = Nephia::Core->new(plugins => [Test => {world => 'MyHome'}], app => $app);
    isa_ok $v, 'Nephia::Core';
    is_deeply [ map {ref($_)} $v->loaded_plugins->as_array ], [qw[Nephia::Plugin::Basic Nephia::Plugin::Cookie Nephia::Plugin::Test]], 'plugins';
};

subtest load_plugin_with_builder_chain => sub {
    {
        package Nephia::Plugin::Test2;
        use parent 'Nephia::Plugin';
        use Plack::Builder;
        sub new {
            my ($class, %opts) = @_;
            my $self = $class->SUPER::new(%opts);
            my $world = $opts{world};
            $self->app->builder_chain->append(Slate2 => sub {
                my ($self, $app) = @_;
                builder {
                    enable 'SimpleContentFilter', filter => sub { s/World/$world/ };
                    $app;
                };
            });
            return $self;
        };
    };

    my $v = Nephia::Core->new(plugins => [Test2 => {world => 'MyHome'}], app => $app);
    isa_ok $v, 'Nephia::Core';
    is_deeply [ map {ref($_)} $v->loaded_plugins->as_array ], [qw[Nephia::Plugin::Basic Nephia::Plugin::Cookie Nephia::Plugin::Test2]], 'plugins';
    my $res = $v->run->($env);
    is_deeply $res, [200, ['Content-Type' => 'text/plain'], ['Hello, MyHome! Nephia::Core Nephia::Context']];
};

subtest with_conf => sub {
    my $v = Nephia::Core->new(
        app => sub {
            my $c = shift;
            [200, ['Content-Type' => 'text/plain'], ['Nephia is '.$c->{config}{message}]];
        },
    );
    my $res = $v->run(message => 'so good!')->($env);
    is_deeply $res, [200, ['Content-Type' => 'text/plain'], ['Nephia is so good!']];
};

done_testing;
