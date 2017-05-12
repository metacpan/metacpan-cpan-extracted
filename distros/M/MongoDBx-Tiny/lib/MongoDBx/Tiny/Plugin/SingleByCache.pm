package MongoDBx::Tiny::Plugin::SingleByCache;

use strict;
use warnings;

=head1 NAME

MongoDBx::Tiny::Plugin::SingleByCache - find via cache

=head1 SYNOPSIS

  # --------------------
  package Your::Data;
  use MongoDBx::Tiny;
  # ~ snip ~
  LOAD_PLUGIN   "SingleByCache";

  # --------------------

  $object = $tiny->single_by_cache('collection_name',{ query => 'value'});
  
  $object = $tiny->single_by_cache('collection_name',{ query => 'value'},
                                  { cache => $cache, cache_key => $key });

  #
  # $cache need to have get, set and delete method.
  # you can also set default $cache defining it as "tiny::get_cache"
  #


=cut

use Carp;
use Digest::SHA;

=head1 EXPORT

=cut

our @EXPORT = qw(single_by_cache single_by_cache_key);

=head2 single_by_cache

=cut

sub single_by_cache {
    my $self = shift;
    my ($c_name,$proto,$opt) = @_;
    my $cache = delete $opt->{cache};
    my $key   = delete $opt->{cache_key};

    if (!$cache && $self->can('get_cache')) {
	$cache  = $self->get_cache;
    } elsif (!$cache && ! $self->can('get_cache')){
	Carp::confess("get_cache is abstract method, define yours.");
    }

    if (!$cache->can('get') or !$cache->can('set')) {
	Carp::confess("invalid cache object: get and set methods are needed");
    }

    if (!$key) {
	$key = $self->single_by_cache_key($c_name,$proto);
    }
    my $document = $cache->get($key);
    if ($document) {
	return $self->document_to_object($c_name,$document);
    }
    my $object = $self->single($c_name,$proto);
    if (defined $object) {
	$cache->set($key,$object->object_to_document) or Carp::confess $!;
    }
    return $object;
}

=head2 single_by_cache_key

=cut

sub single_by_cache_key {
    my $self   = shift;
    my $c_name = shift;
    my $query  = shift;

    unless (ref $query eq 'HASH') {
	$query = { _id => "$query" };
    }

    my $key_str;
    while (my ($key,$value) = each %$query) {
	$key_str .= sprintf "%s::%s",$key,"$value";
    }
    return sprintf "%s::single_by_cache::%s::%s",
	ref $self,$c_name,Digest::SHA::sha1_hex($key_str);

}

1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

