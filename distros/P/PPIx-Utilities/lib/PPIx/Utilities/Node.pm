package PPIx::Utilities::Node;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.001000';

use Readonly;


use PPI::Document::Fragment 1.208 qw< >;
use Scalar::Util                  qw< refaddr >;


use PPIx::Utilities::Exception::Bug qw< >;


use base 'Exporter';

Readonly::Array our @EXPORT_OK => qw<
    split_ppi_node_by_namespace
>;


sub split_ppi_node_by_namespace {
    my ($node) = @_;

    # Ensure we don't screw up the original.
    $node = $node->clone();

    # We want to make sure that we have locations prior to things being split
    # up, if we can, but don't worry about it if we don't.
    eval { $node->location(); }; ## no critic (RequireCheckingReturnValueOfEval)

    if ( my $single_namespace = _split_ppi_node_by_namespace_single($node) ) {
        return $single_namespace;
    } # end if

    my %nodes_by_namespace;
    _split_ppi_node_by_namespace_in_lexical_scope(
        $node, 'main', undef, \%nodes_by_namespace,
    );

    return \%nodes_by_namespace;
} # end split_ppi_node_by_namespace()


# Handle the case where there's only one.
sub _split_ppi_node_by_namespace_single {
    my ($node) = @_;

    my $package_statements = $node->find('PPI::Statement::Package');

    if ( not $package_statements or not @{$package_statements} ) {
        return { main => [$node] };
    } # end if

    if (@{$package_statements} == 1) {
        my $package_statement = $package_statements->[0];
        my $package_address = refaddr $package_statement;

        # Yes, child and not schild.
        my $first_child = $node->child(0);
        if (
                $package_address == refaddr $node
            or  $first_child and $package_address == refaddr $first_child
        ) {
            return { $package_statement->namespace() => [$node] };
        } # end if
    } # end if

    return;
} # end _split_ppi_node_by_namespace_single()


sub _split_ppi_node_by_namespace_in_lexical_scope {
    my ($node, $initial_namespace, $initial_fragment, $nodes_by_namespace)
        = @_;

    my %scope_fragments_by_namespace;

    # I certainly hope a value isn't going to exist at address 0.
    my $initial_fragment_address = refaddr $initial_fragment || 0;
    my ($namespace, $fragment) = ($initial_namespace, $initial_fragment);

    if ($initial_fragment) {
        $scope_fragments_by_namespace{$namespace} = $initial_fragment;
    } # end if

    foreach my $child ( $node->children() ) {
        if ( $child->isa('PPI::Statement::Package') ) {
            if ($fragment) {
               _push_fragment($nodes_by_namespace, $namespace, $fragment);

                undef $fragment;
            } # end if

            $namespace = $child->namespace();
        } elsif (
                $child->isa('PPI::Statement::Compound')
            or  $child->isa('PPI::Statement::Given')
            or  $child->isa('PPI::Statement::When')
        ) {
            my $block;
            my @components = $child->children();
            while (not $block and my $component = shift @components) {
                if ( $component->isa('PPI::Structure::Block') ) {
                    $block = $component;
                } # end if
            } # end while

            if ($block) {
                if (not $fragment) {
                    $fragment = _get_fragment_for_split_ppi_node(
                        $nodes_by_namespace,
                        \%scope_fragments_by_namespace,
                        $namespace,
                    );
                } # end if

                _split_ppi_node_by_namespace_in_lexical_scope(
                    $block, $namespace, $fragment, $nodes_by_namespace,
                );
            } # end if
        } # end if

        $fragment = _get_fragment_for_split_ppi_node(
            $nodes_by_namespace, \%scope_fragments_by_namespace, $namespace,
        );

        if ($initial_fragment_address != refaddr $fragment) {
            # Need to fix these to use exceptions.  Thankfully the P::C tests
            # will insist that this happens.
            $child->remove()
                or PPIx::Utilities::Exception::Bug->throw(
                    'Could not remove child from parent.'
                );
            $fragment->add_element($child)
                or PPIx::Utilities::Exception::Bug->throw(
                    'Could not add child to fragment.'
                );
        } # end if
    } # end foreach

    return;
} # end _split_ppi_node_by_namespace_in_lexical_scope()


