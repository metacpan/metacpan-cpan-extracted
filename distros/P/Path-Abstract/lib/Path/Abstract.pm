package Path::Abstract;
BEGIN {
  $Path::Abstract::VERSION = '0.096';
}
# ABSTRACT: Fast and featureful UNIX-style path parsing and manipulation

use warnings;
use strict;

use vars qw/$_0_093_warn %_0_093_warning/;


$_0_093_warn = 1;

use Sub::Exporter;
{
    my $exporter = Sub::Exporter::build_exporter({
        exports => [ path => sub { sub {
            return __PACKAGE__->new(@_)
        } } ],
    });

    sub import {
        if (@_ && grep { defined && $_ eq '--no_0_093_warning' } @_) {
            $_0_093_warn = 0;
        }
        @_ = grep { ! defined || $_ !~ m/^--/ } @_;
        goto $exporter;
    };
}

use overload
	'""' => 'get',
	fallback => 1,
;

use base qw/Path::Abstract::Underload/;

use Carp;
sub _0_093_warn {
    if ($_0_093_warn) {
        my ($package, $filename, $line, $subroutine) = caller(1);
        if (! $_0_093_warning{$subroutine}) {
            $_0_093_warning{$subroutine} = 1;
            $subroutine =~ s///g;
            carp "** $subroutine behavior has changed since 0.093\n" . 
                 "** To disable this warning: use Path::Abstract qw/--no_0_093_warning/"
        }
    }
}





























1;

__END__
=pod

=head1 NAME

Path::Abstract - Fast and featureful UNIX-style path parsing and manipulation

=head1 VERSION

version 0.096

=head1 SYNOPSIS

  use Path::Abstract;

  my $path = Path::Abstract->new( '/apple/banana' )

  # $parent is '/apple'
  my $parent = $path->parent

  # $cherry is '/apple/banana/cherry.txt'
  my $cherry = $path->child( "cherry.txt" )

  path( '/a/b/c/' )->list                   # ( 'a', 'b', 'c' )
  path( '/a/b/c/' )->split                  # ( '/a', 'b', 'c/' )

  path( '/a/b/c/' )->first                  # a
  path( '/a/b/c/' )->beginning              # /a

  path( '/a/b/c/' )->last                   # c
  path( '/a/b/c/' )->ending                 # c/

  path( '/a/b/c/' ).at(0)                   # a (equivalent to ->first)
  path( '/a/b/c/' ).at(-1)                  # c (equivalent to ->last)
  path( '/a/b/c/' ).at(1)                   # b

  $path = path( 'a/b/c' )
  $path->append( 'd', 'ef/g', 'h' )         # a/b/cd/ef/g/h

  path( 'a/b/c.html' )->extension           # .html
  path( 'a/b/c' )->extension                # ''
  path( 'a/b/c.tar.gz' )->extension         # .gz
  path( 'a/b/c.tar.gz' )->
    extension({ match: '*' })               # .tar.gz

  path( 'a/b/c.html' )->extension( '.txt' ) # a/b/c.txt
  path( 'a/b/c.html' )->extension( 'zip' )  # a/b/c.zip
  path( 'a/b/c.html' )->extension( '' )     # a/b/c

  path( 'a/b/c' )->down( 'd/e' )            # a/b/c/d/e
  path( 'a/b/c' )->child( 'd/e' )           # a/b/c/d/e (Same as ->down except
                                            # returning a new path instead of
                                            # modifying the original)
  
  path( 'a/b/c' )->up                       # a/b
  path( 'a/b/c' )->parent                   # a/b (Same as ->up except
                                            # returning a new path instead of
                                            # modifying the original)

=head1 DESCRIPTION

Path::Abstract is a tool for parsing, interrogating, and modifying a UNIX-style path. The parsing behavior
is similar to L<File::Spec::Unix>, except that trailing slashes are preserved (converted into a single slash).

=head1 Different behavior since 0.093

Some methods of Path::Abstract have changed since 0.093 with the goal of having better/more consistent behavior

