package Mojolicious::Plugin::ConfigGeneral;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ConfigGeneral - Config::General Configuration Plugin for Mojolicious

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use Mojolicious::Plugin::ConfigGeneral;

    # Mojolicious
    my $config = $app->plugin('ConfigGeneral');
    say $config->{foo};

    # Mojolicious::Lite
    my $config = plugin 'ConfigGeneral';
    say $config->{foo};

    # The configuration is available application-wide
    my $config = app->config;
    say $config->{foo};

    # Everything can be customized with options
    my $config = plugin ConfigGeneral => {file => '/etc/myapp.conf'};

=head1 DESCRIPTION

Mojolicious::Plugin::ConfigGeneral is a L<Config::General> Configuration Plugin for Mojolicious

=head1 OPTIONS

This plugin supports the following options

=head2 default

    # Mojolicious::Lite
    plugin ConfigGeneral => {default => {foo => 'bar'}};

Default configuration

=head2 file

    # Mojolicious::Lite
    plugin ConfigGeneral => {file => 'myapp.conf'};
    plugin ConfigGeneral => {file => '/etc/foo.stuff'};

Path to configuration file, absolute or relative to the application home directory, defaults to the value of the
C<MOJO_CONFIG> environment variable or C<$moniker.conf> in the application home directory.

=head2 noload

    plugin ConfigGeneral => {noload => 1};

This option disables loading config file

=head2 opts

    # Mojolicious::Lite
    plugin ConfigGeneral => {opts => {'-AutoTrue' => 0}};
    plugin ConfigGeneral => {options => {'-AutoTrue' => 0}};

Sets the L<Config::General> options directly

=head1 METHODS

This plugin inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

    my $config = $plugin->register(Mojolicious->new);
    my $config = $plugin->register(Mojolicious->new, {file => '/etc/foo.conf'});

Register plugin in L<Mojolicious> application and set configuration.

=head1 HELPERS

All helpers of this plugin are allows get access to configuration parameters by path-pointers.
See L<Mojo::JSON::Pointer> and L<RFC 6901|https://tools.ietf.org/html/rfc6901>

=over 8

=item conf-E<gt>get

    say $self->conf->get('/datadir');

Returns configuration value by path

=item conf-E<gt>first

    dumper $self->conf->first('/foo'); # ['first', 'second', 'third']
        # 'first'

Returns an first value of found values from configuration

=item conf-E<gt>latest

    dumper $self->conf->latest('/foo'); # ['first', 'second', 'third']
        # 'third'

Returns an latest value of found values from configuration

=item conf-E<gt>array, conf-E<gt>list

    dumper $self->conf->array('/foo'); # ['first', 'second', 'third']
        # ['first', 'second', 'third']
    dumper $self->conf->array('/foo'); # 'value'
        # ['value']

Returns an array of found values from configuration

=item conf-E<gt>hash, conf-E<gt>object

    dumper $self->conf->array('/foo'); # { foo => 'first', bar => 'second' }
        # { foo => 'first', bar => 'second' }

Returns an hash of found values from configuration

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious::Plugin::Config>, L<Config::General>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.02';

use Mojo::Base 'Mojolicious::Plugin';
use Config::General qw//;
use Mojo::File qw/path/;
use Mojo::JSON::Pointer qw//;

use constant DEFAULT_CG_OPTS => {
    '-ApacheCompatible' => 1, # Makes possible to tweak all options in a way that Apache configs can be parsed
    '-LowerCaseNames'   => 1, # All options found in the config will be converted to lowercase
    '-UTF8'             => 1, # All files will be opened in utf8 mode
    '-AutoTrue'         => 1, # All options in your config file, whose values are set to true or false values, will be normalised to 1 or 0 respectively
};

has 'config_pointer' => sub { Mojo::JSON::Pointer->new };

sub register {
    my ($self, $app, $args) = @_;

    # NoLoad
    my $noload = $args->{noload} || 0;

    # Config file
    my $file = $args->{file} || $ENV{MOJO_CONFIG};
       $file ||= $app->home->child($app->moniker . '.conf'); # Relative to the home directory by default
    unless ($noload) {
        die sprintf("Configuration file \"%s\" not found", $file) unless -r $file;
    }

    # Config::General Options
    my $opts    = $args->{options} || $args->{opts} || {};
       $opts = {} unless ref($opts) eq 'HASH';
    my %options = (%{DEFAULT_CG_OPTS()}, %$opts); # Merge everything
       $options{'-ConfigFile'} = $file;

    # Load
    my %config = ();
    my @files = ();
    unless ($noload) {
        my $cfg = eval { Config::General->new(%options) };
        die sprintf("Can't load configuration from file \"%s\": %s", $file, $@) if $@;
        die sprintf("Configuration file \"%s\" did not return a Config::General object", $file) unless ref $cfg eq 'Config::General';
        %config = $cfg->getall;
        @files = $cfg->files;
    }

    # Merge defaults
    my $defaults = $args->{defaults} || $args->{default} || {};
    %config = (%$defaults, %config) if (ref($defaults) eq 'HASH') && scalar keys %$defaults;

    # Add system values
    $config{'_config_files'} = [@files];
    $config{'_config_loaded'} = scalar @files;

    # Set config data
    $app->config(\%config);
    $self->config_pointer->data(\%config);

    # Helpers
    my $_conf_get = sub {
        my $this = shift;
        my $key = shift;
        return $self->config_pointer->get($key);
    };
    my $_conf_fisrt = sub {
        my $this = shift;
        return undef unless defined($_[0]) && length($_[0]);
        my $node = $self->config_pointer->get($_[0]);
        if ($node && ref($node) eq 'ARRAY') { # Array
            return exists($node->[0]) ? $node->[0] : undef;
        } elsif (defined($node) && !ref($node)) { # Scalar
            return $node;
        }
        return undef;
    };
    my $_conf_latest = sub {
        my $this = shift;
        return undef unless defined($_[0]) && length($_[0]);
        my $node = $self->config_pointer->get($_[0]);
        if ($node && ref($node) eq 'ARRAY') { # Array
            return exists($node->[0]) ? $node->[-1] : undef;
        } elsif (defined($node) && !ref($node)) { # Scalar
            return $node;
        }
        return undef;
    };
    my $_conf_array = sub {
        my $this = shift;
        return undef unless defined($_[0]) && length($_[0]);
        my $node = $self->config_pointer->get($_[0]);
        if ($node && ref($node) eq 'ARRAY') { # Array
            return $node;
        } elsif (defined($node)) {
            return [$node];
        }
        return [];
    };
    my $_conf_hash = sub {
        my $this = shift;
        return undef unless defined($_[0]) && length($_[0]);
        my $node = $self->config_pointer->get($_[0]);
        if ($node && ref($node) eq 'HASH') { # Hash
            return $node;
        }
        return {};
    };

    # Set conf helpers
    $app->helper('conf.get'         => $_conf_get);
    $app->helper('conf.first'       => $_conf_fisrt);
    $app->helper('conf.latest'      => $_conf_latest);
    $app->helper('conf.array'       => $_conf_array);
    $app->helper('conf.list'        => $_conf_array);
    $app->helper('conf.hash'        => $_conf_hash);
    $app->helper('conf.object'      => $_conf_hash);

    # Return
    return wantarray ? (%config) : \%config;
}

1;

__END__
