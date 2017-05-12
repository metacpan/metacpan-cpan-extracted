package Silki::DatabaseManager;

use strict;
use warnings;
use autodie qw( :all );

use lib 'lib';

use MooseX::Types::Moose qw( Bool HashRef Str );
use Path::Class qw( dir file );

use Moose;
use MooseX::StrictConstructor;

extends 'Pg::DatabaseManager';

with 'MooseX::Getopt::Dashes';

has '+app_name' => (
    default => 'Silki',
);

has '+db_encoding' => (
    default => 'UTF-8',
);

has '+contrib_files' => (
    lazy    => 1,
    default => sub {
        $_[0]->sql_file() =~ /v[12]$/ ? [] : ['citext.sql'];
    },
);

has _existing_config => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => HashRef[Str],
    lazy    => 1,
    builder => '_build_existing_config',
);

has seed => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation =>
        'When this is true, a newly created database will be seeded with some initial required data. Defaults to false.',
);

has production => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation =>
        'If true, this changes what data is seeded. In particular, only one wiki will be seeded instead of three.',
);

# If this isn't done these attributes end up interleaved with attributes from
# the parent class when --help is run.
__PACKAGE__->meta()->get_attribute('seed')->_set_insertion_order(20);
__PACKAGE__->meta()->get_attribute('production')->_set_insertion_order(21);

sub BUILD {
    my $self = shift;
    my $p    = shift;

    my $existing = $self->_existing_config();
    unless ( exists $p->{db_name} ) {
        die
            "No database name provided to the constructor and none can be found in an existing Silki config file."
            unless $existing->{name};

        $self->_set_db_name( $existing->{name} );
    }

    for my $attr (qw( username password host port )) {
        my $set = '_set_' . $attr;

        $self->$set( $existing->{$attr} )
            if defined $existing->{$attr};
    }

    return;
}

after update_or_install_db => sub {
    my $self = shift;

    $self->_seed_data() if $self->seed();
};

override '_connect_failure_message' => sub {
    my $self = shift;

    my $msg = super();

    $msg
        .= "\n  You can change connection info settings by passing arguments to 'perl Build.PL'\n";
    $msg .= "  See the INSTALL documentation for details.\n\n";

    return $msg;
};

sub _build_existing_config {
    my $self = shift;

    require Silki::Config;

    my $instance = Silki::Config->instance();

    return {} unless $instance->config_file();

    return {
        map {
            my $attr = 'database_' . $_;
            $instance->$attr() ? ( $_ => $instance->$attr() ) : ()
            } qw( name username password host port )
    };
}

sub _build_sql_file {
    return file( 'schema', 'Silki.sql' );
}

sub _build_migrations_dir {
    return dir( 'inc', 'migrations' );
}

sub _seed_data {
    my $self = shift;

    require Silki::Config;

    my $config = Silki::Config->instance();
    $config->_set_database_name( $self->db_name() );

    for my $key (qw( username password host port )) {
        if ( my $val = $self->$key() ) {
            my $set_meth = '_set_database_' . $key;

            $config->$set_meth($val);
        }
    }

    require Silki::SeedData;

    my $db_name = $self->db_name();
    $self->_msg("Seeding the $db_name database");

    Silki::SeedData::seed_data(
        production => $self->production(),
        verbose    => !$self->quiet()
    );
}

1;
