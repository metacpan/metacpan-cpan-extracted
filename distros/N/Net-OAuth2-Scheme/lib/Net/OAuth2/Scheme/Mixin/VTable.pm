use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::VTable;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::VTable::VERSION = '0.03';
}
# ABSTRACT: the 'vtable', 'vtable_cache', and 'vtable_pull_queue' option groups

use Net::OAuth2::Scheme::Option::Defines;

#      parse_token
#        @token -> validator_id, @payload
#      vtable_lookup
#        validator_id -> @validator
#      validate
#        @validator, @payload -> valid?, issue_time, expires_in, scope, client_id

#   @token = (token_string [, param => value]*)
#   @validator = (@secrets [, expiration, scope, ext])
# Token scheme determines format of @secrets, @payload and @validator
# Expiration+@scope may live in either @payload or @validator
#
# What needs to be communicated/shared privately
# between Authorization and Resource servers
#    RS -> AS:  server_id
#    AS -> RS:  vtable == (secret_id -> expiration, @data) hash/map

# INTERFACE vtable
# DEFINES
# (AS) vtable_insert
# (RS) vtable_lookup
Define_Group vtable => 'shared_cache',
  qw(vtable_insert vtable_lookup);

# IMPLEMENTATION vtable_shared_cache FOR vtable
# SUMMARY
#   secure shared cache, everybody can read/write
# REQUIRES
#   vtable_cache
# NOTES
#   vtable_insert = vtable_put
#   vtable_lookup = vtable_get
#   this works for
#   (*) AS and RS being the same process
#   (*) AS and RS being on the same host
#       cache is file-based or shared-memory cache
#   (*) AS and RS are on the same server farm
#       cache is memcached
sub pkg_vtable_shared_cache {
    my __PACKAGE__ $self = shift;
    if ($self->is_auth_server) {
        $self->install( vtable_insert => $self->uses('vtable_put'));
    }
    if ($self->is_resource_server) {
        $self->install( vtable_lookup => $self->uses('vtable_get'));
    }
    return $self;
}

# IMPLEMENTATION vtable_authserv_push FOR vtable
# SUMMARY
#   RS-local cache with AS pushing each new entry
# REQUIRES
#   vtable_cache (+ (RS) vtable_put)
#   vtable_push(entry) => send entry
#   push handler => recv entry, vtable_pushed(entry)
# EXPORTS
#   vtable_pushed (for push handler)
# NOTES
#   vtable_insert = vtable_push
#   vtable_lookup = vtable_get
#   vtable_pushed = vtable_put

sub pkg_vtable_authserv_push {
    my __PACKAGE__ $self = shift;
    if ($self->is_auth_server) {
        $self->install( vtable_insert => $self->uses('vtable_push'));
    }
    if ($self->is_resource_server) {
        $self->install( vtable_lookup => $self->uses('vtable_get'));
        $self->install( vtable_pushed => $self->uses('vtable_put'));
        $self->export('vtable_pushed');
    }
    return $self;
}

# IMPLEMENTATION vtable_resource_pull FOR vtable
# SUMMARY
#   RS-local cache with RS pulling on cache miss
# REQUIRES
#   vtable_cache
#   vtable_pull_queue
#   vtable_pull => send query, return response
#   pull handler => recv query, respond vtable_dump(query)
# EXPORTS
#   vtable_dump  (for pull handler)
# NOTES
#   vtable_insert = vtable_enqueue
#   vtable_lookup is
#     vtable_get or
#     (vtable_load(vtable_pull(vtable_query)) and
#      retry vtable_get)

sub pkg_vtable_resource_pull {
    my __PACKAGE__ $self = shift;
    if ($self->is_auth_server) {
        $self->install( vtable_insert => $self->uses('vtable_enqueue'));
        $self->export('vtable_dump');
    }
    if ($self->is_resource_server) {
        my ( $vtable_get, $vtable_load, $vtable_query, $vtable_pull) = $self->uses_all
          (qw(vtable_get   vtable_load   vtable_query   vtable_pull));
        $self->install( vtable_lookup => sub {
            my $v_id = shift;
            my ($error, @found) = $vtable_get->($v_id);
            unless ($error || @found) {
                ($error) = $vtable_load->($vtable_pull->($vtable_query->()));
                return $error if $error;
                ($error,@found) = $vtable_get->($v_id);
            }
            return ($error, @found);
        });
    }
    return $self;
}

# INTERFACE vtable_cache
# DEFINES
#  vtable_put : id,expiration,@stuff ->;
#  vtable_get : id -> expiration,@stuff
Define_Group vtable_cache => 'object',
  qw(vtable_put vtable_get);


