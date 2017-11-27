#
# Copyright (C) 2015,2016,2017 Joelle Maslak
# All Rights Reserved - See License
#

package File::FindStrings::Boilerplate;
# ABSTRACT: Default Boilerplate for Perl::Critic::Policy::BadStrings

=head1 SYNOPSIS

  use File::FindStrings::Boilerplate 'script';

=head1 DESCRIPTION

This module serves two purposes.  First, it sets some default imports,
and turns on the strictures I've come to rely upon.  It is a copy of
the current-at-the-time C<JCM::Boilerplate>, but is included seperately
to ensure that future changes to C<JCM::Boilerplate> don't break this
module.

This module optionally takes one of two parameters, 'script', 'class',
or 'role'. If 'script' is specified, the module assumes that you do not
need Moose or MooseX modules.

=head1 WARNINGS

This module makes significant changes in the calling package!

If you plan on using this module in code not related to
the C<Perl::Critic::Policy::BadStrings> distribution, it is probably best
to fetch C<JCM::Boilerplate> and copy the C<Boilerplate.pm> into some
directory (renaming this package in the Perl module file) under your
distribution.

=cut

use v5.22;
use strict;

use feature 'signatures';
no warnings 'experimental::signatures';

use English;
use Import::Into;
use Smart::Comments;

sub import ( $self, $type = 'script' ) {
    ### assert: ($type =~ m/^(?:class|role|script)$/ms)

    my $target = caller;

    strict->import::into($target);
    warnings->import::into($target);
    autodie->import::into($target);

    feature->import::into( $target, ':5.22' );

    utf8->import::into($target);    # Allow UTF-8 Source

    if ( $type eq 'class' ) {
        Moose->import::into($target);
        Moose::Util::TypeConstraints->import::into($target);
        MooseX::StrictConstructor->import::into($target);
        namespace::autoclean->import::into($target);
    } elsif ( $type eq 'role' ) {
        Moose::Role->import::into($target);
        Moose::Util::TypeConstraints->import::into($target);
        MooseX::StrictConstructor->import::into($target);
        namespace::autoclean->import::into($target);
    }

    Carp->import::into($target);
    English->import::into($target);
    Smart::Comments->import::into( $target, '-ENV', '###' );

    feature->import::into( $target, 'postderef' );    # Not needed if feature budle >= 5.23.1

    # We haven't been using this
    # feature->import::into($target, 'refaliasing');
    feature->import::into( $target, 'signatures' );

    feature->import::into( $target, 'switch' );
    feature->import::into( $target, 'unicode_strings' );
    # warnings->unimport::out_of($target, 'experimental::refaliasing');
    warnings->unimport::out_of( $target, 'experimental::signatures' );

    if ( $PERL_VERSION lt v5.24.0 ) {
        warnings->unimport::out_of( $target, 'experimental::postderef' );
    }

    # For "switch" feature
    warnings->unimport::out_of( $target, 'experimental::smartmatch' );

    return;
}

1;