Unfortunately, this MAY result in code that worked with 0.093 and earlier be updated to reflect the new behavior

The following has changed:

=head2 $path->list

The old behavior (kept the leading slash but dropped trailing slash):

    path('/a/b/c/')->list    # ( '/a', 'b', 'c' )
    path('a/b/c/')->list     # ( 'a', 'b', 'c' )

The new behavior (neither slash is kept):

    path('/a/b/c/')->list    # ( 'a', 'b', 'c' )
    path('a/b/c/')->list     # ( 'a', 'b', 'c' )

In addition, $path->split was an alias for $path->list, but this has changed. Now split
WILL keep BOTH leading and trailing slashes (if any):

    path('/a/b/c/')->split    # ( '/a', 'b', 'c/' )
    path('a/b/c/')->split     # ( 'a', 'b', 'c/' )
    path('a/b/c')->split      # ( 'a', 'b', 'c' ) Effectively equivalent to ->list

=head2 $path->split

See the above note on $path->list

=head2 $path->first

The old behavior:

    1. Would return undef for the empty path
    2. Would include the leading slash (if present)
    3. Would NOT include the trailing slash (if present)
    
    path(undef)->first  # undef
    path('')->first     # undef
    path('/a')->first   # /a
    path('/a/')->first  # /a
    path('a')->first    # a

The new behavior:

    1. Always returns at least the empty string
    2. Never includes any slashes

    path(undef)->first  # ''
    path('')->first     # ''
    path('/a')->first   # a
    path('/a/')->first  # a
    path('a')->first    # a

For an alternative to ->first, try ->beginning

=head2 $path->last

Simlar to ->first

The old behavior:

    1. Would return undef for the empty path
    2. Would include the leading slash (if present)
    3. Would NOT include the trailing slash (if present)
    
    path(undef)->last  # undef
    path('')->last     # undef
    path('/a')->last   # /a
    path('/a/')->last  # /a
    path('a')->last    # a
    path('a/b')->last  # b
    path('a/b/')->last # b

The new behavior:

    1. Always returns at least the empty string
    2. Never includes any slashes

    path(undef)->last  # ''
    path('')->last     # ''
    path('/a')->last   # a
    path('/a/')->last  # a
    path('a')->last    # a
    path('a/b')->last  # b
    path('a/b/')->last # b

For an alternative to ->last, try ->ending

=head2 $path->is_branch

The old behavior:

    1. The empty patch ('') would not be considered a branch

The new behavior:

    1. The empty patch ('') IS considered a branch

=back

=head1 USAGE

=head2 Path::Abstract->new( <path> )

