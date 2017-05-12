package Objects::Collection::Memcached;

=head1 NAME

Objects::Collection::Memcached - class for collections of data, stored in Memcached.

=head1 SYNOPSIS

    use Objects::Collection::Memcached;
    use Cache::Memcached;
    $memd = new Cache::Memcached {
    'servers' => [ "127.0.0.1:11211" ],
    'debug' => 0,
    'compress_threshold' => 10_000,
  };
  $memd->set_compress_threshold(10_000);
  $memd->enable_compress(0);
  my $collection = new Objects::Collection::Memcached:: $memd;
  ...
  my $collection_prefix = new Objects::Collection::Memcached:: $memd, 'prefix';


=head1 DESCRIPTION

Class for collections of data, stored in Memcached.

=head1 METHODS

=head2 new <memcached object>[, <prefix>]

Creates a new Objects::Collection::Memcached object. Keys transparently autoprefixed with <prefix> if provided.

      my $collection_prefix = new Objects::Collection::Memcached:: $memd, 'prefix';


=cut

use Objects::Collection;
use Objects::Collection::Base;
use Data::Dumper;
use Objects::Collection::ActiveRecord;

use strict;
use warnings;

our @ISA     = qw(Objects::Collection);
our $VERSION = '0.01';

attributes qw/ _mem_cache _ns /;

sub _init {
    my $self = shift;
    my $memd = shift || return undef;
    if ( my $ns = shift ) {
        $self->_ns($ns);
    }
    $self->_mem_cache($memd);
    $self->SUPER::_init();
    return 1;
}

sub _delete {
    my $self = shift;
    my @ids  = map { $_->{id} } @_;
    my $memd = $self->_mem_cache;
    my $ns   = $self->_ns;
    if ( defined $ns ) {

        #auto prefix keys
        foreach my $id (@ids) {
            $id = $ns . $id;
        }
    }
    $memd->delete($_) for @ids;
}

sub _create {
    my $self    = shift;
    my %to_save = @_;
    my $memd    = $self->_mem_cache;
    my $ns      = $self->_ns;
    $ns = '' unless defined $ns;
    while ( my ( $key, $val ) = each %to_save ) {
        $memd->set( $ns . $key, $val );
    }
    return \%to_save;
}

sub _fetch {
    my $self = shift;
    my @ids  = map { $_->{id} } @_;
    my $ns   = $self->_ns;
    if ( defined $ns ) {

        #auto prefix keys
        foreach my $id (@ids) {
            $id = $ns . $id;
        }
    }
    my $memd = $self->_mem_cache;
    my $res  = $memd->get_multi(@ids);
    if ( defined $ns ) {
        my $tmp_res = {};
        my $ns_len  = length $ns;
        while ( my ( $keyns, $val ) = each %$res ) {
            my $key = substr( $keyns, $ns_len, length($keyns) - $ns_len );
            $tmp_res->{$key} = $val;
        }
        $res = $tmp_res;
    }
    $res;
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Objects::Collection::ActiveRecord', hash => $ref;
    return \%hash;
}

sub _store {
    my $self = shift;
    my $in   = shift;
    my $memd = $self->_mem_cache;
    my $ns   = $self->_ns;
    $ns = '' unless defined $ns;
    while ( my ( $key, $val ) = each %$in ) {
        $memd->set( $ns . $key, $val );
    }
}

sub commit {
    my $self = shift;
}

sub list_ids {
    my $self = shift;
    return [ keys %{ $self->_obj_cache() } ];
}

1;
__END__

=head1 SEE ALSO

Objects::Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

