use 5.14.0;
package Router::Dumb::Helper::FileMapper 0.006;
use Moose;
# ABSTRACT: something to build routes out of a dumb tree of files

use File::Find::Rule;
use Router::Dumb::Route;

use Moose::Util::TypeConstraints qw(find_type_constraint);

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod The FileMapper helper looks over a tree of files and adds routes to a
#pod L<Router::Dumb> object based on those files.
#pod
#pod For example, imagine the following file hierarchy:
#pod
#pod   templates
#pod   templates/pages
#pod   templates/pages/help
#pod   templates/pages/images
#pod   templates/pages/images/INDEX
#pod   templates/pages/INDEX
#pod   templates/pages/legal
#pod   templates/pages/legal/privacy
#pod   templates/pages/legal/tos
#pod
#pod With the following code...
#pod
#pod   use Path::Class qw(dir);
#pod
#pod   my $r = Router::Dumb->new;
#pod
#pod   Router::Dumb::Helper::FileMapper->new({
#pod     root => 'templates/pages',
#pod     target_munger => sub {
#pod       my ($self, $filename) = @_;
#pod       dir('pages')->file( file($filename)->relative($self->root) )
#pod                   ->stringify;
#pod     },
#pod   })->add_routes_to($r);
#pod
#pod ...the router will have a route so that:
#pod
#pod   $r->route( '/legal/privacy' )->target eq 'pages/legal/privacy';
#pod
#pod These routes never have placeholders, and if files in the tree have colons at
#pod the beginning of their names, an exception will be thrown.  Similarly, slurpy
#pod routes will never be added, and files named C<*> are forbidden.
#pod
#pod Files named F<INDEX> are special:  they cause a route for the directory's name
#pod to exist.
#pod
#pod =cut

#pod =attr root
#pod
#pod This is the name of the root directory to scan when adding routes.
#pod
#pod =cut

has root => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr target_munger
#pod
#pod This attribute (which has a default no-op value) must be a coderef.  It is
#pod called like a method, with the first non-self argument being the file
#pod responsible for the route.  It should return the target for the route to be
#pod added.
#pod
#pod =cut

has target_munger => (
  reader  => '_target_munger',
  isa     => 'CodeRef',
  default => sub {  sub { $_[1] }  },
);

#pod =attr parts_munger
#pod
#pod This attribute (which has a default no-op value) must be a coderef.  It is
#pod called like a method, with the first non-self argument being an arrayref of the
#pod path components of the file responsible for the route.  It should return the
#pod parts for the route to be added.
#pod
#pod =cut

has parts_munger => (
  reader  => '_parts_munger',
  isa     => 'CodeRef',
  default => sub {  sub { $_[1] }  },
);

#pod =method add_routes_to
#pod
#pod   $helper->add_routes_to( $router, \%arg );
#pod
#pod This message tells the helper to scan its directory root and add routes to the
#pod given router.  The helper can be used over and over.
#pod
#pod Valid arguments are:
#pod
#pod   ignore_conflicts - if true, trying adding an existing route will be ignored,
#pod                      rather than fail
#pod
#pod =cut

sub add_routes_to {
  my ($self, $router, $arg) = @_;
  $arg ||= {};

  my $dir = $self->root;
  my @files = File::Find::Rule->file->in($dir);

  my $add_method = $arg->{ignore_conflicts}
                 ? 'add_route_unless_exists'
                 : 'add_route';

  for my $file (@files) {
    my $path = $file =~ s{/INDEX$}{/}gr;
    $path =~ s{$dir}{};
    $path =~ s{^/}{};

    my @parts = split m{/}, $path;

    confess "can't use placeholder-like name in route files"
      if grep {; /^:/ } @parts;

    confess "can't use asterisk in file names" if grep {; $_ eq '*' } @parts;

    my $route = Router::Dumb::Route->new({
      parts  => $self->_parts_munger->( $self, \@parts ),
      target => $self->_target_munger->( $self, $file ),
    });

    $router->$add_method($route);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Dumb::Helper::FileMapper - something to build routes out of a dumb tree of files

=head1 VERSION

version 0.006

=head1 OVERVIEW

The FileMapper helper looks over a tree of files and adds routes to a
L<Router::Dumb> object based on those files.

For example, imagine the following file hierarchy:

  templates
  templates/pages
  templates/pages/help
  templates/pages/images
  templates/pages/images/INDEX
  templates/pages/INDEX
  templates/pages/legal
  templates/pages/legal/privacy
  templates/pages/legal/tos

With the following code...

  use Path::Class qw(dir);

  my $r = Router::Dumb->new;

  Router::Dumb::Helper::FileMapper->new({
    root => 'templates/pages',
    target_munger => sub {
      my ($self, $filename) = @_;
      dir('pages')->file( file($filename)->relative($self->root) )
                  ->stringify;
    },
  })->add_routes_to($r);

...the router will have a route so that:

  $r->route( '/legal/privacy' )->target eq 'pages/legal/privacy';

These routes never have placeholders, and if files in the tree have colons at
the beginning of their names, an exception will be thrown.  Similarly, slurpy
routes will never be added, and files named C<*> are forbidden.

Files named F<INDEX> are special:  they cause a route for the directory's name
to exist.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 root

This is the name of the root directory to scan when adding routes.

=head2 target_munger

This attribute (which has a default no-op value) must be a coderef.  It is
called like a method, with the first non-self argument being the file
responsible for the route.  It should return the target for the route to be
added.

=head2 parts_munger

This attribute (which has a default no-op value) must be a coderef.  It is
called like a method, with the first non-self argument being an arrayref of the
path components of the file responsible for the route.  It should return the
parts for the route to be added.

=head1 METHODS

=head2 add_routes_to

  $helper->add_routes_to( $router, \%arg );

This message tells the helper to scan its directory root and add routes to the
given router.  The helper can be used over and over.

Valid arguments are:

  ignore_conflicts - if true, trying adding an existing route will be ignored,
                     rather than fail

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
