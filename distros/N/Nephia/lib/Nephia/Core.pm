package Nephia::Core;
use strict;
use warnings;
use Nephia::Request;
use Nephia::Response;
use Nephia::Context;
use Nephia::Chain;
use Scalar::Util ();
use Module::Load ();

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ($class, $method) = $AUTOLOAD =~ /^(.+)::(.+?)$/;
    return if $method =~ /^[A-Z]/;
    $self->{dsl}{$method}->(@_);
}

sub new {
    my ($class, %opts) = @_;
    $opts{caller}       ||= caller();
    $opts{plugins}      ||= [];
    $opts{config}       ||= {};
    $opts{action_chain}   = Nephia::Chain->new(namespace => 'Nephia::Action');
    $opts{filter_chain}   = Nephia::Chain->new(namespace => 'Nephia::Filter');
    $opts{builder_chain}  = Nephia::Chain->new(namespace => 'Nephia::Builder');
    $opts{loaded_plugins} = Nephia::Chain->new(namespace => 'Nephia::Plugin', name_normalize => 0);
    $opts{dsl}            = {};
    $opts{external_classes} = {};
    my $self = bless {%opts}, $class;
    $self->action_chain->append(Core => $class->can('_action'));
    $self->_load_plugins;
    return $self;
}

sub export_dsl {
    my $self = shift; 
    my $dummy_context = Nephia::Context->new;
    $self->_load_dsl($dummy_context);
    my $class = $self->caller_class;
    no strict   qw/refs subs/;
    no warnings qw/redefine/;
    *{$class.'::run'} = sub (;%)  { my $subclass = shift; $self->run(@_) };
    *{$class.'::app'} = sub (&) {
        my $app = shift;
        $self->{app} = $app;
    };
}

sub _load_plugins {
    my $self = shift;
    my @plugins = (qw/Basic Cookie/, @{$self->{plugins}});
    while ($plugins[0]) {
        my $plugin_class = 'Nephia::Plugin::'. shift(@plugins);
        my $conf = {};
        if ($plugins[0]) {
            $conf = shift(@plugins) if ref($plugins[0]) eq 'HASH';
        }
        $self->loaded_plugins->append($self->_load_plugin($plugin_class, $conf));
    }
}

sub loaded_plugins {
    my $self = shift;
    return wantarray ? $self->{loaded_plugins}->as_array : $self->{loaded_plugins};
}

sub _load_plugin {
    my ($self, $plugin, $opts) = @_;
    $opts ||= {};
    Module::Load::load($plugin) unless $plugin->isa('Nephia::Plugin');
    my $obj = $plugin->new(app => $self, %$opts);
    return $obj;
}

sub app {
    my ($self, $code) = @_;
    $self->{app} = $code if defined $code;
    return $self->{app};
}

sub caller_class {
    my $self = shift;
    return $self->{caller};
}

sub action_chain {
    my $self = shift;
    return $self->{action_chain};
}

sub filter_chain {
    my $self = shift;
    return $self->{filter_chain};
}

sub builder_chain {
    my $self = shift;
    return $self->{builder_chain};
}

sub _action {
    my ($self, $context) = @_;
    $context->set(res => $self->app->($self, $context));
    return $context;
}

sub dsl {
    my ($self, $key) = @_;
    return $key ? $self->{dsl}{$key} : $self->{dsl};
}

sub call {
    my ($self, $codepath) = @_;
    my ($class, $method) = $codepath =~ /^(.+)\#(.+)$/;
    $class = sprintf('%s::%s', $self->caller_class, $class) unless $class =~ /^\+/;
    $class =~ s/^\+//;
    unless ($self->{external_classes}{$class}) {
        Module::Load::load($class) unless $class->isa($class);
        $self->{external_classes}{$class} = 1;
    }
    $class->can($method);
}

sub _load_dsl {
    my ($self, $context) = @_;
    my $class = $self->caller_class;
    no strict   qw/refs subs/;
    no warnings qw/redefine/;
    for my $plugin ( $self->loaded_plugins->as_array ) {
        for my $dsl ($plugin->exports) {
            *{$class.'::'.$dsl} = $plugin->$dsl($context);
            $self->{dsl}{$dsl} = $plugin->$dsl($context);
        }
    }
}

