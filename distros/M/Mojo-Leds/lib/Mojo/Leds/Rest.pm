package Mojo::Leds::Rest;
$Mojo::Leds::Rest::VERSION = '1.07';
use Mojo::Base 'Mojo::Leds::Page';
use Mojo::Util qw(decamelize class_to_path);
use Mojo::JSON qw(decode_json);

has table => sub {
    return decamelize(
        ( split( /\//, class_to_path( ref shift ) ) )[-1] =~ s/\.pm$//r );
};
has pk       => 'id';
has ro       => 0;
has dbHelper => 'db';
has f_search => 'search';
has f_table  => 'resultset';

sub create {
    my $c = shift;
    return $c->_raise_error( "Resource is read-only", 403 ) if $c->ro;
    my $rec = $c->_json_from_body;
    return unless ($rec);
    $rec = $c->_create($rec);
    return unless ($rec);
    $c->render_json( $c->_rec2json($rec) );
}

sub delete {
    my $c = shift;
    return $c->_raise_error( "Resource is read-only", 403 ) if $c->ro;
    my $rec = $c->stash( $c->_class_name . '::record' );
    return $c->_raise_error( 'Element not found', 404 ) unless $rec;
    $c->_delete($rec);
    $c->render_json( undef, 204 );
}

sub list {
    my $c     = shift;
    my $query = $c->param('query');
    return $c->$query(@_) if ($query);

    my ( $qry, $opt, $rc ) = $c->_qs2q;
    my $rec  = $c->searchDB( $qry, $opt );
    my $recs = $c->_list( $rec, $qry, $opt, $rc );

    $c->render_json($recs);
}

sub listupdate {
    my $c = shift;
    return $c->_raise_error( "Resource is read-only", 403 ) if $c->ro;
    my $json = $c->_json_from_body;
    return unless ($json);

    # json deve essere un array
    return $c->_raise_error( 'Not an array of records', 422 )
      unless ( ref($json) eq 'ARRAY' );

    my @recs = $c->_listupdate($json);

    $c->render_json( \@recs );
}

sub patch {
    my $c = shift;
    return $c->_raise_error( "Resource is read-only", 403 ) if $c->ro;
    my $json = $c->_json_from_body;
    return unless ($json);
    my $rec = $c->_patch($json);
    return unless ($rec);
    $c->render_json( $c->_rec2json($rec) );
}

sub read {
    my $c = shift;
    $c->render_json( $c->_rec2json );
}

sub render_json {
    my $c      = shift;
    my $json   = shift;
    my $status = shift || 200;
    $c->render( json => $json, status => $status );
}

sub resource_lookup {
    my $c   = shift;
    my $rec = $c->_resource_lookup;
    $rec || return $c->_raise_error( 'Element not found', 404 );
    $c->stash( $c->_class_name . '::record' => $rec );
    return $rec;
}

sub searchDB {
    my $c   = shift;
    my $qry = shift;
    my $opt = shift;

    my $f_search = $c->f_search;
    return $c->tableDB->$f_search( $qry, $opt );
}

sub tableDB {
    my $c       = shift;
    my $helper  = $c->dbHelper;
    my $f_table = $c->f_table;
    return $c->helpers->$helper->$f_table( $c->table );
}

sub update {
    my $c = shift;
    return $c->_raise_error( "Resource is read-only", 403 ) if $c->ro;
    my $json = $c->_json_from_body;
    return unless ($json);
    my $rec = $c->_update($json);
    return unless ($rec);
    $c->render_json( $c->_rec2json($rec) );
}

sub _class_name {
    return ref shift;
}

sub _json_from_body {
    my $c       = shift;
    my $content = $c->req->body;
    my $json;
    eval { $json = decode_json $content};
    if ($@) {
        $@ =~ s/\sat\s\/(.*?)\n$//g;
        return $c->_raise_error( $@, 400 );
    }
    return $json;
}

sub _raise_error {
    my $c      = shift;
    my $txt    = shift;
    my $status = shift || 400;
    $c->render_json(
        {
            status  => $status,
            message => $txt
        },
        $status
    );
    return undef;
}

1;

=pod

=head1 NAME

Mojo::Leds::Rest - Abstract class for RESTFul webservices interface

=head1 VERSION

version 1.07

=head1 RESTFul API

=head2 create

    PUT /url/

create a new record

B<Parameters:>

=over 4

=item *

body JSON - C<{col1: ..., col2:... }>

=back

B<Return>:

=over 4

=item *

Created record in JSON C<{_id:...., col1:. ...., }>

=back

=head2 read

    GET /url/id

return a single record with _id: id

B<Parameters:>

=over 4

=item *

None

=back

B<Return>:

=over 4

=item *

Record found in JSON C<{_id:...., col1:. ...., }>

=back

=head2 update

    PUT /url/id

update a single record

B<Parameters:>

=over 4

=item *

body JSON - C<{_id:...., col1: new_value, col2: new_value,  }>

=back

B<Return>:

=over 4

=item *

Updated record in JSON C<{_id:...., col1:. ...., }>

=back

=head2 delete

    DELETE /url/id

delete a record

B<Parameters:>

=over 4

=item *

None

=back

B<Return>:

=over 4

=item *

Empty body

=item *

HTTP Status: C<204 No Content>

=back

=head2 list

    GET /url/

return all records

B<Parameters:>

=over 4

=item *

None

=back

B<Return>:

=over 4

=item *

All records in JSON array: C<[ {_id:...., }, {_id:...., }, ...} ]>

=back

=head2 listupdate

    POST /url/

update/creare multi records. Record with _id is updated, record without _id is created.

B<Parameters:>

=over 4

=item *

body JSON array:  C<[ {col1,... }, {_id:...., col1: new_value, col2: new_value,  } ]>

=back

B<Return>:

=over 4

=item *

Created/ Updated record in JSON C<[{_id:...., col1:. ...., }, ...]>

=back

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Abstract class for RESTFul webservices interface

