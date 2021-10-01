package Mojo::Leds::Rest::MongoDB;
$Mojo::Leds::Rest::MongoDB::VERSION = '1.11';
use Mojo::Base 'Mojo::Leds::Rest';
use boolean;

use Scalar::Util qw(looks_like_number);
use BSON::OID;
use Tie::IxHash;

has pk       => '_id';
has f_search => 'find';
has f_table  => 'coll';

sub _create {
    my $c   = shift;
    my $rec = shift;
    my $res = $c->tableDB->insert_one($rec);
    if ( $res->acknowledged ) {
        $rec->{_id} = $res->inserted_id;
    }
    else {
        return $c->_raise_error( 'Element duplicated', 409 );
    }
    return $rec;
}

sub _rec2json() {
    my $c   = shift;
    my $rec = shift || $c->stash( $c->_class_name . '::record' );
    return $rec;
}

sub _patch {
    my $c   = shift;
    my $set = shift;

    my $id = shift || $c->restify->current_id;

    # remove id from updated fields
    delete $set->{ $c->pk };

    my $rec = $c->stash( $c->_class_name . '::record' );
    my $res = $c->tableDB->update_one(
        { $c->pk => $c->_oid($id) },
        { '$set' => $set },
    );

    return $c->_raise_error( 'Element not found', 404 )
      unless $res->matched_count;
    $rec = { %$rec, %$set };
    return $rec;
}

sub _update {
    my $c   = shift;
    my $set = shift;

    my $id = shift || $c->restify->current_id;

    # remove id from updated fields
    delete $set->{ $c->pk };

    my $rec = $c->stash( $c->_class_name . '::record' );
    my $res = $c->tableDB->replace_one( { $c->pk => $c->_oid($id) }, $set, );

    return $c->_raise_error( 'Element not found', 404 )
      unless $res->matched_count;
    return { $c->pk => $id, %$set };
}

sub _delete {
    my $c   = shift;
    my $rec = shift;
    $rec = $c->tableDB->find_one_and_delete( { $c->pk => $rec->{_id} } );
    return $rec;
}

sub _list {
    my ( $c, $rec, $qry, $opt, $rc ) = @_;

    my $recs = [$rec->all];
    if ($rc) {
        my $count =
          ( exists $opt->{limit} || exists $opt->{page} || exists $opt->{skip} )
          ? $c->tableDB->count_documents($qry)
          : scalar(@$recs);
        $recs = { count => $count, recs => $recs };
    }

    return $recs;
}

sub _listupdate {
    my $c    = shift;
    my $json = shift;

    my @recs;
    foreach my $item (@$json) {
        if ( exists $item->{ $c->pk } ) {
            $c->app->log->debug(
                'Update record ' . Data::Dumper::Dumper($item) );
            my $id  = $item->{ $c->pk };
            my $rec = $c->_update( $item, $id );
            push @recs, $rec;
        }
        else {
            $c->app->log->debug(
                'Create record ' . Data::Dumper::Dumper($item) );
            my $rec = $c->_create($item);
            push @recs, $rec;
        }
    }
    return @recs;
}

sub _qs2q {
    my $c   = shift;
    my $flt = $c->req->query_params->to_hash;
    my $qry = {};
    my $opt = {};
    my $rc  = 0;

    $opt->{sort} = new Tie::IxHash;

    # query string parse
    while ( my ( $k, $v ) = each %$flt ) {
        $v = $v + 0 if ( looks_like_number($v) );
        $v = undef  if ( $v eq '[null]' );
        for ($k) {

            # match exact filter
            if (/^q\[(.*?)\]/) {
                $c->_query_builder( \$qry, $1, $v, sub { return shift } );
            }

            # match regexp filter
            elsif (/^qre\[(.*?)\]/) {
                $c->_query_builder( \$qry, $1, $v,
                    sub { $a = shift; return qr/$a/i } );
            }

            # advanced sort
            elsif (/^sort\[(.*?)\]/) { $opt->{sort}->Push( $1 => $v ) }
            elsif ( $_ eq 'limit' )  { $opt->{limit} = $v }
            elsif ( $_ eq 'skip' )   { $opt->{skip} = $v }
            elsif ( $_ eq 'rc' )     { $rc = $v }
        }
    }

    # page here because i must have limit
    if ( defined $flt->{page} && defined $flt->{limit} ) {
        $opt->{skip} = $flt->{limit} * ( $flt->{page} - 1 );
    }

    # simple sort, needs sort and order
    if ( defined $flt->{sort} && defined $flt->{order} ) {
        $opt->{sort}->Push( $flt->{sort} => $flt->{order} eq 'asc' ? -1 : 1 );
    }

    $c->app->log->debug( 'Query url: '
          . Data::Dumper::Dumper($flt)
          . "\nSearch: "
          . Data::Dumper::Dumper($qry)
          . "\nOpt: "
          . Data::Dumper::Dumper($opt) );

    return ( $qry, $opt, $rc );
}

sub _query_builder {
    my ( $c, $qry, $k, $v, $func ) = @_;
    if ( ref($v) ne 'ARRAY' ) {
        $v = $c->_oid($v) if ( $k eq '_id' );
        if ( $v =~ /^(true)|(false)$/ ) {
            $v = $v eq 'true' ? true : false;
        }
        $$qry->{$k} = $func->($v);
    }
    else {
        $$qry->{'$or'} = [];
        foreach my $value (@$v) {
            if ( $value =~ /^(true)|(false)$/ ) {
                $value = $value eq 'true' ? true : false;
            }
            $value = $c->_oid($value) if ( $k eq '_id' );
            push @{ $$qry->{'$or'} }, { $k => $func->($value) };
        }
    }
}

sub _resource_lookup {
    my $c   = shift;
    my $id  = $c->restify->current_id;
    my $oid = $c->_oid($id);
    return unless ($oid);
    my $rec = $c->tableDB->find_one( { $c->pk => $oid } );
}

sub _oid {
    my $c  = shift;
    my $id = shift;

    # oid in {"$oid" : "012345678901234567890123"} format
    $id = $id->{'$oid'} if ( ref($id) eq 'HASH' && exists( $id->{'$oid'} ) );

    # convert to 12 byte packet
    $id = pack( "H*", $id );

    my $oid;
    eval { $oid = new BSON::OID( oid => $id ) };

    if ($@) {
        return $c->_raise_error( "ID '$id' is not valid", 400 );
    }
    return $oid;
}

1;

=pod

=head1 NAME

Mojo::Leds::Rest::MongoDB - A RESTFul interface to MongoDB

=head1 VERSION

version 1.11

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

# ABSTRACT: A RESTFul interface to MongoDB

