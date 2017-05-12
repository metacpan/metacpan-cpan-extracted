package Mojolicious::Plugin::Cache::Action;

BEGIN {
    $Mojolicious::Plugin::Cache::Action::VERSION = '0.0015';
}

use strict;
use warnings;
use CHI;
use Carp;
use base qw/Mojolicious::Plugin/;

# Module implementation
#

my $cache;
my $actions;

__PACKAGE__->attr( 'driver' => 'Memory' );

sub register {
    my ( $self, $app, $conf ) = @_;

    if ( defined $conf->{actions} ) {
        $actions = { map { $_ => 1 } @{ $conf->{actions} } };
    }

    #setup cache
    if ( !$cache ) {
        if ( defined $conf->{options} ) {
            my $opt = $conf->{options};
            $opt->{driver} = $self->driver if not defined $opt->{driver};
            $cache = CHI->new(%$opt);
        }
        else {
            $cache = CHI->new( driver => $self->driver );
        }
    }

    if ( $app->log->level eq 'debug' ) {
        $cache->on_set_error('log');
        $cache->on_get_error('log');
    }

    $app->plugins->add_hook(
        'before_dispatch' => sub {
            my ( $self, $c ) = @_;
            my $path = $c->tx->req->url->to_abs->to_string;
            $app->log->debug( ref $path );
            if ( $cache->is_valid($path) ) {
                $app->log->debug("serving from cache for $path");
                my $data = $cache->get($path);
                $c->res->code( $data->{code} );
                $c->res->headers( $data->{headers} );
                $c->res->body( $data->{body} );
                $c->stash( 'from_cache' => 1 );
            }
        }
    );

    $app->plugins->add_hook(
        'after_dispatch' => sub {
            my ( $self, $c ) = @_;

            #conditions at which no caching will be done
            ## - it is already a cached response
            return if $c->stash('from_cache');

            ## - has to be GET request
            return if $c->req->method ne 'GET';

            ## - only successful response
            return if $c->res->code != 200;

            my $path = $c->req->url->to_abs->to_string;
            my $name = $c->stash('action');

            ## - have to match the action
            return
                if defined $conf->{actions}
                    and not exists $actions->{$name};

            $app->log->debug("storing in cache for $path and action $name");
            $cache->set(
                $path,
                {   body    => $c->res->body,
                    headers => $c->res->headers,
                    code    => $c->res->code
                }
            );
        }
    );

    return;
}

1;

# ABSTRACT: Action caching plugin

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Cache::Action - Action caching plugin

=head1 VERSION

version 0.0015

=head1 SYNOPSIS

Mojolicious:

 $self->plugin('cache-action');

Mojolicious::Lite:

 plugin 'cache-action';

=head1 DESCRIPTION

This plugin caches responses of mojolicious applications. It works by caching the entire
output of controller action for every request. Action caching internally uses
the I<before_dispatch> hook to serve the response from cache by skipping the entire
controller body. Uncached responses are cached in an I<after_dispatch> hook. 

The cache is named according to the current host and path. So,  the cache will
differentiate between an identical page that is accessed from B<tucker.myplace.com/user/2>
and from B<caboose.myplace.com/user/2> 
Different representation of the same resource such as B<tucker.myplace.com/book/list> and
B<tucker.myplace.com/book/list.json> are considered as separate requests and so are
cached separately.

=head2 Cache backends 

This plugin uses L<CHI|http://search.cpan.org/~jswartz/CHI> for caching responses.
So,  all the various cache backends and customization options of B<CHI> are supported. By
default,  this plugin uses the 
L<Memory|http://search.cpan.org/~jswartz/CHI-0.36/lib/CHI/Driver/Memory.pm> cache backend.
Various other backends 

=over

=item *  

L<File|http://search.cpan.org/~jswartz/CHI-0.36/lib/CHI/Driver/File.pm> 

=item *

L<FastMmap|http://search.cpan.org/~jswartz/CHI-0.36/lib/CHI/Driver/FastMmap.pm>

=item *

L<Memcached|http://search.cpan.org/~jswartz/CHI-Driver-Memcached-0.12/lib/CHI/Driver/Memcached.pm>

=item *

L<BerkleyDB|http://search.cpan.org/~jswartz/CHI-Driver-BerkeleyDB-0.03/lib/CHI/Driver/BerkeleyDB.pm>

=back

are also available through CHI.

=head2 Options

=over

=item actions

 actions => [qw/action1 action2 ....]

 #Mojolicious::Lite 
 plugin cache-action => { actions => [qw/user show/]}; 


 #Mojolicious
 $self->plugin('cache-action' => { actions => [qw/user show/]});

 By default,  all actions with successful GET requests will be cached

=item options

  options =>  \%options
  All CHI module options are recognized

  #Mojolicious lite using memcache 
  plugin cache-action => {
       options => {
       driver => 'Memcached',  
       servers => [ "10.0.0.15:11211",  "10.0.0.15:11212" ] 
     }
  } 

  #Mojolicious lite using file based storage
  plugin cache-action => {
       options => {
       driver => 'File',  
       root_dir => '/path/to/cache' 
     }
  } 

  #Mojolicious using file based storage
  $self->plugin('cache-action' => { options => 
        { 
          driver => 'File',  
          root_dir => '/path/to/cache' 
        }
  });

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
