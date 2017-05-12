# --8<--8<--8<--8<--
#
# Copyright (C) 2015 Smithsonian Astrophysical Observatory
#
# This file is part of MooX::TaggedAttributes
#
# MooX::TaggedAttributes is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package MooX::TaggedAttributes;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use Moo::Role;

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

sub _install_role_import {

    my $target = shift;

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    no warnings 'redefine';
    *{"${target}::import"} = sub {

        my $class  = shift;
        my $target = caller;

        Moo::Role->apply_roles_to_package( $target, $class );

        _install_tags( $target, $TAGSTORE{$class} );
    };

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

    install_modifier(
        $target,
        after => has => sub {
            my ( $attrs, %attr ) = @_;

            $attrs = ref $attrs ? $attrs : [$attrs];

            my $target = caller;

            my @tags = @{ $TAGSTORE{$target} };

            # we need to
            #  1) use the target package's around() function, and
            #  2) call it in that package's context.

            ## no critic (ProhibitStringyEval)
            my $around = eval( "package $target; sub { goto &around }" );

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

use Sub::Name 'subname';

my $can = sub { ( shift )->next::can };

# this modifier is run once for each composition of a tag role into
# the class.  role composition is orthogonal to class inheritance, so we
# need to carefully handle both

# see http://www.nntp.perl.org/group/perl.moose/2015/01/msg287{6,7,8}.html,
# but note that djerius' published solution was incomplete.
around _tag_list => sub {

    # 1. call &$orig to handle tag role compositions into the current
    #    class

    # 2. call up the inheritance stack to handle parent class tag role
    #    compositions.

    my $orig    = shift;
    my $package = caller;

    # create the proper environment context for next::can
    my $next = ( subname "${package}::_tag_list" => $can )->( $_[0] );

    return [ @{&$orig}, $next ? @{&$next} : () ];
};


use namespace::clean -except => qw( import );

# _tags can't be lazy; we must resolve the tags and attributes at
# object creation time in case a role is modified after this object
# is created, as we scan both clsses and roles to gather the tags.
# classes are immutable after the first instantiation
# of an object, but roles aren't.

# We also need to identify when a role has been added to an *object*
# which adds tagged attributes.  TODO: make this work.

sub _tag_list { [] }


# Build the tag cache.  Only update it if we're an object.  if the
# class hasn't yet been instantiated, it's still mutable, and we'd be
# caching prematurely.

sub _build_cache {

    my $class = shift;

    # returned cached tags if available.
    return $TAGCACHE{$class} if $TAGCACHE{$class};

    my %cache;

    for my $tuple ( @{ $class->_tag_list } ) {
        # my ( $tag, $attrs, $value ) = @$tuple;
        my $cache = ( $cache{ $tuple->[0] } ||= {} );
        $cache->{$_} = $tuple->[2] for @{ $tuple->[1] };
    }

    return \%cache;
}

has _tag_cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
	my $class = blessed( $_[0] );
	return $TAGCACHE{$class} ||= $class->_build_cache;
    }
);

sub _tags { blessed( $_[0] ) ? $_[0]->_tag_cache : $_[0]->_build_cache }

1;

__END__

=head1 NAME

MooX::TaggedAttributes - Add a tag with an arbitrary value to a an attribute


=head1 SYNOPSIS

    # Create a Role used to apply the attributes
    package Tags;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( t1 t2 ) ];

    # Apply the role directly to a class
    package C1;
    use Tags;

    has c1 => ( is => 'ro', t1 => 1 );

    my $obj = C1->new;

    # get the value of the tag t1, applied to attribute a1
    $obj->_tags->{t1}{a1};

    # Apply the tags to a role
    package R1;
    use Tag1;

    has r1 => ( is => 'ro', t2 => 2 );

    # Use that role in a class
    package C2;
    use R1;

    has c2 => ( is => 'ro', t2 => sub { }  );

    # get the value of the tag t2, applied to attribute c2
    C2->new->_tags->{t2}{c2};

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

If there's only one tag, it can be passed directly without being
wrapped in an array:

    package T2;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => 't2';

    has a2 => ( is => 'ro', t2 => 'bar' );

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

    package R3;
    use Moo::Role;
    use R3;

    has r3 => ( is => 'ro', t1 => 'foo' );

The same goes for classes:

    package C2;
    use Moo;
    use T1;

    has c2 => ( is => 'ro', t1 => 'foo' );

Combining tag roles is as simple as B<use>'ing them in the new role:

    package T12;
    use T1;
    use T2;

    package C2;
    use Moo;
    use T12;

    has c2 => ( is => 'ro', t1 => 'foo', t2 => 'bar' );

=head2 Accessing tags

Classes and objects are provided a B<_tags> method which returns a
hash of hashes keyed off of the tags and attribute names.  For
example, for the following code:

    package T;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( t1 t2 ) ];

    package C;
    use Moo;
    use T;

    has a => ( is => 'ro', t1 => 2 );
    has b => ( is => 'ro', t2 => 'foo' );

The tag structure returned by either of the following

    C->_tags
    C->new->_tags

looks like

    { t1 => { a => 2 },
      t2 => { b => 'foo' },
    }

=head1 BUGS AND LIMITATIONS

=head2 Changes to an object after instantiation are not tracked.

If a role with tagged attributes is applied to an object, the
tags for those attributes are not visible.



Please report any bugs or feature requests to
C<bug-moox-taggedattributes@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 The Smithsonian Astrophysical Observatory

MooX::TaggedAttributes is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>