sub run {
    my ($self, %config) = @_;
    $self->{config} = { %{$self->{config}}, %config };
    my $class = $self->{caller};
    my $app = sub {
        my $env     = shift;
        my $req     = Nephia::Request->new($env);
        my $context = Nephia::Context->new(req => $req, config => $self->{config});
        $self->_load_dsl($context);
        my $res;
        for my $action ($self->{action_chain}->as_array) {
            ($context, $res) = $action->($self, $context);
            last if $res;
        }
        $res ||= $context->get('res');
        $res = Scalar::Util::blessed($res) ? $res : Nephia::Response->new(@$res);
        for my $filter ($self->{filter_chain}->as_array) {
            my $body = ref($res->body) eq 'ARRAY' ? $res->body->[0] : $res->body;
            $res->body($filter->($self, $body));
        }
        return $res->finalize;
    };
    for my $builder ($self->builder_chain->as_array) {
        $app = $builder->($self, $app);
    }
    return $app;
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Core - Core Class of Nephia

=head1 DESCRIPTION

Core Class of Nephia, Object Oriented Interface Included.

=head1 SYNOPSIS

    my $v = Nephia::Core->new( 
        appname => 'YourApp::Web',
        plugins => ['JSON', 'HashHandler' => { ... } ],
    );
    $v->app(sub {
        my $req = req();
        [200, [], 'Hello, World'];
    });
    $v->run;

=head1 ATTRIBUTES

=head2 appname

Your Application Name. Default is caller class.

=head2 plugins

Nephia plugins you want to load.

=head2 app

Application as coderef.

=head1 METHODS

=head2 action_chain

Returns a Nephia::Chain object for specifying order of actions.

=head2 filter_chain

Returns a Nephia::Chain object for specifying order of filters.

=head2 builder_chain

Returns a Nephia::Chain object for specifying order of builders.

=head2 caller_class

Returns caller class name as string.

=head2 app

Accessor method for application coderef (ignore plugins, actions, filters, and builders).

=head2 export_dsl

Export DSL (see dsl method) into caller namespace.

=head2 loaded_plugins

Returns objects of loaded plugins.

=head2 dsl

Returns pairs of name and coderef of DSL as hashref.

=head2 run

Returns an application as coderef (include plugins, actions, filters, and builders).

If you specify some arguments, these will be stored as config into context.

Look at following example. This psgi application returns 'Nephia is so good!'.

    my $v = Nephia::Core->new(
        app => sub {
            my $c = shift;
            [200, ['Content-Type' => 'text/plain'], ['Nephia is '.$c->{config}{message}]];
        },
    );
    $v->run(message => 'so good!');
    

=head1 HOOK MECHANISM

Nephia::Core includes hook mechanism itself. These provided as L<Nephia::Chain> object.

Nephia::Core has action_chain, filter_chain, and builder_chain. 

First, Look following ASCII Art Image.

This AA presents relation of builder chain and application.

          /----------------------------------------------\
          |                                              |
          |                           /---------------\  |
          |                           |               |  |
          |                           |   /~\   /~\   |  |
          |                           |   |B|   |B|   |  |
          |  +---------------+        |   |u|   |u|   |  |     |\   +----------+
          |  |               |        |   |i|   |i|   |  |     | \  |          |
          |  |            +---------------|l|---|l|------------+  \ |          |
          |  | $v->run;   | application   |d|   |d|                \|   PSGI   |
          |  |            |               |e|   |e|                 >          |
          |  |            +---------------|r|---|r|------------+   /|    App.  |
          |  |               |        |   | |   | |   |  |     |  / |          |
          |  +---------------+        |   |1|   |2|   |  |     | /  |          |
          |                           |   \_/   \_/   |  |     |/   +----------+
          |  $v                       |               |  |
          |  Nephia::Core obj.        | builder_chain |  |
          |                           \---------------/  |
          \----------------------------------------------/

When execute run method of Nephia::Core instance, run method returns PSGI Application (coderef).

Then, Builders in builder_chain modifies PSGI Application.

Okay. Look following ASCII Art Image. 

This AA presents relation of request, response, action chain, and filter chain.

    
        [HTTP Request]                              [HTTP Response]
           |                                                   A
   /-------|---------------------------------------------------|--------------\
   |       |       Your Application                            |              |
   |       |                                                   |              |
   |       v                                                   |              |
   |   /------------------------------------\    /---------------------\      |
   |   |                                    |    |                     |      |
   |   |           Nephia::Context          |--->|  Nephia::Response   |      |
   |   |                                    |    |                     |      |
   |   \------------------------------------/    \---------------------/      |
   |       |  A    |  A     |   A    |  A           |           A             |
   |       |  |    |  |     |   |    |  |        [Content]      |             |
   |   /---|--|----|--|-----|---|----|--|--\   /----|-----------|--------\    |
   |   |   |  |    |  |     |   |    |  |  |   |    |           |        |    |
   |   |   |  |    |  |     |   |    |  |  |   |    |           |        |    |
   |   |   v  |    v  |     v   |    v  |  |   |    v           |        |    |
   |   |  /~\ |   /~\ |   /~~~\ |   /~\ |  |   |   /~\    /~\   |        |    |
   |   |  |A| |   |A| |   | A | |   |A| |  |   |   |F|    |F|   |        |    |
   |   |  |c|-/   |c|-/   | p |-/   |c|-/  |   |   |i|--->|i|---+        |    |
   |   |  |t|     |t|     | p.|     |t|    |   |   |l|    |l|            |    |
   |   |  |i|     |i|     |   |     |i|    |   |   |t|    |t|            |    |
   |   |  |o|     |o|     \---/     |o|    |   |   |e|    |e|            |    |
   |   |  |n|     |n|               |n|    |   |   |r|    |r|            |    |
   |   |  | |     | |               | |    |   |   | |    | |            |    |
   |   |  |1|     |2|               |3|    |   |   |1|    |2|            |    |
   |   |  \_/     \_/               \_/    |   |   \_/    \_/            |    |
   |   |                                   |   |                         |    |
   |   | action_chain                      |   | filter_chain            |    |
   |   \-----------------------------------/   \-------------------------/    |
   \--------------------------------------------------------------------------/


Actions (and App) in action_chain affects context. Then, Nephia::Response object creates from context. 

Afterwords, filters in filter_chain affects content string in Nephia::Response.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<Nephia::Chain>

=cut
