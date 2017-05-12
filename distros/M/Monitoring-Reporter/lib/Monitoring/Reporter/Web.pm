package Monitoring::Reporter::Web;
{
  $Monitoring::Reporter::Web::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Web::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a plack based webinterface to Monitoring::Reporter

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
use Try::Tiny;
use Module::Pluggable;
use Template;
use File::ShareDir;

use Plack::Request;

use Monitoring::Reporter;

# extends ...
# has ...
has '_key'  => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'lazy'  => 1,
    'builder' => '_init_key',
);

has '_fields' => (
    'is'      => 'rw',
    'isa'     => 'ArrayRef',
    'lazy'    => 1,
    'builder' => '_init_fields',
);

has '_finder' => (
    'is'       => 'rw',
    'isa'      => 'Module::Pluggable::Object',
    'lazy'     => 1,
    'builder'  => '_init_finder',
    'accessor' => 'finder',
);

has '_plugins' => (
    'is'       => 'rw',
    'isa'      => 'HashRef[Monitoring::Reporter::Web::Plugin]',
    'lazy'     => 1,
    'builder'  => '_init_plugins',
    'accessor' => 'plugins',
);

has '_tt' => (
    'is'      => 'ro',
    'isa'     => 'Template',
    'lazy'    => 1,
    'builder' => '_init_tt',
);

has 'mr' => (
    'is'            => 'rw',
    'isa'           => 'Monitoring::Reporter',
    'lazy'          => 1,
    'builder'       => '_init_zr',
);

# with ...
with qw(Config::Yak::LazyConfig Log::Tree::Logger);

sub _log_facility { return 'mreporter-web'; }
sub _config_locations { return [qw(conf /etc/mreporter)]; }

# initializers ...
sub _init_fields {
    return [qw(mode key)];
}

sub _init_key {
    my $self = shift;

    return $self->config()->get('Monitoring::Reporter::Key', { Default => '', }, );
}

sub _init_finder {
    my $self = shift;

    # The finder is the class that finds our available plugins
    my $Finder = Module::Pluggable::Object::->new( 'search_path' => 'Monitoring::Reporter::Web::Plugin' );

    return $Finder;
} ## end sub _init_finder

sub _init_zr {
    my $self = shift;

    my $ZR = Monitoring::Reporter::->new({
        'config'    => $self->config(),
        'logger'    => $self->logger(),
        'warn_unattended' => $self->config()->get('Monitoring::Reporter::WarnUnattended', { Default => 0, } ),
        'warn_unsupported' => $self->config()->get('Monitoring::Reporter::WarnUnsupported', { Default => 0, } ),
    });

    return $ZR;
}

sub _init_plugins {
    my $self = shift;

    my $plugin_ref = {};
  PLUGIN: foreach my $class_name ( $self->finder()->plugins() ) {
        ## no critic (ProhibitStringyEval)
        my $eval_status = eval "require $class_name;";
        ## use critic
        if ( !$eval_status ) {
            $self->logger()->log( message => 'Failed to require ' . $class_name . ': ' . $@, level => 'warning', );
            next;
        }
        my $arg_ref = $self->config()->get($class_name);
        $arg_ref->{'logger'} = $self->logger();
        $arg_ref->{'config'} = $self->config();
        $arg_ref->{'tt'}     = $self->_tt();
        $arg_ref->{'mr'}     = $self->mr();
        if ( $arg_ref->{'disabled'} ) {
            $self->logger()->log( message => 'Skipping disabled plugin: ' . $class_name, level => 'debug', );
            next PLUGIN;
        }
        try {
            my $Plugin = $class_name->new($arg_ref);

            my $alias = $Plugin->alias();
            if ( $alias && !exists( $plugin_ref->{$alias} ) ) {
                $plugin_ref->{$alias} = $Plugin;
                $self->logger()->log( message => 'Initialized Plugin: ' . $class_name . ' as ' . $alias, level => 'debug', );
                foreach my $field ( @{ $Plugin->fields() } ) {
                    push( @{ $self->_fields() }, $field );
                }
            } ## end if ( $alias && !exists...)
        } ## end try
        catch {
            $self->logger()->log( message => 'Failed to initialize plugin ' . $class_name . ' w/ error: ' . $_, level => 'warning', );
        };
    } ## end foreach my $class_name ( $self...)

    return $plugin_ref;
} ## end sub _init_plugins

