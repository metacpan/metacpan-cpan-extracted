package Mojolicious::Plugin::Alias;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';


our $VERSION = '0.0.4';

our $aliases = {};
our $saved_static_dispatcher;

sub aliases {
    my ($self) = @_;
    my %by_lengths = map { $_ => length $_ } keys %$aliases;
    my @aliases = sort { $by_lengths{$b} <=> $by_lengths{$a} } keys %$aliases;
    return @aliases;
}

sub alias {
    my $self  = shift;
    my $alias = shift;
    return unless ( $alias && $alias =~ m{^/.*} );
    if (@_ > 0) {
      my @args = (@_ == 1 && ! ref $_[0]) 
               ? (paths => [ @_ ])
               : @_ ;
      $aliases->{$alias} = Mojolicious::Static->new(@args);
    }
    if ($alias && exists $aliases->{$alias}) {
        return $aliases->{$alias};
    }
    return;
}

sub match {
    my ($self, $req_path) = @_;
    foreach my $alias ($self->aliases) {
        if ($req_path =~ /^$alias.*/) {
            # print STDERR "$req_path matches $alias";
            return $alias;
        }
    }
    return;
}


sub register {
    my ($self, $app, $conf) = @_;

    if ($conf) {
        while(my ($alias, $def) = each %$conf) {
           $self->alias($alias, $def);
        }
    };

    $app->hook(
        before_dispatch => sub {
            my ($c) = @_;
            my $req_path = $c->req->url->path;
            return unless (my $alias = $self->match($req_path));
            # rewrite req_path
            $req_path =~ s/^$alias//;
            $c->req->url->path($req_path);
            # change static
            my $dispatcher = $self->alias($alias);
            $saved_static_dispatcher = $c->app->static;
            $c->app->static($dispatcher);
            # Pushy? 
        } );
     $app->hook(
        after_static => sub {
            my ($c) = @_;
            if ($saved_static_dispatcher) {
                $c->app->static($saved_static_dispatcher);
                $saved_static_dispatcher = undef;
            }
        } );
}


1;
__END__

=head1 NAME

Mojolicious::Plugin::Alias - serve static files from aliased paths

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('alias', { '/images' => '/foo/bar/dir/images',
                             '/css' => '/here/docs/html/css' } );

    # Mojolicious::Lite
    plugin alias => { '/people/fry/photos' => '/data/foo/frang' };

    # statics embedded in __DATA__
    plugin alias => { '/people' => {classes => ['main']} };

    # multiple paths also possible
    plugin alias => { '/people/leela/photos' =>
        { paths => [
                     '/data/foo/zoop',
                     '/data/bar/public'
                   ] } };


=head1 DESCRIPTION

L<Mojolicious::Plugin::Alias> lets you map specific routes to collections
of static files. While by default a Mojolicious app will serve static files
located in any directory in the C<app->static->paths> array, 
L<Mojolicious::Plugin::Alias> will set up a seperate Mojolicious::Static
object to serve files according to the specified prefix in the URL path.

When developing with the stand-alone webserver, this module allows you to
mimic server paths that might be used in your templates.

=head1 CONFIGURATION

When installing the plugin, pass a reference to a hash of aliases (server
paths). The keys of the hash are URL path prefixes and must start with a '/'
( leading slash). The values of the hash can be either directory paths (a
single string) or hash references that will initialize L<Mojolicious::Static>
objects - they must have either C<paths> or C<classes> keys, with array reference
values.

=head1 AUTHOR

Dotan Dimet, C<dotan@corky.net>.

=head1 COPYRIGHT

Copyright (C) 2010,2014, Dotan Dimet.

=head1 LICENSE

Artistic 2.0

==head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
