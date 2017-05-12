package MySQL::Workbench::SQLiteSimple;

# ABSTRACT: Create a simple .sql file for SQLite

use warnings;
use strict;

use Carp;
use File::Spec;
use List::Util qw(first);
use Moo;
use MySQL::Workbench::Parser;

# ABSTRACT: create DBIC scheme for MySQL workbench .mwb files

our $VERSION = '0.02';

has output_path    => ( is => 'ro', required => 1, default => sub { '.' } );
has file           => ( is => 'ro', required => 1 );

sub create_sql {
    my $self = shift;
    
    my $parser = MySQL::Workbench::Parser->new( file => $self->file ); 
    my @tables = @{ $parser->tables };

    my @tables_sql = $self->_create_tables( \@tables );

    $self->_write_files( @tables_sql );
}

sub _write_files{
    my ($self, @sqls) = @_;
    
    my $dir = $self->_untaint_path( $self->output_path || '.' );
    my $path = File::Spec->catfile( $dir, 'sqlite.sql' );
        
    unless( -e $dir ){
        $self->_mkpath( $dir );
    }

    if( open my $fh, '>', $path ) {
        print $fh join "\n\n", @sqls;
        close $fh;
    }
    else{
        croak "Couldn't create $path: $!";
    }
}

sub _untaint_path{
    my ($self,$path) = @_;
    ($path) = ( $path =~ /(.*)/ );
    # win32 uses ';' for a path separator, assume others use ':'
    my $sep = ($^O =~ /win32/i) ? ';' : ':';
    # -T disallows relative directories in the PATH
    $path = join $sep, grep !/^\.+$/, split /$sep/, $path;
    return $path;
}

sub _mkpath{
    my ($self, $path) = @_;
    
    my @parts = split /[\\\/]/, $path;
    
    for my $i ( 0..$#parts ){
        my $dir = File::Spec->catdir( @parts[ 0..$i ] );
        $dir = $self->_untaint_path( $dir );
        unless ( -e $dir ) {
            mkdir $dir or die "$dir: $!";
        }
    }
}

sub _create_tables {
    my ($self, $tables) = @_;

    my @sqls;
    for my $table ( @{ $tables } ) {
    
        my $name    = $table->name;
        my @columns = $self->_get_columns( $table );
        my $pk      = sprintf ",\n    PRIMARY KEY (%s)", join ', ', @{ $table->primary_key || [] };
        if ( first { $_ =~ /PRIMARY KEY/ }@columns ) {
            $pk = '';
        }

        my $sql = sprintf q~CREATE TABLE `%s` (
    %s%s
);
~, $name, join( ",\n    ", @columns), $pk;
        push @sqls, $sql;
    }

    return @sqls;
}

sub _get_columns {
    my ($self, $table) = @_;

    my @columns = @{ $table->columns };

    my @create_columns;

    for my $column ( @columns ) {
        my $default_value = $column->default_value || '';
        $default_value =~ s/'/\\'/g;

        my $datatype    = $column->datatype;
        my $sqlite_type = 'TEXT';
        if ( first{ $datatype eq $_ }qw/SMALLINT INT INTEGER BIGINT MEDIUMINT/ ) {
            $sqlite_type = 'INTEGER';
        }

        my $name           = $column->name;
        my $not_null       = $column->not_null ? ' NOT NULL' : '';
        my $auto_increment = $column->autoincrement ? ' AUTOINCREMENT' : '';
        my $pk             = $auto_increment ? ' PRIMARY KEY' : '';

        my $single_column  = sprintf q~%s %s%s%s%s~,
            $name, $sqlite_type, $not_null, $pk, $auto_increment;

        push @create_columns, $single_column;
    }

    return @create_columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::SQLiteSimple - Create a simple .sql file for SQLite

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use MySQL::Workbench::SQLiteSimple;

    my $foo = MySQL::Workbench::SQLiteSimple->new(
        file           => '/path/to/file.mwb',
        output_path    => $some_path,
    );

    $foo->create_sql;

=head1 METHODS

=head2 new

creates a new object of MySQL::Workbench::DBIC. You can pass some parameters
to new:

  my $foo = MySQL::Workbench::DBIC->new(
    output_path => '/path/to/dir',
    file        => '/path/to/dbdesigner.file',
  );

=head2 create_sql

creates a sqlite.sql

=head1 ATTRIBUTES

=head2 output_path

sets / gets the output path for the scheme

  print $foo->output_path;

=head2 file

sets / gets the name of the Workbench file

  print $foo->file;

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