sub _init_tt {
    my $self = shift;

        my $dist_dir;
    try {
        $dist_dir = File::ShareDir::dist_dir('Monitoring-Reporter');
    };
    my @inc = ( 'share/tpl', '../share/tpl', );
    if($dist_dir && -d $dist_dir) {
        push(@inc, $dist_dir.'/tpl');
    }
    my $cfg_dir = $self->config()->get('Monitoring::Reporter::TemplatePath');
    if($cfg_dir && -d $cfg_dir) {
        unshift(@inc,$cfg_dir);
    }

    my $tpl_config = {
        INCLUDE_PATH => [ @inc ],
        POST_CHOMP   => 1,
        FILTERS      => {
            'substr'   => [
                sub {
                    my ( $context, $len ) = @_;

                    return sub {
                        my $str = shift;
                        if ($len) {
                            $str = substr $str, 0, $len;
                        }
                        return $str;
                      }
                },
                1,
            ],
            'ucfirst'       => sub { my $str = shift; return ucfirst($str); },
            'localtime'     => sub {
                my $str = shift;
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($str);
                $year += 1900;
                $mon++;
                return sprintf('%02d.%02d.%04d %02d:%02d:%02d', $mday, $mon, $year, $hour, $min, $sec);
            },
            'sev2btn'       => sub {
                my $str = shift;
                return 'btn-info' if $str =~ m/^information$/i;
                return 'btn-warning' if $str =~ m/^warning$/i;
                return 'btn-warning' if $str =~ m/^average$/i;
                return 'btn-danger' if $str =~ m/^high$/i;
                return 'btn-danger' if $str =~ m/^disaster$/i;
            },
        },
    };
    my $TT = Template::->new($tpl_config);

    return $TT;
}

sub BUILD {
    my $self = shift;

    # init param filter list
    $self->plugins();

    return 1;
} ## end sub BUILD

# your code here ...
sub run {
    my $self = shift;
    my $env  = shift;

    my $plack_request = Plack::Request::->new($env);
    my $request       = $self->_filter_params($plack_request);

    # log request and ip
    $self->_log_request($request);

    return $self->_handle_request($request);
} ## end sub run

sub _filter_params {
    my $self    = shift;
    my $request = shift;

    my $params = $request->parameters();

    my $request_ref = {};
    foreach my $key ( @{ $self->_fields() } ) {
        if ( defined( $params->{$key} ) ) {
            $request_ref->{$key} = $params->{$key};
        }
    }

    # add the remote_addr
    $request_ref->{'remote_addr'} = $request->address();

    return $request_ref;
} ## end sub _filter_params

sub _handle_request {
    my $self    = shift;
    my $request = shift;

    my $mode = $request->{'mode'} || 'list_triggers';
    my $key  = $request->{'key'};

    # Check API key
    if($self->_key() && (!$key || $key ne $self->_key())) {
        return [ 400, [ 'Content-Type', 'text/plain' ], ['Bad Request - Invalid key'] ];
    }

    # Handle request
    if ( $mode && $self->plugins()->{$mode} && ref( $self->plugins()->{$mode} ) ) {
        if ( my $resp = $self->plugins()->{$mode}->execute($request) ) {
            return $resp;
        }
        else {
            return [ 500, [ 'Content-Type', 'text/plain' ], ['Processing Error'] ];
        }
    } ## end if ( $mode && $self->plugins...)
    else {
        return [ 400, [ 'Content-Type', 'text/html' ], [$self->_list_plugins()] ];
    }

    return 1;
} ## end sub _handle_request

sub _list_plugins {
  my $self = shift;
  my $request = shift;

  my $body = '<html><body><h1>Bad Request - Command not found</h1><h2>Available Plugins</h2><ul>';
  try {
    foreach my $plugin (sort keys %{ $self->plugins() } ) {
      my $alias = $self->plugins->{$plugin}->alias();
      $body .= '<li><a href="?mode='.$alias.'">'.$plugin.'</a>';
    }
  };
  $body .= '</ul></body></html>';

  return $body;
}

sub _log_request {
    my $self        = shift;
    my $request_ref = shift;

    my $remote_addr = $request_ref->{'remote_addr'};

    # turn key => value pairs into smth. like key1=value1,key2=value2,...
    my $args = join( q{,}, map { $_ . q{=} . $request_ref->{$_} } keys %{$request_ref} );

    $self->logger()->log( message => 'New Request from ' . $remote_addr . '. Args: ' . $args, level => 'debug', );

    return 1;
} ## end sub _log_request

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Web - a plack based webinterface to Monitoring::Reporter

=head1 METHODS

=head2 BUILD

Initialize all plugins.

=head2 run

Process a request.

=head1 NAME

Monitoring::Reporter::Web - a plack based webinterface to Monitoring::Reporter

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
