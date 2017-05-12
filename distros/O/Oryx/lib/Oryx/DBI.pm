package Oryx::DBI;

use Oryx::DBI::Class;

use base qw(Oryx Oryx::MetaClass Ima::DBI);

our $DEBUG = 0;

=head1 NAME

Oryx::DBI - DBI Storage interface for Oryx

=head1 SYNOPSIS

 my $storage = Oryx::DBI->new;
 
 $storage->connect([ 'dbi:Pg:dbname=mydb', $usname, $passwd]);
 $storage->connect([ 'dbi:Pg:dbname=mydb', $usname, $passwd], $schema);
  
 $storage->dbh;
 $storage->db_name;
 $storage->ping;
 $storage->schema;
 $storage->util;
 $storage->set_util;
 $storage->deploy_class;
 $storage->deploy_schema;

=head1 DESCRIPTION

DBI Storage interface for Oryx. You should not need to instantiate
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

=item connect( \@conn, [$schema] )

Called by C<< Oryx->connect() >>. You shouldn't need to be doing this.

=cut

sub connect {
    my ($self, $conn, $schema) = @_;

    eval "use $schema"; $self->_croak($@) if $@;

    my $db_name = $schema->name;
    $self->_croak("no schema name '$db_name'")
        unless $db_name;

    ref($self)->set_db($db_name, @$conn)
        unless UNIVERSAL::can($self, "db_$db_name");

    $self->init('Oryx::DBI::Class', $conn, $schema);
    return $self;
}

=item dbh

returns the cached L<DBI> handle object

=cut

sub dbh {
    my $class = shift;
    my $db_name = $class->db_name;
    eval { $class->$db_name };
    $class->_croak($@) if $@;
    return $class->$db_name();
}

=item db_name

Shortcut for C<< "db_".$self->schema->name >> used for passing
a name to L<Ima::DBI>'s C<set_db> method.

=cut

sub db_name {
    my $self = shift;
    return "db_".$self->schema->name;
}

=item ping

ping the database

=cut

sub ping {
    my $self = shift;
    my $sth = $self->dbh->prepare('SELECT 1+1');
    $sth->execute;
    $sth->finish;
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

=item util

simple mutator for accessing the oryx::dbi::util::x instance

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
    my ($self, $dsn) = @_;
    $dsn =~ /^dbi:(\w+)/i;
    my $utilClass = __PACKAGE__."\::Util\::$1";

    eval "use $utilClass";
    $self->_carp($@) if $@;

    # Can't construct the utilClass: fallback to Generic and pray it works
    unless (UNIVERSAL::can($utilClass, 'new')) {
        $utilClass = __PACKAGE__."\::Util::Generic";

        eval "use $utilClass";
        $self->_croak($@) if $@;
    }

    $self->util($utilClass->new);
}


=item deploy_schema( $schema )

Takes a L<Oryx::Schema> instance and deploys all classes seen by that
schema instance to the database building all tables needed for storing
your persistent objects.

=cut

sub deploy_schema {
    my ($self, $schema) = @_;
    $schema = $self->schema unless defined $schema;

    $DEBUG && $self->_carp(
	"deploy_schema $schema : classes => "
        .join(",\n", $schema->classes)
    );

    foreach my $class ($schema->classes) {
	$self->deploy_class($class);
    }
}

=item deploy_class( $class )

does the work of deploying a given class' tables and link tables to
the database; called by C<deploy_schema>

=cut

sub deploy_class {
    my $self = shift;
    my $class = shift;
    $DEBUG && $self->_carp("DEPLOYING $class");

    eval "use $class"; $self->_croak($@) if $@;

    my $dbh   = $class->dbh;
    my $table = $class->table;

    my $int = $self->util->type2sql('Integer');
    my $oid = $self->util->type2sql('Oid');

    my @columns = ('id');
    my @types   = ($oid);
    if ($class->is_abstract) {
	$DEBUG && $self->_carp("CLASS $class IS ABSTRACT");
	push @columns, '_isa';
	push @types, $self->util->type2sql('String');
    }

    foreach my $attrib (values %{$class->attributes}) {
	$DEBUG && $self->_carp("GOT ATTRIBUTE => $attrib");
	push @columns, $attrib->name;
	push @types, $self->util->type2sql($attrib->primitive, $attrib->size);
    }

    foreach my $assoc (values %{$class->associations}) {
	my $target_class = $assoc->class;
	eval "use $target_class"; $self->_croak($@) if $@;
	if ($assoc->type ne 'Reference') {
	    # create a link table
	    my $lt_name = $assoc->link_table;
	    my @lt_cols = $assoc->link_fields;
	    my @lt_types = ($int) x 2;

	    # set up the meta column (3rd entry in @lt_cols) to store
	    # indicies or keys depeding on the type of Association
	    if (lc($assoc->type) eq 'array') {
		push @lt_types, $int;
	    }
	    elsif (lc($assoc->type) eq 'hash') {
		push @lt_types, $self->util->type2sql('String');
	    }

	    $self->util->table_create(
                $dbh, $lt_name, \@lt_cols, \@lt_types
            );
	}
        elsif (not $assoc->is_weak) {
	    push @types,   $int;
	    push @columns, $assoc->role;
	}
    }

    if (@{$class->parents}) {
	my @lt_cols  = (lc($class->name.'_id'));
	my @lt_types = ($int) x (scalar(@{$class->parents}) + 1);
	my $lt_name  = lc($class->name."_parents");
	push @lt_cols, map { lc($_->class->name) } @{$class->parents};

	$DEBUG && $self->_carp(
            "PARENT $_, lt_name => $lt_name, lt_cols => "
	    .join("|", @lt_cols).", lt_types => "
	    .join("|", @lt_types));

	# create the link table
	$self->util->table_create(
            $dbh, $lt_name, \@lt_cols, \@lt_types
        );
    }

    $self->util->table_create($dbh, $table, \@columns, \@types);
#    $self->util->sequence_create($dbh, $table);

    $dbh->commit;
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>, L<Oryx::DBI::Util>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
