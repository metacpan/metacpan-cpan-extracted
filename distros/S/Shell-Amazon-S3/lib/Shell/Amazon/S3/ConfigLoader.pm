package Shell::Amazon::S3::ConfigLoader;
use Moose;
use YAML;
use File::HomeDir;
use Path::Class qw(file);
use ExtUtils::MakeMaker ();

has 'changed' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {0},
);

has 'conf' => (
    is      => 'rw',
    default => sub { file( File::HomeDir->my_home, ".psh3ll" ) },
);

sub prompt {
    my ( $self, $prompt ) = @_;
    my $value = ExtUtils::MakeMaker::prompt($prompt);
    $self->changed( $self->changed + 1 );
    return $value;
}

# TODO: More testable
# we need to inject access key and secret access key outsied 
sub load {
    my $self = shift;
    my $config = eval { YAML::LoadFile( $self->conf ) } || {};
    $config->{aws_access_key_id} ||= $self->prompt("AWS access key:");
    $config->{aws_secret_access_key}
        ||= $self->prompt("AWS secret access key:");
    $self->save($config);
    return $config;
}

sub update {
    my ( $self, $key, $value ) = @_;
    my $config = eval { YAML::LoadFile( $self->conf ) } || {};
    $config->{$key} = $value;
    $self->changed( $self->changed + 1 );
    $self->save($config);
}

sub save {
    my ( $self, $conf ) = @_;
    if ( $self->changed ) {
        YAML::DumpFile( $self->conf, $conf );
        chmod 0600, $self->conf;
    }
    $self->changed(0);
}

__PACKAGE__->meta->make_immutable;

1;
