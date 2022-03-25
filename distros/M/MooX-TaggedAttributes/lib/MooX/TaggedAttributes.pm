package MooX::TaggedAttributes;

# ABSTRACT: Add a tag with an arbitrary value to a an attribute

use v5.10.1;

use strict;
use warnings;

our $VERSION = '0.15';

use MRO::Compat;

use Class::Method::Modifiers ();

use Sub::Name ();
use Moo::Role ();
use MooX::TaggedAttributes::Cache;

our %TAGSTORE;
our %TAGCACHE;
our %TAGHANDLER;

my %ARGS = ( -tags => 1, -handler => 1 );

sub _croak {
    require Carp;
    goto \&Carp::croak;
}

sub import {

    my ( $class, @args ) = @_;
    my $target = caller;

    Moo::Role->apply_roles_to_package( $target,
        'MooX::TaggedAttributes::Role' );

    return unless @args;

    my %args;

    while ( @args ) {
        my $arg = shift @args;
        _croak( "unknown argument to ", __PACKAGE__, ": $arg" )
          unless exists $ARGS{$arg};
        $args{$arg} = defined $ARGS{$arg} ? shift @args : 1;
    }

    if ( defined $args{-tags} ) {
        $args{-tags} = [ $args{-tags} ]
          unless 'ARRAY' eq ref $args{-tags};

        $args{-class} = $class;
        install_tags( $target, %args )
          if @{ $args{-tags} };
    }

    no strict 'refs';    ## no critic
    *${ \"${target}::import" } = \&role_import;
}

























sub role_import {
    my $class = shift;
    return unless Moo::Role->is_role( $class );
    my $target = caller;
    if ( Moo::Role->is_role( $target ) ) {
        Moo::Role->apply_roles_to_package( $target, $class );
    }
    else {
        # Prevent installation of the import routine from a tagged role
        # into the consumer.  Roles won't overwrite an existing method,
        # so create one which goes away when this block exits.
        no strict 'refs';    ## no critic
        local *${ \"${target}::import" } = sub { };
        Moo::Role->apply_roles_to_package( $target, $class );
    }
    install_tags( $target, -class => $class );
}

















