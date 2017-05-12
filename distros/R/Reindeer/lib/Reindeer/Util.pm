#
# This file is part of Reindeer
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Reindeer::Util;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Reindeer::Util::VERSION = '0.018';
# ABSTRACT: Common and utility functions for Reindeer

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw{ trait_aliases as_is also_list type_libraries } ],
};

use Class::Load 'load_class';

use Moose 1.15                              ( );
use MooseX::AlwaysCoerce 0.16               ( );
use MooseX::AbstractMethod 0.003            ( );
use MooseX::AttributeShortcuts 0.017        ( );
use MooseX::ClassAttribute 0.26             ( );
use MooseX::CurriedDelegation               ( );
use MooseX::LazyRequire 0.07                ( );
use MooseX::MarkAsMethods 0.14              ( );
use MooseX::NewDefaults 0.003               ( );
use MooseX::StrictConstructor 0.19          ( );
use MooseX::Types::Moose 0.31               ( );
use MooseX::Types::Common::String 0.001004  ( );
use MooseX::Types::Common::Numeric 0.001004 ( );
use MooseX::Types::LoadableClass 0.006      ( );
use MooseX::Types::Path::Class 0.05         ( );
use MooseX::Types::Tied::Hash::IxHash 0.003 ( );

use MooseX::Params::Validate 0.016 ( );
use Path::Class 0.24               ( );
use Try::Tiny 0.11                 ( );

# SlurpyConstructor, Params::Validate


sub trait_aliases {

    # note that merely specifing aliases does not load the packages; Moose
    # will handle that when (if) the trait is ever used.
    return (
        [ 'MooseX::AutoDestruct::Trait::Attribute'           => 'AutoDestruct'    ],
        [ 'MooseX::MultiInitArg::Trait'                      => 'MultiInitArg'    ],
        [ 'MooseX::TrackDirty::Attributes::Trait::Attribute' => 'TrackDirty'      ],
        [ 'MooseX::UndefTolerant::Attribute'                 => 'UndefTolerant'   ],
        [ 'MooseX::CascadeClearing::Role::Meta::Attribute'   => 'CascadeClearing' ],

        # these don't export a trait_alias, so let's create one
        'MooseX::LazyRequire::Meta::Attribute::Trait::LazyRequire',

        # this one is a little funky, in that it replaces the accessor
        # metaclass, rather than just applying a trait to it
        [ 'Moose::Meta::Attribute::Custom::Trait::MergeHashRef' => 'MergeHashRef' ],
    );
}

# If an extension doesn't have a trait that's directly loadable, we build subs
# to do it here.

sub ENV       { _lazy('MooseX::Attribute::ENV',     'MooseX::Attribute::ENV'                      ) }
sub SetOnce   { _lazy('MooseX::SetOnce',            'MooseX::SetOnce::Attribute'                  ) }
sub Shortcuts { _lazy('MooseX::AttributeShortcuts', 'MooseX::AttributeShortcuts::Trait::Attribute') }

sub _lazy   { load_class(shift); shift }


sub as_is {

    return (
        \&ENV,
        \&SetOnce,
        \&Shortcuts,
    );
}

# Types:
# Tied, Perl, IxHash, ENV

# Roles:
# TraitConstructor, Traits


sub also_list {

    return qw{
        MooseX::AbstractMethod
        MooseX::AlwaysCoerce
        MooseX::AttributeShortcuts
        MooseX::ClassAttribute
        MooseX::CurriedDelegation
        MooseX::LazyRequire
        MooseX::NewDefaults
        MooseX::StrictConstructor
    };
}


sub import_type_libraries {
    my ($class, $opts) = @_;

    #$_->import({ -into => $opts->{for_class} }, ':all')
    $_->import($opts, ':all')
        for type_libraries();

    return;
}


sub type_libraries {

    return qw{
        MooseX::Types::Moose
        MooseX::Types::Common::String
        MooseX::Types::Common::Numeric
        MooseX::Types::LoadableClass
        MooseX::Types::Path::Class
        MooseX::Types::Tied::Hash::IxHash
    };
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Reindeer::Util - Common and utility functions for Reindeer

=head1 VERSION

This document describes version 0.018 of Reindeer::Util - released March 28, 2015 as part of Reindeer.

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides the parts of Reindeer that are common to both Reindeer
and Reindeer role.  In general, this package contains functions that either
return lists for L<Moose::Exporter> or actively import other packages into the
namespace of packages invoking Reindeer or Reindeer::Role (e.g. type
libraries).

=head1 FUNCTIONS

=head2 trait_aliases

Trait alias definitions for our optional traits.

=head2 as_is

A list of sugar to export "as_is".

=head2 also_list

A list of Moose::Exporter based packages that we should also invoke (through
Moose::Exporter, that is).

=head2 import_type_libraries

Import our list of type libraries into a given package.

=head2 type_libraries

Returns a list of type libraries currently exported by Reindeer.

=for Pod::Coverage     SetOnce
    Shortcuts

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reindeer|Reindeer>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/reindeer>
and may be cloned from L<git://https://github.com/RsrchBoy/reindeer.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/reindeer/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Freindeer&title=RsrchBoy's%20CPAN%20Reindeer&tags=%22RsrchBoy's%20Reindeer%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Freindeer&title=RsrchBoy's%20CPAN%20Reindeer&tags=%22RsrchBoy's%20Reindeer%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
