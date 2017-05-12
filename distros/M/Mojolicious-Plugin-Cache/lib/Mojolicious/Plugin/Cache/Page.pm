package Mojolicious::Plugin::Cache::Page;

BEGIN {
    $Mojolicious::Plugin::Cache::Page::VERSION = '0.0015';
}

use strict;
use Carp;
use File::Path qw/make_path/;
use File::Spec::Functions;
use base qw/Mojolicious::Plugin/;

# Module implementation
#

sub register {
    my ( $self, $app, $conf ) = @_;

    my $home = $app->home;
    my $cache_dir
        = -e $app->home->rel_dir('public')
        ? $app->home->rel_dir('public')
        : $home->to_string;

    #if given as an option
    if ( defined $conf->{cache_directory} ) {
        $cache_dir = $conf->{cache_directory};
    }

    my $actions;
    if ( defined $conf->{actions} ) {
        $actions = { map { $_ => 1 } @{ $conf->{actions} } };
    }

    $app->plugins->add_hook(
        'after_dispatch' => sub {
            my ( $self, $c ) = @_;

            ## - has to be GET request
            return if $c->req->method ne 'GET';

            ## - only successful response
            return if $c->res->code != 200;

            ## - only html response
            return if $c->res->headers->content_type !~ /^text\/html/;

            ## - have to match the action
            my $name = $c->stash('action');
            return
                if defined $conf->{actions}
                    and not exists $actions->{$name};

            my $parts = $c->req->url->path->parts;
            my $file_name;
            if ( @$parts == 1 ) {
                $file_name = catfile( $cache_dir, $parts->[0] . '.html' );
            }
            else {
                my $end    = pop @$parts;
                my $folder = $cache_dir;
                $folder = catdir( $folder, $_ ) for @$parts;
                make_path($folder);
                $file_name = catfile( $folder, $end . '.html' );
            }

            $app->log->debug(
                "storing in cache for action **$name** in file $file_name");

            my $handler = IO::File->new( $file_name, 'w' )
                or croak "cannot create file:$!";
            $handler->print( $c->res->body );
            $handler->close;
        }
    );
    return;
}

1;

# ABSTRACT: Page caching plugin

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Cache::Page - Page caching plugin

=head1 VERSION

version 0.0015

=head1 SYNOPSIS

Mojolicious:

 $self->plugin('cache-page');

Mojolicious::Lite:

 plugin 'cache-page';

=head1 DESCRIPTION

This plugin caches the entire output of controller action in a HTML file which can be
delivered directly by the webserver without even going through the controller at all. The
cache will generate files for example user/2/view.html,  user/new.html etc which matches
the request urls. The webserver picks up the existing file by matching the path otherwise
it gets passed to the mojolicious controller.

The cache is named according to path and so the cache will not differentiate between 
an identical page that is accessed from B<tucker.myplace.com/user/2/view.html>
and from B<caboose.myplace.com/user/2/view.html>. This caching system ignores the query
parameters. So,  for example /users?page=1 will be cached as users.html and so another
call to /users?page=2 will retrieve the users.html. The cache is expired by deleting the
html file that defered it creation until a new request comes in. 

=head2 Options

=over

=item actions

 actions => [qw/action1 action2 ....]

 #Mojolicious::Lite 
 plugin cache-page => { actions => [qw/user show/]}; 

 By default,  all actions with successful GET requests will be cached

=item cache_directory

  By default, for mojolicious lite application the current working directory is set for
  page caching. For mojolicious application it is set to the B<public> folder. 

  #Mojolicious lite using memcache 
  plugin cache-page => { cache_direcotry => '/home/page_cache' }; 

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