sub install_tags {
    my ( $target, %opt ) = @_;

    my $tags = $opt{-tags}
      // ( defined( $opt{-class} ) && $TAGSTORE{ $opt{-class} } )
      || _croak( "-tags or -class not specified" );

    # first time importing a tag role, install our tag handler
    install_tag_handler( $target, \&make_tag_handler )
      if !exists $TAGSTORE{$target};

    # add the tags.
    push @{ $TAGSTORE{$target} //= [] }, @$tags;

    # if an extra handler has been specified, or the tag role class
    # $opt{-class} has one install that as well.
    if ( my $handler = $opt{-handler}
        // ( defined $opt{-class} && $TAGHANDLER{ $opt{-class} } ) )
    {
        my @handlers = 'ARRAY' eq ref $handler ? @$handler : $handler;
        install_tag_handler( $target, $_ ) for @handlers;
        push @{ $TAGHANDLER{$target} //= [] }, @handlers;
    }
}












sub install_tag_handler {
    my ( $target, $handler ) = @_;
    Class::Method::Modifiers::install_modifier( $target,
        around => has => $handler->( $target ) );
}











sub make_tag_handler {

    # we need to
    #  1) use the target package's around() function, and
    #  2) call it in that package's context.

    # create a closure which knows about the target's around
    # so that if namespace::clean is called on the target class
    # we don't lose access to it.


    my $target = shift;
    my $around = \&${ \"${target}::around" };

    return Sub::Name::subname "${target}::tag_handler" => sub {
        my ( $orig, $attrs, %opt ) = @_;
        $orig->( $attrs, %opt );

        $attrs = ref $attrs ? $attrs : [$attrs];
        my @tags = @{ $TAGSTORE{$target} };
        $around->(
            "_tag_list" => sub {
                my $orig = shift;
                ## no critic (ProhibitAccessOfPrivateData)
                return [
                    @{&$orig},
                    map    { [ $_, $attrs, $opt{$_} ] }
                      grep { exists $opt{$_} } @tags,
                ];
            } );
    }
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

version 0.15

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
 
 use 5.01001;
 
 # get the value of the tag t1, applied to attribute a1
 say C1->new->_tags->{t1}{a1};
 
 # get the value of the tag t2, applied to attribute c2
 say C2->new->_tags->{t2}{c2};

=head1 DESCRIPTION

This module attaches a tag-value pair to an attribute in a B<Moo>
class or role, and provides a interface to query which attributes have
which tags, and what the values are.  It keeps track of tags for
attributes through role composition as well as class inheritance.

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
L<MooX::TaggedAttributes::Cache> object.  For backwards compatibility,
it can be dereferenced as a hash, providing a hash of hashes keyed
off of the tags and attribute names.  For example, for the following
code:

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

 bless({ t1 => { a => 2 }, t2 => { b => "foo" } }, "MooX::TaggedAttributes::Cache")

and C<< C->new->_tags >>

 bless({ t1 => { a => 2 }, t2 => { b => "foo" } }, "MooX::TaggedAttributes::Cache")

are identical.

=head1 ADVANCED USE

B<Experimental>

C<MooX::TaggedAttributes> works in part by wrapping L<Moo/has> in
logic which handles the association of tags with attributes.  This
wrapping is automatically applied when a module uses a tag role, and
its mechanism may be used to apply an additional wrapper by passing
the C<-handler> option to L<MooX::TaggedAttributes>:

  use MooX::TaggedAttributes -handler => $handler, -tags => ...;

C<$handler> is a subroutine reference which will be called as

  $coderef = $handler->($class);

Its return value must be a coderef suitable for passing to
L<Class::Method::Modifiers/around> to wrap C<has>, e.g.

  around has => $coderef;

=head1 BUGS, LIMITATIONS, TRAPS FOR THE UNWARY

=head2 Changes to an object after instantiation are not tracked.

If a role with tagged attributes is applied to an object, the
tags for those attributes are not visible.

=head2 An B<import> routine is installed into the tag role's namespace

When a tag role imports C<MooX::TaggedAttributes> via

  package My::Role;
  use MooX::TaggedAttributes;

two things happen to it:

=over

=item 1

a role is applied to it which adds the  methods C<_tags> and C<_tag_list>.

=item 2

An C<import()> method is installed (e.g. in the above example, that
becomes C<My::Role::import>). This may cause conflicts if C<My::Role>
has an import method. (It's exceedingly rare that a role would have an
C<import> method.)  This import method is used when the tag role is
itself imported, e.g. in the above example,

  package My::Module;
  use My::Role;  # <---- My::Role's import routine is called here

This C<import> does two things. In the above example, it 

=over

=item 1

applies the role C<My::Role> to C<My::Module>;

=item 2

modifies the L<Moo> C<has> attribute creator so that calls to C<has>
in C<My::Module> track attributes with tags.

=back

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-moox-taggedattributes@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-taggedattributes

and may be cloned from

  https://gitlab.com/djerius/moox-taggedattributes.git

=head1 INTERNAL ROUTINES

These routines are B<not> meant for public consumption, but are
documented here for posterity.

=head2 role_import

This import method is installed into tag roles (i.e. roles which
import L<MooX::TaggedAttributes>).  The result is that when a tag role
is imported, via e.g.

   package My::Module
   use My::TagRole;

=over

=item *

The role will be applied to the importing module (e.g., C<My::Module>), providing the C<_tags> and
C<_tag_list> methods.

=item *

The Moo C<has> routine in C<My::Module> will be modified to track attributes with tags.

=back

=head2 install_tags

   install_tags( $target, %opt );

This subroutine associates a list of tags with a class.  The first time this is called
on a class it also calls L</install_tag_handler>.  For subsequent calls it appends
the tags to the class' list of tags.

C<%opt> may contain C<tag_handler> which is a coderef for a tag handler.

C<%opt> must contain either C<tags>, an arrayref of tags, or C<class>, the name of a class
which as already been registered with L<MooX::TaggedAttributes>.

=head2 install_tag_handler

   install_tag_handler( $class, $factory );

This installs a wrapper around the C<has> routine in C<$class>. C<$factory>
is called as C<< $factory->($class) >> and should return a wrapper compatible
with L<Class::Method::Modifiers/around>.

=head2 make_tag_handler

  $coderef = make_tag_handler( $target_class );

A tag handler factory returning a coderef which wraps the
C<$target_class::_tag_list> method to add the tags in
C<$TAGSTORE{$target}> to its return value.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
