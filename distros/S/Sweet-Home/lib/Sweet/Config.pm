package Sweet::Config;
use latest;
use Moose::Role;

use Carp;
use UNIVERSAL::require;

use namespace::autoclean;

requires qw(file_config_classname);

has config => (
    default => sub {
        my $self = shift;

        my @namespace = @{ $self->_config_namespace };

        my $file_config = $self->_file_config;

        my $config = $file_config->content;

        for (my $i = 0 ; $i < scalar(@namespace) ; $i++) {
            my $node = $namespace[$i];

            $config = $config->{$node};

            defined $config
                or croak "Could not found configuration entry in $file_config: " . join(' > ', @namespace[ 0 .. $i ]) . "\n";
        }


        return $config;
    },
    is   => 'ro',
    isa  => 'HashRef',
    lazy => 1,
);

has _file_config => (
    default => sub {
        my $self = shift;

        my $file_config_classname = $self->file_config_classname;
        $file_config_classname->require;

        my $file_config = $file_config_classname->new;

        return $file_config;
    },
    is   => 'ro',
    isa  => 'Sweet::File::Config',
    lazy => 1,
);

has _config_namespace => (
    builder => '_build_config_namespace',
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
);

sub _build_config_namespace {
    my $self = shift;

    my $package_name = $self->meta->name;

    my @namespace = split '::', $package_name;

    return \@namespace;
}

1;

__END__

=head1 NAME

Sweet::Config

=head1 ATTRIBUTES

=head2 config

=head1 PRIVATE ATTRIBUTES

=head2 _config_namespace

=cut

