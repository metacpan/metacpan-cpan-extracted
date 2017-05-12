###########################################
package Path::Ancestor;
###########################################
use strict;
use warnings;
use List::Util qw(min max);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(longest_common_ancestor);

our $VERSION = "0.01";

###########################################
sub longest_common_ancestor {
###########################################
    my $paths   = [];

      # Just one path? Simply return it.
    return $_[0] if @_ == 1;

      # Transform all paths to arrays
    for ( @_ ) {
        push @$paths, [split //, $_];
    }

    my $minlen = min map { scalar @$_ } @$paths;
    my $maxlen = max map { scalar @$_ } @$paths;
    my $last_match        = -1;
    my $last_slash_idx    = -1;

      # Examine all characters left-to-right
    MATCH: for my $i (0..$minlen-1) {

          # Get the Nth character of the first path
        my $ref = $paths->[0]->[ $i ];
        if( $ref eq "/" ){
            $last_slash_idx = $i;
        }

          # ... and compare what all other paths have at this location
        for my $path_idx ( 1 .. $#$paths ) {
            if( $paths->[ $path_idx ]->[ $i ] ne $ref ) {
                last MATCH;
            }
            $last_match = $i;
        }
    }

      # Here's an edge case: If we have "/foo", "/foo/bar", "/foo/moo/moo",
      # we need to verify that "/foo" is a *complete* path with all other
      # paths.
    my $is_complete_path = 1;
    for ( @$paths ) {
        if(exists $_->[ $last_match+1 ] and
           $_->[ $last_match+1 ] ne "/") {
               $is_complete_path = 0;
               last;
        }
    }

      # Remove only trailing slashes
    while($last_match > 0 and
        $paths->[0]->[ $last_match ] eq "/") {
        $last_match--;
    }

      # What if we didn't match all the way to the end?
    if( $last_match+1 ne $maxlen and !$is_complete_path) {
        # Not a complete path, go back

        if($last_slash_idx < 0) {
            # We don't have a slash to go back to => empty match
            $last_match = -1;
        } elsif($last_slash_idx == 0 and $paths->[0]->[0] eq "/") {
            # leave the slash in if "/" is the longest common path
            $last_match = 0;
        } else {
            # up until (excluding) the last matching slash
            $last_match = $last_slash_idx - 1;
        }
    }

    return substr $_[0], 0, $last_match+1;
}

1;

__END__

=head1 NAME

Path::Ancestor - Find the longest common ancestor of N paths

=head1 SYNOPSIS

    use Path::Ancestor qw(longest_common_ancestor);

    my $ancestor = longest_common_ancestor( 
                     "/foo/bar/baz",
                     "/foo/bar/baz/moo",
                     "/foo/bar/quack" 
                   );

    # => "foo/bar"

=head1 DESCRIPTION

Path::Ancestor finds the longest common ancestor of N file paths. 

Make sure that all paths are given in canonical Unix format, either
all absolute or all relative. If you have a different format, use
File::Spec::canonpath to sanitize your paths before feeding them to
Path::Ancestor, because Path::Ancestor won't do anything fancy in
this regard.

The longest common ancestor path will never have a trailing slash,
except if it's the root path (/).

Examples:

    /foo/bar, /foo     => /foo
    /foo/bar, /foo/baz => /foo
    /foo1, /foo2       => /

=head1 LEGALESE

Copyright 2008 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2008, Mike Schilli <cpan@perlmeister.com>