Default_Value cache_grace => 300;
Default_Value cache_prefix => 'vtab';

# vtable_cache_object
# IMPLEMENTS vtable_cache
# REQUIRES
#   cache => Cache::Memory, Cache::File, or Cache::Memcached object
# OPTIONS
#   cache_grace => number;
#     delay cache expiration by this many seconds (default = 300)
#   cache_prefix => string
#     keys are prefixed with this (default = 'vtab:')
sub pkg_vtable_cache_object {
    my __PACKAGE__ $self = shift;
    my ( $cache,     $grace,     $prefix) = $self->uses_all
      (qw(cache cache_grace cache_prefix));

    $prefix .= ':' if length($prefix) && $prefix !~ m/:\z/;
    $self->croak("cache_prefix ($prefix) cannot contain interior colon (:)")
        if length($prefix) && $prefix =~ m{:[^:]};

    $self->install( vtable_get => sub {
        my $v = $cache->thaw($prefix . $_[0]);
        return (undef, @{defined($v) ? $v : []});
    });
    $self->install( vtable_put => sub {
        my $id = shift;
        $cache->freeze($prefix . $id, [@_], $_[0] + $grace);
        return ();
    });
}

# INTERFACE vtable_pull_queue
# DEFINES
# (AS) vtable_enqueue
#      vtable_dump
# (RS) vtable_query
#      vtable_load
Define_Group vtable_pull_queue => 'default',
  qw(vtable_enqueue
     vtable_dump
     vtable_query
     vtable_load);

# default implementation
# REQUIRES
# (RS) vtable_put
sub pkg_vtable_pull_queue_default {
    my __PACKAGE__ $self = shift;
    if ($self->is_auth_server) {
        my $cache_grace = $self->uses('cache_grace');
        my $vpqueue = {};
        my $latest = [];

        $self->install( vtable_enqueue => sub {
            my ($v_id, $expiration, $now) = @_;

            # insert maintaining @$latest in order of increasing expiration
            my $i = $#{$latest};
            --$i while ($i >= 0 && $latest->[$i]->[1] > $expiration);
            splice @{$latest}, $i+1, 0, [@_];

            # prune expired entries from @$latest
            $i = 0;
            ++$i while ($i < @$latest && $latest->[$i]->[1] + $cache_grace < $now);
            splice @{$latest}, 0, $i;

            # prune expired entries from each batch of %$vpqueue
            for my $entries (values %{$vpqueue}) {
                $i = $#{$entries};
                --$i while ($i >= 0 && $entries->[$i]->[1] + $cache_grace < $now);
                splice @{$entries}, $i+1;
            }
            # remove empty batches from %$vpqueue
            delete @{$vpqueue}{grep {!@{$vpqueue->{$_}}} keys %{$vpqueue}};

            # never fails (?)
            return ();
        });

        $self->install( vtable_dump => sub {
            my ($now, $last_recv) = @_;
            # remove batches whose receipt has been acknowledged
            delete @{$vpqueue}{grep {$_ <= $last_recv} keys %$vpqueue};

            # insert @$latest entries into vpqueue
            if (@$latest) {
                unless (exists $vpqueue->{$now}) {
                    # make a new batch
                    $vpqueue->{$now} = [reverse @{$latest}];
                }
                else {
                    # merge into current batch; this should be rare
                    # and when it happens @$latest should be short
                    my $nqueue = $vpqueue->{$now};
                    for my $e (@{$latest}) {
                        my $i = 0;
                        ++$i while ($i < @{$nqueue} && $nqueue->[$i]->[1] > $e->[1]);
                        splice @{$nqueue}, $i, 0, $e;
                    }
                }
                $latest = [];
            }
            # send everything
            my @r = ();
            push @r, @$_ for values %{$vpqueue};
            return (undef, $now, \@r);
        });
    }
    if ($self->is_resource_server) {
        my $vtable_put = $self->uses('vtable_put');
        my $last_recv;
        $self->install( vtable_query => sub {
            my $now = time();
            return ($now, (defined($last_recv) && $now == $last_recv
                           ? $last_recv - 1 : $last_recv));
        });
        $self->install( vtable_load => sub {
            my ($error, $now, $recvd) = @_;
            return ($error) if $error;
            for my $entry (@$recvd) {
                $vtable_put->(@$entry);
            }
            $last_recv = $now;
            return (undef, scalar(@$recvd));
        });
    }
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::VTable - the 'vtable', 'vtable_cache', and 'vtable_pull_queue' option groups

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is an internal module that implements the abstract shared cache
for sharing secrets between authorization servers and resource
servers.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

