package Test::Chado::Role::Helper::WithBcs;
{
  $Test::Chado::Role::Helper::WithBcs::VERSION = 'v4.1.1';
}

# Other modules:
use Moo::Role;
use MooX::late;
use MooX::HandlesVia;
use Bio::Chado::Schema;
use namespace::autoclean;
use Carp;
use Data::Perl qw/hash/;
use Bio::Chado::Schema;
use Test::Chado::Types qw/BCS HashiFied DbManager DBIC/;
use Module::Load qw/load/;

# Module implementation
#

requires 'namespace';

has 'dbmanager' => ( is => 'rw', isa => DbManager );

has 'dynamic_schema' => (
    is      => 'ro',
    isa     => DBIC,
    lazy    => 1,
    default => sub {
        my $self = shift;
        if (    $self->dbmanager->can('is_dynamic_schema')
            and $self->dbmanager->is_dynamic_schema )
        {
            load 'Test::Chado::Schema::Loader';
            return Test::Chado::Schema::Loader->connect(
                sub { return $self->dbmanager->dbh } );
        }
        else {
            my $schema = $self->schema;
            $schema->unregister_source('Sequence::Cvtermsynonym');
            return $schema;
        }
    }
);

has 'schema' => (
    is      => 'rw',
    isa     => BCS,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Bio::Chado::Schema->connect(
            sub { return $self->dbmanager->dbh } );
    }
);

has 'cvrow' => (
    is          => 'rw',
    isa         => HashiFied,
    handles_via => 'Data::Perl',
    builder     => 1,
    clearer     => 1,
    lazy        => 1,
    handles     => {
        get_cvrow   => 'get',
        set_cvrow   => 'set',
        exist_cvrow => 'defined'
    }
);

has 'dbrow' => (
    is          => 'rw',
    isa         => HashiFied,
    handles_via => 'Data::Perl',
    lazy        => 1,
    clearer     => 1,
    builder     => 1,
    handles     => {
        get_dbrow   => 'get',
        set_dbrow   => 'set',
        exist_dbrow => 'defined'
    }
);

has 'cvterm_row' => (
    is          => 'rw',
    isa         => HashiFied,
    lazy        => 1,
    default     => sub { return hash( () ); },
    handles_via => 'Data::Perl',
    handles     => {
        get_cvterm_row   => 'get',
        set_cvterm_row   => 'set',
        exist_cvterm_row => 'defined'
    }
);

sub _build_dbrow {
    my ($self) = @_;
    my %hash   = ();
    my $name   = $self->namespace . '-db';
    my $row    = $self->schema->resultset('General::Db')
        ->find_or_create( { name => $name } );
    $row->description('database namespace for test-chado fixture');
    $row->update;
    $hash{default} = $row;

    ## -- cache entries from database
    my $rs = $self->schema->resultset('General::Db')->search( {} );
    while ( my $dbrow = $rs->next ) {
        $hash{ $dbrow->name } = $dbrow
            if not defined $hash{ $dbrow->name };
    }
    return hash(%hash);
}

sub default_db_id {
    $_[0]->get_dbrow('default')->db_id;

}

sub find_db_id {
    my ( $self, $db ) = @_;
    return $self->get_dbrow($db)->db_id if $self->exist_dbrow($db);
}

sub find_or_create_db_id {
    my ( $self, $dbname ) = @_;
    my $schema = $self->schema;

    my $dbrow;
    ## -- check cache
    if ( $self->exist_dbrow($dbname) ) {
        $dbrow = $self->get_dbrow($dbname);
    }
    ## -- check database
    elsif ( $dbrow
        = $schema->resultset('General::Db')->find( { name => $dbname } ) )
    {
        $self->set_dbrow( $dbname, $dbrow );
    }
    ## -- create
    else {
        $dbrow = $schema->txn_do(
            sub {
                return $schema->resultset('General::Db')->create(
                    {   name => $dbname,
                        description =>
                            "db namespace for module-build-chado fixture"
                    }
                );
            }
        );
        $self->set_dbrow( $dbname, $dbrow );
    }
    return $dbrow->db_id;
}

sub _build_cvrow {
    my ($self)    = @_;
    my %hash      = ();
    my $namespace = $self->namespace . '-cv';
    my $cvrow     = $self->schema->resultset('Cv::Cv')
        ->find_or_create( { name => $namespace } );
    $cvrow->definition(
        'Ontology namespace for module-build-chado text fixture');
    $cvrow->update;
    $hash{default} = $cvrow;

    ## -- now create the cache if any
    my $cv_rs = $self->schema->resultset('Cv::Cv')->search( {} );
    while ( my $row = $cv_rs->next ) {
        $hash{ $row->name } = $row if not defined $hash{ $row->name };
    }
    return hash(%hash);
}

sub default_cv_id {
    $_[0]->get_cvrow('default')->cv_id;
}

sub find_cv_id {
    my ( $self, $cv ) = @_;
    $self->get_cvrow($cv)->cv_id if $self->exist_cvrow($cv);
}

sub find_or_create_cv_id {
    my ( $self, $namespace ) = @_;
    my $schema = $self->schema;

    my $cvrow;
    ## -- check in the cache
    if ( $self->exist_cvrow($namespace) ) {
        $cvrow = $self->get_cvrow($namespace);
    }
    ## -- check in the database
    elsif ( $cvrow
        = $schema->resultset('Cv::Cv')->find( { name => $namespace } ) )
    {
        $self->set_cvrow( $namespace, $cvrow );
    }
    ## -- create
    else {
        $cvrow = $schema->txn_do(
            sub {
                return $schema->resultset('Cv::Cv')->create(
                    {   name => $namespace,
                        definition =>
                            "Ontology namespace for module-build-chado fixture"
                    }
                );
            }
        );
        $self->set_cvrow( $namespace, $cvrow );
    }
    return $cvrow->cv_id;
}

