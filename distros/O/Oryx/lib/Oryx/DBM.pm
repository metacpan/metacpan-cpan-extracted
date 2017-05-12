package Oryx::DBM;

use DBM::Deep;
use Oryx::DBM::Class;
use Oryx::DBM::Util;
use Oryx::Class;

use base qw(Oryx Oryx::MetaClass);

__PACKAGE__->mk_classdata("datapath");

our $DEBUG = 0;

=head1 NAME

Oryx::DBM - DBM Storage interface for Oryx

=head1 SYNOPSIS

 my $storage = Oryx::DBM->new;
 
 $storage->connect([ 'dbm:Deep:datapath=/path/to/datafiles' ]);
  
 $storage->dbh;
 $storage->db_name;
 $storage->ping;
 $storage->schema;
 $storage->util;
 $storage->set_util;
 $storage->deploy_class;
 $storage->deploy_schema;

=head1 DESCRIPTION

DBM Storage interface for Oryx. You should not need to instantiate
this directly, use C<< Oryx->connect() >> instead.

=head1 METHODS

=over

=item new

Simple constructor

=cut

sub new {
    my $class = shift;
    return bless { }, $class;
}


=item dbh

stub - returns $self

=cut

sub dbh { $_[0] }
sub commit {  }

=item connect( \@conn, [$schema] )

Called by C<< Oryx->connect() >>. You shouldn't need to be doing this.

=cut

# $conn looks like this : ["dbm:Deep:datapath=/path/to/data"]
sub connect {
    my ($self, $conn, $schema) = @_;

    if ($conn->[0] =~ /^dbm:Deep:datapath=(.+)$/) {
        $self->_croak('ERROR: connect called without a datapath')
            unless $1;
        $self->datapath($1);
    } else {
        $self->_croak("ERROR: bad dsn $conn->[0]");
    }

    $self->catalog(DBM::Deep->new($self->datapath.'/oryx_catalog'));

    $self->init('Oryx::DBM::Class', $conn, $schema);

    return $self;
}

=item catalog

L<DBM::Deep> instance for holding the catalog of tables. This is
a sort of global internal store for the DBM backend for keeping
meta data which it needs.

=cut

sub catalog { $_[0]->{catalog} = $_[1] if $_[1]; $_[0]->{catalog} }

=item ping

ping the database - all this does here is make sure the C<catalog>
exists and is a L<DBM::Deep> instance

=cut

sub ping {
    my $self = shift;
    return UNIVERSAL::isa($self->catalog, 'DBM::Deep');
}

=item schema

returns the schema if called with no arguments, otherwise
sets if called with a L<Oryx::Schema> instance.

=cut


sub schema {
    my $self = shift;
    $self->{schema} = shift if @_;
    $self->{schema};
}

=item schema

returns the schema if called with no arguments, otherwise
sets if called with a L<Oryx::Schema> instance.

=cut

sub util {
    my $self = shift;
    $self->{util} = shift if @_;
    $self->{util};
}

=item set_util

determines which L<Oryx::DBI::Util> class to instantiate
by looking at the dsn passed to C<connect> and sets it

=cut

sub set_util {
    my $self = shift;
    $self->util( Oryx::DBM::Util->new );
}

=item deploy_schema( $schema )

Takes a L<Oryx::Schema> instance and deploys all classes seen by that
schema instance to the database creating all L<DBM::Deep> db files
needed for storing your persistent objects.

=cut

sub deploy_schema {
    my ($self, $schema) = @_;
    $schema = $self->schema unless defined $schema;

    $DEBUG && $self->_carp(
	"deploy_schema $schema : classes => ".join(",\n", $schema->classes)
    );
    unless (-d $self->datapath) {
	mkdir $self->datapath;
    }
    foreach my $class ($schema->classes) {
	$self->deploy_class($class);
    }
}

=item deploy_class( $class )

does the work of deploying a given class; called by C<deploy_schema>

=cut

sub deploy_class {
    my ($self, $class) = @_;
    $DEBUG && $self->_carp("DEPLOYING $class");
    $self->util->table_create($self, $class->table);
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>, L<Oryx::DBM::Util>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