sub _get_fragment_for_split_ppi_node {
    my ($nodes_by_namespace, $scope_fragments_by_namespace, $namespace) = @_;

    my $fragment;
    if ( not $fragment = $scope_fragments_by_namespace->{$namespace} ) {
        $fragment = PPI::Document::Fragment->new();
        $scope_fragments_by_namespace->{$namespace} = $fragment;
        _push_fragment($nodes_by_namespace, $namespace, $fragment);
    } # end if

    return $fragment;
} # end _get_fragment_for_split_ppi_node()


# Due to $fragment being passed into recursive calls to
# _split_ppi_node_by_namespace_in_lexical_scope(), we can end up attempting to
# put the same fragment into a namespace's nodes multiple times.
sub _push_fragment {
    my ($nodes_by_namespace, $namespace, $fragment) = @_;

    my $nodes = $nodes_by_namespace->{$namespace} ||= [];

    if (not @{$nodes} or refaddr $nodes->[-1] != refaddr $fragment) {
        push @{$nodes}, $fragment;
    } # end if

    return;
} # end _push_fragment()


1;

__END__

=head1 NAME

PPIx::Utilities::Node - Extensions to L<PPI::Node|PPI::Node>.


=head1 VERSION

This document describes PPIx::Utilities::Node version 1.1.0.


=head1 SYNOPSIS

    use PPIx::Utilities::Node qw< split_ppi_node_by_namespace >;

    my $dom = PPI::Document->new("...");

    while (
        my ($namespace, $sub_doms) = each split_ppi_node_by_namespace($dom)
    ) {
        foreach my $sub_dom ( @{$sub_doms} ) {
            ...
        }
    }


=head1 DESCRIPTION

This is a collection of functions for dealing with L<PPI::Node|PPI::Node>s.


=head1 INTERFACE

Nothing is exported by default.


=head2 split_ppi_node_by_namespace($node)

Returns the sub-trees for each namespace in the node as a reference to a hash
of references to arrays of L<PPI::Node|PPI::Node>s.  Say we've got the
following code:

    #!perl

    my $x = blah();

    package Foo;

    my $y = blah_blah();

    {
        say 'Whee!';

        package Bar;

        something();
    }

    thingy();

    package Baz;

    da_da_da();

    package Foo;

    foreach ( blrfl() ) {
        ...
    }

Calling this function on a L<PPI::Document|PPI::Document> for the above
returns a value that looks like this, using multi-line string literals for the
actual code parts instead of PPI trees to make this easier to read:

    {
        main    => [
            q<
                #!perl

                my $x = blah();
            >,
        ],
        Foo     => [
            q<
                package Foo;

                my $y = blah_blah();

                {
                    say 'Whee!';

                }

                thingy();
            >,
            q<
                package Foo;

                foreach ( blrfl() ) {
                    ...
                }
            >,
        ],
        Bar     => [
            q<
                package Bar;

                something();
            >,
        ],
        Baz     => [
            q<
                package Baz;

                da_da_da();
            >,
        ],
    }

Note that the return value contains copies of the original nodes, and not the
original nodes themselves due to the need to handle namespaces that are not
file-scoped.  (Notice how the first element for "Foo" above differs from the
original code.)


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-ppix-utilities@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c)2009-2010, Elliot Shank C<< <perl@galumph.com> >>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.


=cut

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/lib/PPIx/Utilities/Node.pm $
#     $Date: 2010-12-01 20:31:47 -0600 (Wed, 01 Dec 2010) $
#   $Author: clonezone $
# $Revision: 4001 $
##############################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 70
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround:
