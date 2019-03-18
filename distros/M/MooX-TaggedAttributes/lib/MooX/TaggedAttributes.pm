package MooX::TaggedAttributes;

# ABSTRACT: Add a tag with an arbitrary value to a an attribute

use 5.008009;

use strict;
use warnings;

our $VERSION = '0.09';

use Carp;
use MRO::Compat;

use Scalar::Util qw[ blessed ];
use Class::Method::Modifiers qw[ install_modifier ];

our %TAGSTORE;
our %TAGCACHE;

my %ARGS = ( -tags => [] );

sub import {

    my ( $class, @args ) = @_;
    my $target = caller;

    Moo::Role->apply_roles_to_package( $target, __PACKAGE__ );

    return unless @args;

    my %args = %ARGS;

    while ( @args ) {

        my $arg = shift @args;

        croak( "unknown argument to ", __PACKAGE__, ": $arg" )
          unless exists $ARGS{$arg};

        $args{$arg} = defined $ARGS{$arg} ? shift @args : 1;
    }

    $args{-tags} = [ $args{-tags} ]
      unless 'ARRAY' eq ref $args{-tags};

    _install_tags( $target, $args{-tags} )
      if @{ $args{-tags} };

    _install_role_import( $target );
}

# this needs to be accessible by tag role import() methods, but don't want it
# to pollute the namespace
our $_role_import = sub {
    my $class = shift;
    return unless Moo::Role->is_role( $class );

    my $target = caller;
    Moo::Role->apply_roles_to_package( $target, $class );
    _install_tags( $target, $TAGSTORE{$class} );
};


sub _install_role_import {
    my $target = shift;

    ## no critic (ProhibitStringyEval)

    croak( "error installing import routine into $target\n" )
      unless eval
      "package $target; sub import { goto \$MooX::TaggedAttributes::_role_import }; 1;";
}


sub _install_tags {
    my ( $target, $tags ) = @_;

    if ( $TAGSTORE{$target} ) {
        push @{ $TAGSTORE{$target} }, @$tags;
    }

    else {
        $TAGSTORE{$target} = [@$tags];
        _install_tag_handler( $target );
    }
}

sub _install_tag_handler {
    my $target = shift;

    # we need to
    #  1) use the target package's around() function, and
    #  2) call it in that package's context.

    # create a closure which knows about the target's around
    # so that if namespace::clean is called on the target class
    # we don't lose access to it.

    ## no critic (ProhibitStringyEval)
    my $around = eval( "package $target; sub { goto &around }" );

    install_modifier(
        $target,
        after => has => sub {
            my ( $attrs, %attr ) = @_;

            $attrs = ref $attrs ? $attrs : [$attrs];

            my @tags = @{ $TAGSTORE{$target} };

            $around->(
                "_tag_list" => sub {
                    my $orig = shift;

                    ## no critic (ProhibitAccessOfPrivateData)
                    return [
                        @{&$orig},
                        map { [ $_, $attrs, $attr{$_} ] }
                          grep { exists $attr{$_} } @tags,
                    ];

                } );

        } );
}

# Moo::Role won't compose anything before it was used into a consuming
# package. Don't want import to be consumed.
use Moo::Role;

use Sub::Name 'subname';

my $can = sub { ( shift )->next::can };

# this modifier is run once for each composition of a tag role into
# the class.  role composition is orthogonal to class inheritance, so we
# need to carefully handle both

# see http://www.nntp.perl.org/group/perl.moose/2015/01/msg287{6,7,8}.html,
# but note that djerius' published solution was incomplete.
around _tag_list => sub {

    # 1. call &$orig to handle tag role compositions into the current class

# 2. call up the inheritance stack to handle parent class tag role compositions.

    my $orig    = shift;
    my $package = caller;

    # create the proper environment context for next::can
    my $next = ( subname "${package}::_tag_list" => $can )->( $_[0] );

    return [ @{&$orig}, $next ? @{&$next} : () ];
};


# _tags can't be lazy; we must resolve the tags and attributes at
# object creation time in case a role is modified after this object
# is created, as we scan both clsses and roles to gather the tags.
# classes should be immutable after the first instantiation
# of an object (but see RT#101631), but roles aren't.

# We also need to identify when a role has been added to an *object*
# which adds tagged attributes.  TODO: make this work.


# Build the tag cache.  Only update it if we're an object.  if the
# class hasn't yet been instantiated, it's still mutable, and we'd be
# caching prematurely.

sub _class_tags {

    my $class = shift;

    # return cached values if available.  They are stored in %TAGCACHE
    # on the first object method call to _tags(), at which point we've
    # decreed the class as being complete.
    return $TAGCACHE{$class}
      || do {
        my %cache;
        for my $tuple ( @{ $class->_tag_list } ) {

            # my ( $tag, $attrs, $value ) = @$tuple;
            my $cache = ( $cache{ $tuple->[0] } ||= {} );
            $cache->{$_} = $tuple->[2] for @{ $tuple->[1] };
        }
        \%cache;
      };
}

