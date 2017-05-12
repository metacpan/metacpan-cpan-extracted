package Repository::Simple::Util;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;

use Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( 
    normalize_path 
    basename 
    dirname 
);

our @CARP_NOT = qw(
    Repository::Simple::Engine
    Repository::Simple::Node
    Repository::Simple::Permission
    Repository::Simple::Property
    Repository::Simple::Type::Node
    Repository::Simple::Type::Property
    Repository::Simple::Type::Value
    Repository::Simple::Value
    Repository::Simple
);

=head1 NAME

Repository::Simple::Util - Utility methods shared by repository components

=head1 SYNOPSIS

  use Repository::Simple::Util qw( normalize_path dirname basename );

  my $clean_path = normalize_path("/usr", "../messy/../.././///messy/path");

  my $dirname  = dirname("/foo/bar/baz"); # returns "/foo/bar"
  my $basename = basename("/foo/bar/baz"); # returns "baz"

=head1 DESCRIPTION

The methods here are for use by the content repository and content repository engines internally. Unless you are extending the repository system, you will probably want to avoid the use of these methods.

=head1 METHODS

=over

=item $clean_path = normalize_path($current_path, $messy_path)

This method creates a "normal" path out of the given "messy" path, C<$messy_path>. In case the C<$messy_path> is relative, the C<$current_path> gives the absolute path we're working from.

It provides the following:

=over

=item 1.

If the messy path is relative, this method merges the messy path and the current path to create an absolute path.

=item 2.

All superfluous "." and ".." elements will be stripped from the path so that the resulting path will be the most concise and direct name for the named file.

=item 3.

Enforces the principle that ".." applied to the root returns the root. This provides security by preventing users from getting to a file outside of the root.

=back

=cut

sub normalize_path {
    my ($current_path, $messy_path) = @_;

    if (!defined $current_path) {
        croak "normalize_path must be given a current path";
    }

    if (!defined $messy_path) {
        croak "normalize_path must be given a messy path";
    }

    # Fix us up to an absolute path
    my $abs_path;
    if ($messy_path !~ m#^/#) {
        $abs_path = "$current_path/$messy_path";
    }
    else {
        $abs_path = $messy_path;
    }

    # Break into components
    my @components = split m#/+#, $abs_path;
    @components = ('', '') unless @components; # account for root
    unshift @components, '' unless @components > 1;

    # Manipulate the path components based upon each entry, work left-to-right
    # to ensure proper handling of each component.
    for (my $i = 1; $i < @components;) {
        # Drop any "." components
        if ($components[$i] eq '.') {
            splice @components, $i, 1;
        }

        # Drop any ".." that go above root
        elsif ($components[$i] eq '..' && $i == 1) {
            splice @components, $i, 1;
        }

        # Drop any ".." and the component above
        elsif ($components[$i] eq '..') {
            splice @components, ($i - 1), 2;
            $i--;
        }

        # Otherwise, do nothing and move on to the next element
        else {
            $i++;
        }
    }

    # Make sure to tack on an empty "" in case we're back to root
    unshift @components, '' unless @components > 1;

    # Reassemble the result
    return join '/', @components;
}

=item $dirname = dirname($path)

Given a normalized path, this returns the path with the last element stripped. That is, it returns the parent of the given path. If the root path ("/") is given, then the same path is returned.

=cut

sub dirname {
    my $path = shift;

    if ($path eq '/') {
        return '/';
    }

    else {
        my @components = split m{/}, $path;
        pop @components;
        push @components, '' if @components == 1;
        return join '/', @components;
    }
}

=item $basename = basename($path)

Given a normalized path, this method returns the last path element of the path. That is, it returns the last name in the path. If the root path ("/") is given, then the same is returned.

=cut

sub basename {
    my $path = shift;

    if ($path eq '/') {
        return '/';
    }

    else {
        my @components = split m{/}, $path;
        return pop @components;
    }
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
