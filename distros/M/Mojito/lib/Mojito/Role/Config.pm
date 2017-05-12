use strictures 1;
package Mojito::Role::Config;
{
  $Mojito::Role::Config::VERSION = '0.24';
}
use Moo::Role;
use MooX::Types::MooseLike::Base qw(HashRef);
use Dir::Self;
use Path::Class qw(file);
use Data::Dumper::Concise;

has 'config' => (
    is  => 'rw',
    isa => HashRef,
    lazy => 1,
    builder => '_build_config',
);

=head2 _build_config

Construct the configuration file.
Config file is looked for in three locations:

    ENV
    lib/Mojito/conf/mojito_local.conf
    lib/Mojito/conf/mojito.conf

    The values will be merged with the precedent order being:
    ENV over
    mojito_local.conf over
    mojito.conf

=cut

sub _build_config {
    my ($self) = @_;

    warn "BUILD CONFIG" if $ENV{MOJITO_DEBUG};
    my $conf_file       = file(__DIR__ . '/../conf/mojito.conf');
    $conf_file->cleanup;
    $conf_file->resolve if (-e $conf_file);

    my $local_conf_file = file(__DIR__ . '/../conf/mojito_local.conf');
    $local_conf_file->cleanup;
    $local_conf_file->resolve if (-e $local_conf_file);

    my $env_conf_file   = $ENV{MOJITO_CONFIG};
    warn "ENV CONFIG: $ENV{MOJITO_CONFIG}" if ($ENV{MOJITO_DEBUG} and $ENV{MOJITO_CONFIG});

    my $conf       = $self->read_config($conf_file);
    my $local_conf = $self->read_config($local_conf_file);
    my $env_conf   = $self->read_config($env_conf_file);

    # The merge happens in pairs
    my $merged_conf = $self->merge_hash($local_conf, $conf);
       $merged_conf = $self->merge_hash($env_conf, $merged_conf);
    return $merged_conf;
}

=head2 read_config

    Args: a configuration file name
    Returns: a HashRef of configuration values

=cut

sub read_config {
    my ($self, $conf_file) = @_;

    my $config = {};
    if ( $conf_file && -r $conf_file ) {
        if ( not $config = do $conf_file ) {
            die qq/Can't do config file "$conf_file" EXCEPTION: $@/ if $@;
            die qq/Can't do config file "$conf_file" UNDEFINED: $!/ if not defined $config;
        }
    }

    # Let's add in the version number.
    $config->{VERSION} = $Mojito::Role::Config::VERSION || 'development version';

    return $config;
}

=head2 merge_hash

    Args: ($hash_ref_dominant, $hash_ref_subordinate)
    Returns: HashRef of the two merged with the dominant values
    chosen when they exist otherwise the subordinate values are used.

=cut

sub merge_hash {
    my ($self, $precedent, $subordinate) = @_;
    my @not = grep !exists $precedent->{$_}, keys %{$subordinate};
    @{$precedent}{@not} = @{$subordinate}{@not};
    return $precedent;
}


1;
