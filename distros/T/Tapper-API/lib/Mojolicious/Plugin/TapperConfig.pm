package Mojolicious::Plugin::TapperConfig;
our $AUTHORITY = 'cpan:TAPPER';
$Mojolicious::Plugin::TapperConfig::VERSION = '5.0.2';
use Mojo::Base 'Mojolicious::Plugin';
use Tapper::Config;
# ABSTRACT: create config for Hypnotoad used in Tapper


sub register {

    my ($self, $app) = @_;

    my $port     = Tapper::Config->subconfig->{rest_api_port} || 3000;
    my $pid_file = Tapper::Config->subconfig->{paths}{workdir}."/tapper-rest-api-daemon.pid";
    my $config   = {hypnotoad => {listen => ["http://*:$port"], pid_file => $pid_file}};
    my $current  = $app->defaults(config => $app->config)->config;
     %{$current} = (%{$current}, %{$config});

    return $current;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::TapperConfig - create config for Hypnotoad used in Tapper

=head1 SYNOPSIS

This module generates a config for the hypnotoad driving the Tapper::API
daemon. It will be integrated by telling Mojolicious to use this plugin.

 use Mojo::Base 'Mojolicious';

 sub startup
 {
     my ($self) = shift;
     $self->plugin('TapperConfig');
     ...
 }

=head1 FUNCTIONS

Register this plugin in the plugin system. Not supposed to be called
externally.

=head1 AUTHOR

Tapper Team <tapper-ops@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Amazon.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
