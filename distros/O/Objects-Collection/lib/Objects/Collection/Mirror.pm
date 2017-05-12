package Objects::Collection::Mirror;

=head1 NAME

 Objects::Collection::Mirror -  Mirror of two collections.

=head1 SYNOPSIS

    use Objects::Collection::Mirror;
     my $coll1 = ( new Collection::Mem:: mem => \%h1 );# fast but nonstable source ( Memcached )
     my $coll2 = ( new Collection::Mem:: mem => \%h2 );# slow but stable source ( database )

     my $mirror_coll1 =  new Objects::Collection::Mirror:: $coll1, $coll2 ;


=head1 DESCRIPTION

Mirror two collections.

 
=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Test::More;
require Tie::Hash;
use Objects::Collection;
@Objects::Collection::Mirror::ISA     = qw(Objects::Collection);
$Objects::Collection::Mirror::VERSION = '0.01';

__PACKAGE__->attributes qw( _c1 _c2 _stack);

sub Init {
    my ( $self, $c1, $c2 ) = @_;
    _c1 $self $c1;
    _c2 $self $c2;
    $self->_stack( [ $c1, $c2 ] );
    return 1;
}

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    return $self->Init(@_);
}

=head2 _fetch

Fetch keys from collection1. And then from collection2

=cut

sub _fetch {
    my $self = shift;

    #collect ids to fetch
    my @ids = map { $_->{id} } @_;
    return {} unless @ids;    #skip empty ids list
    my ( $c1, $c2 ) = @{ $self->_stack };

    #read keys from first collection
    my $res1     = $c1->fetch_objects(@_);
    my @notfound = ();
    foreach my $key (@ids) {
        push @notfound, $key unless exists $res1->{$key};
    }
    if (@notfound) {

        #if we not found some keys, then fetch from coll2
        #and store to coll1
        #        diag "Fetch non exists in col1".Dumper (\@notfound);
        my $res2        = $c2->fetch_objects(@notfound);
        my %create_keys = ();
        foreach my $k1 (@notfound) {
            next unless exists $res2->{$k1};    #skip real nonexists keys
            my $value = $res2->{$k1};

            #save for create
            $create_keys{$k1} = $value;
        }
        if ( keys %create_keys ) {

            #            diag "create". Dumper (\%create_keys);
            #store only simply results
            #now store to coll1
            my $created = $c1->create( \%create_keys );
            while ( my ( $k2, $v2 ) = each %$created ) {
                $res1->{$k2} = $v2;
            }
        }
    }

    #    diag "try " . Dumper( \@_ );
    #    diag "Diff two keys" . Dumper [ \@keys1, \@keys2 ];
    return $res1;
}

=head2 _create

create items

=cut

sub _create {
    my $self = shift;
    my ( $c1, $c2 ) = @{ $self->_stack };
    return $c2->create(@_);
}

=head2 _store

=cut

sub _store {
    my $self = shift;
    my ( $c1, $c2 ) = @{ $self->_stack };
    my $hash2store = shift;
    my @ids2store  = keys %$hash2store;
    my $coll2res   = $c2->fetch_objects(@ids2store);

    #and create new in col2
    #create non exists keys on c2
    my %tocreate = ();
    while ( my ( $key, $val ) = each %$hash2store ) {
        if ( exists $coll2res->{$key} ) {
            my $value = $coll2res->{$key};

            #mirror only HASHes
            if ( ref($value) eq 'HASH' ) {

                #use value as hash
                %$value = %$val;
            }
        }
        else {
            $tocreate{$key} = $val;
        }
    }
    if ( keys %tocreate ) {
        $c2->create( \%tocreate );
    }

    #now mirroring changed data
    #mirror coll1 to coll2
    while ( my ( $key, $val ) = each %$hash2store ) {
        next unless exists $coll2res->{$key};

    }
    # changed items we also mirror to coll2
    $c1->store_changed(@ids2store);
    $c2->store_changed(@ids2store);
    return;
}

=head2 list_ids

Return  union of keys from collection1 and collection2

=cut

sub list_ids {
    my $self = shift;
    my ( $c1, $c2 ) = @{ $self->_stack };
    my %uniq = ();
    @uniq{ @{ $c1->list_ids }, @{ $c2->list_ids } } = ();
    return [ keys %uniq ];
}

sub _delete {
    my $self = shift;
    my ( $c1, $c2 ) = @{ $self->_stack };
    for ( $c1, $c2 ) {
        $_->delete_objects(@_)
    }
}
1;
__END__


=head1 SEE ALSO

Tie::StdHash

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

