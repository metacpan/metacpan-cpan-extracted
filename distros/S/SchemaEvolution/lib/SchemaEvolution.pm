package SchemaEvolution;
our $VERSION = '0.03';


# ABSTRACT: SchemaEvolution - manage the evolution of a database with simple files

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( ArrayRef Bool HashRef Str );

use Config::Tiny;
use DBI;
use File::Find::Rule;
use File::Slurp;
use Path::Class qw( file );
use SchemaEvolution::Types qw( DBH );
use TryCatch;

with 'MooseX::Getopt';

has 'config_file' => (
    traits => [qw( Getopt )],
    isa => Str,
    cmd_aliases => [qw( c config )],
    ro,
    default => 'evolution.ini',
    required
);

has 'initialize' => (
    traits => [qw( Getopt )],
    isa => Bool,
    ro,
    default => 0,
);

sub run {
    my $self = shift;

    $self->initialize_table if ($self->initialize);


    my $dbh = $self->_dbh;
    my ($column, $table) = ($self->_version_column, $self->_version_table);
    my ($version) = $dbh->selectrow_array("SELECT $column FROM $table");
    defined $version
        or die "Could not select version column '$column' from meta table '$table'";
    my @evolutions = $self->evolutions_after_version($version);
    if (@evolutions == 0) {
        print "Didn't find any schema evolutions, nothing to do\n";
        return;
    }

    my $new_version = $version;
    for my $evolution (@evolutions) {
        try {
            $new_version = $self->apply_evolution($evolution);
        } catch {
            print "encountered an error, aborting.\n";
            last;
        }
    }

    print "\nSchema evolution completed (or terminated)\n";
    print "New version is: $new_version\n";
    $self->_set_version($new_version);
}

sub initialize_table {
    my $self = shift;
    my $dbh = $self->_dbh;
    my ($column, $table) = ($self->_version_column, $self->_version_table);
    $dbh->do("CREATE TABLE $table ( $column INTEGER NOT NULL DEFAULT 0 )");
    $dbh->do("INSERT INTO $table ( $column) VALUES ( 0 )");
}

sub apply_evolution {
    my ($self, $filename) = @_;
    print "Applying $filename... ";
    my $dbh = $self->_dbh;
    my $sql = read_file($filename) or die "Could read contents of $filename!";
    my $res = $dbh->do($sql);
    if (!defined $res) {
        die "Could not apply $filename";
    }
    print "done!\n";
    return _version_from_filename($filename);
}

sub _set_version {
    my ($self, $version) = @_;
    my ($column, $table) = ($self->_version_column, $self->_version_table);
    $self->_dbh->do("UPDATE $table SET $column = ?", {}, $version);
}

sub _version_from_filename
{
    my $filename = shift;
    my ($v) = file($filename)->basename =~ /^(\d+)/;
    return int($v);
}

sub evolutions_after_version
{
    my ($self, $version) = @_;
    return sort {
        _version_from_filename($a) <=> _version_from_filename($b)
    } grep {
        _version_from_filename($_) > $version;
    } @{ $self->_evolutions };
}

has '_evolutions' => (
    isa => ArrayRef[Str],
    lazy,
    ro,
    default => sub {
        my $self = shift;
        return [
            File::Find::Rule->file()
                  ->name('*.sql')->in($self->_evolutions_dir)
              ];
    }
);

has '_config' => (
    ro,
    lazy_build
);

sub _build__config {
    my $self = shift;
    my $tiny = Config::Tiny->new;
    my $config = $tiny->read($self->config_file)
        or die 'Could not open ' . $self->config_file;
    return $config;
}

for my $param (qw(username password dsn)) {
    has "_$param" => (
        ro,
        lazy,
        default => sub { shift->_config->{_}->{$param} }
    );
}

has '_version_table' => (
    ro,
    isa => Str,
    lazy => 1,
    default => sub { shift->_config->{_}->{version_table} || 'schema_version' }
);

has '_version_column' => (
    ro,
    isa => Str,
    lazy => 1,
    default => sub { shift->_config->{_}->{version_column} || 'version' }
);

has '_evolutions_dir' => (
    ro,
    isa => Str,
    lazy => 1,
    default => sub { shift->_config->{_}->{evolutions} || 'evolutions' }
);

has '_dbh' => (
    isa => DBH,
    ro,
    lazy_build
);

sub _build__dbh {
    my $self = shift;
    my $dsn = $self->_dsn or die 'Missing required option "dsn"';
    my @args = ($dsn);
    push @args, $self->_username if $self->_username;
    push @args, $self->_password if $self->_password;
    my $dbh = DBI->connect(@args)
        or die "Could not connect to: " . $self->_dsn;
    return $dbh;
}

1;



__END__
=pod

=head1 NAME

SchemaEvolution - SchemaEvolution - manage the evolution of a database with simple files

=head1 VERSION

version 0.03

=head1 DESCRIPTION

SchemaEvolution is a very basic tool to cope with evolving a database
schema over time. Rather than hook in with any specific framework,
this is nothing more than a single table to track the version of
database, and a set of scripts to move from one version to another.

=head1 METHODS

=head2 run

Runs the schema evolution process, with settings from the configuration
options. This is the entry point of the 'evolve' script.

=head2 apply_evolution $filename

Applies a single evolution pointed to by $filename (raw SQL), and returns
the new version of the schema.

=head2 evolutions_after_version $version

Returns all the evolution filenames that are after $version.

=head1 AUTHOR

  Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Oliver Charles.

This is free software, licensed under:

  The Artistic License 2.0

=cut