use namespace::clean -except => qw( import  );

# this is where all of the tags get stored while a class is being
# built up.  eventually they are condensed into a simple hash via
# _build_cache

sub _tag_list { [] }

# never create a cached value if called as a class method, as the class
# may still be under construction.
sub _tags {
    my $class = blessed $_[0];
    $class
      ? $TAGCACHE{ $class } ||= _class_tags( $class )
      : _class_tags( $_[0] );
}

1;

#
# This file is part of MooX-TaggedAttributes
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory instantiation use'ing

=head1 NAME

MooX::TaggedAttributes - Add a tag with an arbitrary value to a an attribute

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 # define a Tag Role
 package T1;
 use Moo::Role;
 
 use MooX::TaggedAttributes -tags => [qw( t1 t2 )];
 1;

 # Apply a tag role directly to a class
 package C1;
 use Moo;
 use T1;
 
 has c1 => ( is => 'ro', t1 => 1 );
 1;

 # use a tag role in another Role
 package R1;
 
 use Moo::Role;
 use T1;
 
 has r1 => ( is => 'ro', t2 => 2 );
 1;

 # Use a tag role which consumes a tag role in a class
 package C2;
 use Moo;
 use R1;
 
 has c2 => ( is => 'ro', t2 => sub { } );
 1;

 # Use our tags
 use C1;
 use C2;
 
 use 5.010;
 
 # get the value of the tag t1, applied to attribute a1
 say C1->new->_tags->{t1}{a1};
 
 # get the value of the tag t2, applied to attribute c2
 say C2->new->_tags->{t2}{c2};

=head1 DESCRIPTION

This module attaches a tag-value pair to an attribute in a B<Moo>
class or role, and provides a interface to query which attributes have
which tags, and what the values are.

=head2 Tagging Attributes

To define a set of tags, create a special I<tag role>:

 package T1;
 use Moo::Role;
 use MooX::TaggedAttributes -tags => [ 't1' ];
 
 has a1 => ( is => 'ro', t1 => 'foo' );
 
 1;

If there's only one tag, it can be passed directly without being
wrapped in an array:

 package T2;
 use Moo::Role;
 use MooX::TaggedAttributes -tags => 't2';
 
 has a2 => ( is => 'ro', t2 => 'bar' );
 
 1;

A tag role is a standard B<Moo::Role> with added machinery to track
attribute tags.  As shown, attributes may be tagged in the tag role
as well as in modules which consume it.

Tag roles may be consumed just as ordinary roles, but in order for
role consumers to have the ability to assign tags to attributes, they
need to be consumed with the Perl B<use> statement, not with the B<with> statement.

Consuming with the B<with> statement I<will> propagate attributes with
existing tags, but won't provide the ability to tag new attributes.

This is correct:

 package R2;
 use Moo::Role;
 use T1;
 
 has r2 => ( is => 'ro', t1 => 'foo' );
 1;

 package R3;
 use Moo::Role;
 use R3;
 
 has r3 => ( is => 'ro', t1 => 'foo' );
 1;

The same goes for classes:

 package C1;
 use Moo;
 use T1;
 
 has c1 => ( is => 'ro', t1 => 'foo' );
 1;

Combining tag roles is as simple as B<use>'ing them in the new role:

 package T12;
 
 use Moo::Role;
 use T1;
 use T2;
 
 1;

 package C2;
 use Moo;
 use T12;
 
 has c2 => ( is => 'ro', t1 => 'foo', t2 => 'bar' );
 1;

=head2 Accessing tags

Classes and objects are provided a B<_tags> method which returns a
hash of hashes keyed off of the tags and attribute names.  For
example, for the following code:

 package T;
 use Moo::Role;
 use MooX::TaggedAttributes -tags => [qw( t1 t2 )];
 1;

 package C;
 use Moo;
 use T;
 
 has a => ( is => 'ro', t1 => 2 );
 has b => ( is => 'ro', t2 => 'foo' );
 1;

The tag structure returned by  C<< C->_tags >>

 { t1 => { a => 2 }, t2 => { b => "foo" } }


and C<< C->new->_tags >>

 { t1 => { a => 2 }, t2 => { b => "foo" } }


are identical.

=head1 BUGS AND LIMITATIONS

=head2 Changes to an object after instantiation are not tracked.

If a role with tagged attributes is applied to an object, the
tags for those attributes are not visible.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes>
or by email to
L<bug-MooX-TaggedAttributes@rt.cpan.org|mailto:bug-MooX-TaggedAttributes@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/moox-taggedattributes>
and may be cloned from L<git://github.com/djerius/moox-taggedattributes.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