=head2 Path::Abstract->new( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=head2 Path::Abstract::path( <path> )

=head2 Path::Abstract::path( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Abstract> object using <path> or by joining each <part> with "/"

Returns the new C<Path::Abstract> object

=head2 $path->clone

Returns an exact copy of $path

=head2 $path->set( <path> )

=head2 $path->set( <part>, [ <part>, ..., <part> ] )

Set the path of $path to <path> or the concatenation of each <part> (separated by "/")

Returns $path

=head2 $path->is_nil

=head2 $path->is_empty

Returns true if $path is equal to ""

=head2 $path->is_root

Returns true if $path is equal to "/"

=head2 $path->is_tree

Returns true if $path begins with "/"

	path("/a/b")->is_tree # Returns true
	path("c/d")->is_tree # Returns false

=head2 $path->is_branch

Returns true if $path does NOT begin with a "/"

	path("")->is_branch # Returns true
	path("/")->is_branch # Returns false
	path("c/d")->is_branch # Returns true
	path("/a/b")->is_branch # Returns false

=head2 $path->to_tree

Change $path by prefixing a "/" if it doesn't have one already

Returns $path

=head2 $path->to_branch

Change $path by removing a leading "/" if it has one

Returns $path

=head2 $path->list

Returns the path in list form by splitting at each "/"

	path("c/d")->list # Returns ("c", "d")
	path("/a/b/")->last # Returns ("a", "b")

NOTE: This behavior is different since 0.093 (see above)

=head2 $path->split

=head2 $path->first

Returns the first part of $path up to the first "/" (but not including the leading slash, if any)

	path("c/d")->first # Returns "c"
	path("/a/b")->first # Returns "a"

This is equivalent to $path->at(0)

=head2 $path->last

Returns the last part of $path up to the last "/"

	path("c/d")->last # Returns "d"
	path("/a/b/")->last # Returns "b"

This is equivalent to $path->at(-1)

=head2 $path->at( $index )

Returns the part of path at $index, not including any slashes
You can use a negative $index to start from the end of path

    path("/a/b/c/").at(0)  # a (equivalent to $path->first)
    path("/a/b/c/").at(-1) # c (equivalent to $path->last)
    path("/a/b/c/").at(1)  # b

=head2 $path->beginning

Returns the first part of path, including the leading slash, if any

    path("/a/b/c/")->beginning # /a
    path("a/b/c/")->beginning  # a

=head2 $path->ending

Returns the first part of path, including the leading slash, if any

    path("/a/b/c/")->ending # c/
    path("/a/b/c")->ending  # c

=head2 $path->get

=head2 $path->stringify

Returns the path in string or scalar form

	path("c/d")->list # Returns "c/d"
	path("/a/b/")->last # Returns "/a/b"

=head2 $path->push( <part>, [ <part>, ..., <part> ] )

=head2 $path->down( <part>, [ <part>, ..., <part> ] )

Modify $path by appending each <part> to the end of \$path, separated by "/"

Returns $path

    path( "a/b/c" )->down( "d/e" ) # a/b/c/d/e

=head2 $path->child( <part>, [ <part>, ..., <part> ] )

Make a copy of $path and push each <part> to the end of the new path.

Returns the new child path

    path( "a/b/c" )->child( "d/e" ) # a/b/c/d/e

=head2 $path->append( $part1, [ $part2 ], ... )

Modify path by appending $part1 WITHOUT separating it by a slash. Any, optional,
following $part2, ..., will be separated by slashes as normal

      $path = path( "a/b/c" )
      $path->append( "d", "ef/g", "h" ) # "a/b/cd/ef/g/h"

=head2 $path->extension

Returns the extension of path, including the leading the dot

Returns "" if path does not have an extension

      path( "a/b/c.html" )->extension                   # .html
      path( "a/b/c" )->extension                        # ""
      path( "a/b/c.tar.gz" )->extension                 # .gz
      path( "a/b/c.tar.gz" )->extension({ match: "*" }) # .tar.gz

=head2 $path->extension( $extension )

Modify path by changing the existing extension of path, if any, to $extension

      path( "a/b/c.html" )->extension( ".txt" ) # a/b/c.txt
      path( "a/b/c.html" )->extension( "zip" )  # a/b/c.zip
      path( "a/b/c.html" )->extension( "" )     # a/b/c

Returns path

=head2 $path->pop( <count> )

Modify $path by removing <count> parts from the end of $path

Returns the removed path as a C<Path::Abstract> object

=head2 $path->up( <count> )

Modify $path by removing <count> parts from the end of $path

Returns $path

=head2 $path->parent( <count> )

Make a copy of $path and pop <count> parts from the end of the new path

Returns the new parent path

=head2 $path->file

=head2 $path->file( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::File> object using $path as a base, and optionally extending it by each <part>

Returns the new file object

=head2 $path->dir

=head2 $path->dir( <part>, [ <part>, ..., <part> ] )

Create a new C<Path::Class::Dir> object using $path as a base, and optionally extending it by each <part>

Returns the new dir object

=head1 SEE ALSO

L<Path::Class>

L<File::Spec::Unix>

L<File::Spec>

L<Path::Resource>

L<Path::Abstract::Underload>

L<URI::PathAbstract>

=head1 ACKNOWLEDGEMENTS

Thanks to Joshua ben Jore, Max Kanat-Alexander, and Scott McWhirter for discovering the "use overload ..." slowdown issue.

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