sub find_or_create_cvterm_id {
    my ( $self, $cvterm, $cv, $db, $dbxref ) = @_;

    if ( $self->exist_cvterm_row($cvterm) ) {
        my $row = $self->get_cvterm_row($cvterm);
        return $row->cvterm_id if $row->cv->name eq $cv;
    }

    #otherwise try to retrieve from database
    my $cv_id
        = $cv
        ? $self->find_or_create_cv_id($cv)
        : $self->get_cvrow('default')->cv_id;

    my $rs = $self->schema->resultset('Cv::Cvterm')
        ->search( { 'name' => $cvterm, 'cv_id' => $cv_id }, );
    if ( $rs->count > 0 ) {
        $self->set_cvterm_row( $cvterm, $rs->first );
        return $rs->first->cvterm_id;
    }

    my $db_id
        = $db
        ? $self->find_or_create_db_id($db)
        : $self->get_dbrow('default')->db_id;

    #otherwise create one cvterm
    $dbxref ||= $cvterm;
    my $row = $self->schema->resultset('Cv::Cvterm')->create(
        {   name   => $cvterm,
            cv_id  => $cv_id,
            dbxref => {
                accession => $dbxref,
                db_id     => $db_id
            }
        }
    );
    $self->set_cvterm_row( $cvterm, $row );
    return $row->cvterm_id;
}

sub find_cvterm_id {
    my ( $self, $cvterm, $cv ) = @_;

    if ( $self->exist_cvterm_row($cvterm) ) {
        my $row = $self->get_cvterm_row($cvterm);
        if ($cv) {
            return $row->cvterm_id if $row->cv->name eq $cv;
        }
        else {
            return $row->cvterm_id;
        }
    }

    #otherwise try to retrieve from database
    my $rs
        = $cv
        ? $self->schema->resultset('Cv::Cvterm')
        ->search( { 'me.name' => $cvterm, 'cv.name' => $cv },
        { join => 'cv', cache => 1 } )
        : $self->schema->resultset('Cv::Cvterm')
        ->search( { 'name' => $cvterm, cache => 1 } );

    if ( $rs->count > 0 ) {
        $self->set_cvterm_row( $cvterm => $rs->first );
        return $rs->first->cvterm_id;
    }
}

sub search_cvterm_ids_by_namespace {
    my ( $self, $name ) = @_;

    if ( $self->exist_cvrow($name) ) {
        my $ids = [ map { $_->cvterm_id } $self->get_cvrow($name)->cvterms ];
        return $ids;
    }

    my $rs = $self->schema->resultset('Cv::Cv')->search( { name => $name } );
    if ( $rs->count > 0 ) {
        my $row = $rs->first;
        $self->set_cvrow( $name, $row );
        my $ids = [ map { $_->cvterm_id } $row->cvterms ];
        return $ids;
    }
    croak "the given cv namespace $name does not exist : create one\n";
}

1;    # Magic true value required at end of module

__END__

=pod

=head1 NAME

Test::Chado::Role::Helper::WithBcs

=head1 VERSION

version v4.1.1

=head1 DESCRIPTION

L<Bio::Chado::Schema> base Moo role to manage various db,  cv,  cvterm and dbxref values. This is primarilly consumed by various B<flatfile> based fixture loaders.

=head1 API

=head2 Attributes

=over

=item Handling L<Bio::Chado::Schema::Result::Cv> object

=over

=item get_cvrow(term name)

Gets an cached instances of L<Bio::Chado::Schema::Result::Cv>

=item set_cvrow(term name,L<Bio::Chado::Schema::Result::Cv>)

Cache an L<Bio::Chado::Schema::Result::Cv> object

=item exist_cvrow(term name)

Check for L<Bio::Chado::Schema::Result::Cv> in the cache

=back

=back

=over

=item Handling of L<Bio::Chado::Schema::Result::Cvterm>

=over

=item get_cvterm_row

=item set_cvterm_row

=item exist_cvterm_row

=back

=back

=over

=item Handling of L<Bio::Chado::Schema::Result::Db> 

=over

=item get_dbrow

=item set_dbrow

=item exist_dbrow

=back

=back

=over

=item dbmanager

Instance of L<Test::Chado::Role::Role::HasDBManager>

=item schema 

Instance of L<Bio::Chado::Schema>

=back

=head2 Methods

=over

=item find_cv_id(cv name)

Given a cv name returns cv_id column value from B<cv> table.

=item find_or_create_cv_id(cv name)

Similar to previous, however creates a cv if absent in the database.

=item find_cvterm_id

Similar to L<find_cv_id> method, however works on cvterm table to return the cvterm_id.

=item find_or_create_cvterm_id(cvterm,cv,db,dbxref)

Similar to previous L<find_or_create_cv_id> method, however needs few more parameters to work.

=item search_cvterm_ids_by_namespace(cv name)

Given a cv name returns a list(arrayref) of cvterm_ids

=item find_db_id(db name)

Given a db name returns a db_id from db table

=item find_or_create_db_id(db name)

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
