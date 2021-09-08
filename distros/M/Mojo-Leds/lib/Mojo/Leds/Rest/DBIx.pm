package Mojo::Leds::Rest::DBIx;
$Mojo::Leds::Rest::DBIx::VERSION = '1.08';
use Mojo::Base 'Mojo::Leds::Rest';

has pk       => 'id';
has dbHelper => 'schema';    # here dbHelper is schema

sub _create {
    my $c   = shift;
    my $rec = shift;
    $rec = $c->tableDB->create($rec);

    return $c->_raise_error( 'Element duplicated', 409 )
      unless ( $rec->in_storage );

    return $rec;
}

sub _rec2json() {
    my $c   = shift;
    my $rec = shift || $c->stash( $c->_class_name . '::record' );
    return { $rec->get_columns };
}

sub _patch {
    my $c   = shift;
    my $set = shift;

    delete $set->{ $c->pk };    # remove id from updated fields

    my $rec = $c->stash( $c->_class_name . '::record' );
    return $c->_raise_error( 'Element not found', 404 )
      unless $rec;
    $rec = $rec->update($set);

    return $rec;
}

sub _update {
    my $c   = shift;
    my $set = shift;

    my $id = shift || $c->restify->current_id;

    # remove id from updated fields
    my $pk = $c->pk;
    delete $set->{$pk};

    my $rec = $c->stash( $c->_class_name . '::record' );
    return $c->_raise_error( 'Element not found', 404 ) unless ($rec);

    # annullo tutti i campi
    $rec->$_(undef) foreach ( grep !/^${pk}$/, keys %{ $c->_rec2json } );
    while ( my ( $k, $v ) = each %$set ) {
        $rec->$k($v);
    }

    $rec->update;
    return $rec;
}

sub _delete {
    my $c   = shift;
    my $rec = shift;
    $rec->delete;
    return $rec;
}

sub _list {
    my ( $c, $rec, $qry, $opt, $rc ) = @_;

    my $recs = [];
    while ($_ = $rec->next) {
        push @$recs, $c->_rec2json($_);
    }
    if ($rc) {
        $recs = { count => $rec->pager->total_entries, recs => $recs };
    }

    return $recs;
}

sub _listupdate {
    my $c    = shift;
    my $json = shift;

    my @recs;
    foreach my $item (@$json) {
        my $rec = $c->tableDB->update_or_create($item);
        push @recs, $c->_rec2json($rec);
    }

    return @recs;
}

sub _qs2q {
    my $c   = shift;
    my $flt = $c->req->query_params->to_hash;
    my $qry = {};
    my $opt = {};
    my $rc  = 0;

    while ( my ( $k, $v ) = each %$flt ) {
        for ($k) {

            # match exact filter
            if (/^q\[(.*?)\]/) { $qry->{$1} = $v }

            # match regexp filter
            elsif (/^qre\[(.*?)\]/) {
                $qry->{$1} = { -like => $v };
            }

            # advanced sort
            elsif (/^sort\[(.*?)\]/) {
                my $order = $v == 1 ? '-asc' : '-desc';
                push @{ $opt->{'order_by'} }, { $order => $1 };
            }
            elsif ( $_ eq 'limit' ) { $opt->{rows}   = $v }
            elsif ( $_ eq 'skip' )  { $opt->{offset} = $v }
            elsif ( $_ eq 'rc' )    { $rc            = $v }
            elsif ( $_ eq 'page' )  { $opt->{page}   = $v }
        }
        $opt->{page} //= 1;
    }

    $c->app->log->debug( 'Query url: '
          . Data::Dumper::Dumper($flt)
          . "\nDBIx search: "
          . Data::Dumper::Dumper($qry)
          . "\nDBIx opt: "
          . Data::Dumper::Dumper($opt) );

    return ( $qry, $opt, $rc );
}

sub _resource_lookup {
    my $c  = shift;
    my $id = $c->restify->current_id;
    return $c->tableDB->single( { $c->pk => $id } );
}

1;

=pod

=head1 NAME

Mojo::Leds::Rest::DBIx - A RESTFul interface to Class::DBIx

=head1 VERSION

version 1.08

=head1 SYNOPSIS

=head1 DESCRIPTION

=encoding UTF-8

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A RESTFul interface to Class::DBIx

