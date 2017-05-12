package Path::Resource;

use warnings;
use strict;

=head1 NAME

Path::Resource - URI/Path::Class combination

=head1 VERSION

Version 0.072

=head1 SYNOPSIS

  use Path::Resource;

  # Map a resource on the local disk to a URI.
  # Its (disk) directory is "/var/dir" and its uri is "http://hostname/loc"
  my $rsc = new Path::Resource dir => "/var/dir", uri => "http://hostname/loc";
  # uri: http://hostname/loc 
  # dir: /var/dir

  my $apple_rsc = $rsc->child("apple");
  # uri: http://hostname/loc/apple
  # dir: /var/dir/apple

  my $banana_txt_rsc = $apple_rsc->child("banana.txt");
  # uri: http://hostname/loc/apple/banana.txt
  # file: /var/dir/apple/banana.txt

  my $size = -s $banana_txt_rsc->file;

  redirect($banana_txt_rsc->uri);
  # Redirect to "http://hostname/loc/apple/banana.txt"

=head1 DESCRIPTION

Path::Resource is a module for combining local file and directory manipulation with URI manipulation. It allows you to
effortlessly map local file locations to their URI equivalent.

It combines Path::Class and URI into one object.

Given a base Path::Resource, you can descend (using ->child) or ascend (using ->parent) the path tree while maintaining
URI equivalency, all in one object. 

As a convenience, if you do not need the full URI, you can use the ->loc method to just return the URI path.

=cut

our $VERSION = '0.072';

use Path::Class();
use Path::Resource::Base();
use Path::Abstract;
use Scalar::Util qw/blessed/;
use Carp;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw(_path base));

=head1 METHODS 

=over 4

=item $rsc = Path::Resource->new

=item $rsc = Path::Resource->new( dir => $dir, uri => $uri, [ path => $path ] )

Create and return a new Path::Resource object using $dir as the base dir and $uri as the base uri.

The URI path of $uri will be automatically extracted and used as the base loc.

If $path is given, then the $rsc will start at that point on the path.

    # For example, if the following $rsc is created like so:
    my $rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", path => "xyzzy");

    my $dir = $rsc->dir; # The dir "/home/b/htdocs/xyzzy"
    my $uri = $rsc->uri; # The uri "http://example.com/a/xyzzy"

    # Note that path doesn't have to be a dir.
    # You can give it a file path if you like (Path::Resource doesn't care)
    $rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", path => "xyzzy/nothing.txt");

    my $file = $rsc->file; # The file "/home/b/htdocs/xyzzy/nothing.txt"
    $uri = $rsc->uri; # The uri "http://example.com/a/xyzzy/nothing.txt"

=item $rsc = Path::Resource->new( dir => $dir, uri => $uri, loc => $loc, [ path => $path ] )

Create and return a new Path::Resource object using $dir as the base dir, $uri as the base uri, and
using $loc as the base loc (the uri path).

If $loc is relative, then it will be appended to $uri->path, otherwise (being absolute) it will replace $uri->path.

If $path is given, then the $rsc will start at that point on the path.

    # For example, if the following $rsc is created like so:
    my $rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", loc => "c");

    my $dir = $rsc->dir; # The dir "/home/b/htdocs"
    my $uri = $rsc->uri; # The uri "http://example.com/a/c"

    # On the other hand:
    $rsc = Path::Resource->new(uri => "http://example.com/a", dir => "/home/b/htdocs", loc => "/g/h");

    $dir = $rsc->dir; # The dir "/home/b/htdocs"
    $uri = $rsc->uri; # The uri "http://example.com/g/h

=item $rsc = Path::Resource->new( file => $file, dir => $dir, uri => $uri, [ loc => $loc, path => $path ] )

Create and return a new Path::Resource object using $dir as the base dir, $uri as the base uri, and
the difference between $file and $dir as the path (literally: $path = $file->relative($dir))

If $loc is given then if it is relative, then it will be appended to $uri->path, otherwise (being absolute) it will replace $uri->path.

=cut

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my $dir = $_{dir};
	my $file = $_{file};
	my $path = $_{path};
	my $loc = $_{loc};
	my $uri = $_{uri};

	my $base;
	if ($base = $_{base}) {
        # Use supplied base object
        croak "\$base ($base) is not of Path::Resource::Base" unless $base->isa("Path::Resource::Base");
	}
	else {
        # Make a new base object from @_
		if ($dir && $file && $path) {
			croak "Can't initialize a dir ($dir), a file ($file), and a path ($path) at the same time"
		}
		elsif ($dir && $file) {
            # We were given a dir and file, so keep the dir and determine the path by finding difference between the two.
			$dir = Path::Class::dir($dir) unless blessed $dir && $dir->isa("Path::Class::Dir");
			$file = Path::Class::file($file) unless blessed $file && $file->isa("Path::Class::File");
			croak "Can't initialize since dir ($dir) does not contain file ($file) unless $dir->subsumes($file)";
			$path = $file->relative($dir);
		}
		elsif ($dir) {
			$dir = Path::Class::dir($dir) unless blessed $dir && $dir->isa("Path::Class::Dir");
		}
		elsif ($file) {
			$dir = Path::Class::dir('/');
		}
		else {
			$dir = Path::Class::dir('/');
		}

        	$base = new Path::Resource::Base(dir => $dir, uri => $uri, loc => $loc);
	}
	$self->base($base);

        $path = Path::Abstract->new($path) unless blessed $path && $path->isa("Path::Abstract");
	$self->_path($path);

	return $self;
}

=item $rsc->path

=item $rsc->path( <part>, [ <part>, ..., <part> ] )

Return a clone of $rsc->path based on $rsc->path and any optional <part> passed through

    my $rsc = Path::Resource->new(path => "b/c");

    # $path is "b/c"
    my $path = $rsc->path;

    # $path is "b/c/d"
    my $path = $rsc->path("d");

=cut

sub path {
	my $self = shift;
    my $path = $self->_path->child(@_);
    return $path;
}

=item $rsc->clone

=item $rsc->clone( <path> )

Return a Path::Resource object that is a copy of $rsc

The optional argument will change (not append) the path of the cloned object

=cut

sub clone {
	my $self = shift;
	my $path = shift || $self->_path->clone;
	return __PACKAGE__->new(base => $self->base->clone, path => $path);
}

=item $rsc->subdir( <part>, [ <part>, ..., <part> ] )

=item $rsc->child( <part>, [ <part>, ..., <part> ] )

Return a clone Path::Resource object whose path is the child of $rsc->path

    my $rsc = Path::Resource->new(dir => "/a", path => "b");

    # $rsc->path is "b/c/d.tmp"
    $rsc = $rsc->child("c/d.tmp");

    # ->subdir is an alias for ->child
    $rsc = $rsc->parent->subdir("e");

=cut

sub child {
	my $self = shift;
	my $clone = $self->clone($self->_path->child(@_));
	return $clone;
}
*subdir = \&child;

=item $rsc->parent

Return a clone Path::Resource object whose path is the parent of $rsc->path

    my $rsc = Path::Resource->new(dir => "/a", path => "b/c");

    # $rsc->path is "b"
    $rsc = $rsc->parent;

    # $rsc->path is ""
    $rsc = $rsc->parent;

    # $dir is "/a/f"
    my $dir = $rsc->parent->parent->dir("f");

=cut

sub parent {
	my $self = shift;
	my $clone = $self->clone($self->_path->parent);
	return $clone;
}

=item $rsc->loc

=item $rsc->loc( <part>, [ <part>, ..., <part> ] )

Return a Path::Abstract object based on the path part of $rsc->base->uri ($rsc->base->loc), $rsc->path, and any optional <part> passed through

    my $rsc = Path::Resource->new(uri => "http://example.com/a", path => "b/c");

    # $loc is "/a/b/c"
    my $loc = $rsc->loc;

    # $dir is "/a/b/c/d.tmp"
    $loc = $rsc->loc("d.tmp");

=cut

sub loc {
	my $self = shift;
	unshift @_, $self->_path unless $self->_path->is_empty;
	return $self->base->loc->child(@_);
}


=item $rsc->uri

=item $rsc->uri( <part>, [ <part>, ..., <part> ] )

Return a URI object based on $rsc->base->uri, $rsc->path, and any optional <part> passed through

    my $rsc = Path::Resource->new(uri => "http://example.com/a", path => "b/c");

    # $uri is "http://example.com/a/b/c"
    my $uri = $rsc->uri;

    # $uri is "http://example.com/a/b/c/d.tmp"
    $uri = $rsc->uri("d.tmp");

    # $uri is "https://example.com/a/b/c/d.tmp"
    $uri->scheme("https");

=cut

sub uri {
	my $self = shift;
	my $uri = $self->base->uri->clone;
	$uri->path($self->loc(@_)->get);
	return $uri;
}

=item $rsc->file

=item $rsc->file( [ <part>, <part>, ..., <part> ] )

Return a Path::Class::File object based on $rsc->base->dir, $rsc->path, and any optional <part> passed through

NOTE: This method will return a Path::Class::File object, *NOT* a new Path::Resource object (use ->child for that functionality)

    my $rsc = Path::Resource->new(dir => "/a", path => "b");
    $rsc = $rsc->child("c/d.tmp");

    # $file is "/a/b/c/d.tmp"
    my $file = $rsc->file;

    # $file is "/a/b/c/d.tmp/e.txt"
    $file = $rsc->file(qw/ e.txt /);

=cut

sub file {
	my $self = shift;
	unshift @_, $self->_path->get unless $self->_path->is_empty;
	return $self->base->dir->file(@_);
}

=item $rsc->dir

=item $rsc->dir( <part>, [ <part>, ..., <part> ] )

Return a Path::Class::Dir object based on $rsc->base->dir, $rsc->path, and any optional <part> passed through

    my $rsc = Path::Resource->new(dir => "/a", path => "b");
    $rsc = $rsc->child("c/d.tmp");

    # $dir is "/a/b/c/d.tmp"
    my $dir = $rsc->file;

    # $dir is "/a/b/c/d.tmp/e.tmp"
    $dir = $rsc->file(qw/ e.tmp /);

=cut

sub dir {
	my $self = shift;
	unshift @_, $self->_path->get unless $self->_path->is_empty;
	return $self->base->dir->subdir(@_);
}


=item $rsc->base

Return the Path::Resource::Base object for $rsc

=back 

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

URI::ToDisk

=head1 BUGS

Please report any bugs or feature requests to
C<bug-path-resource at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Resource>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Path::Resource

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Path-Resource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Path-Resource>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Resource>

=item * Search CPAN

L<http://search.cpan.org/dist/Path-Resource>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Path::Resource
