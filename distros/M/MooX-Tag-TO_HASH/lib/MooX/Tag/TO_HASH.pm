package MooX::Tag::TO_HASH;

# ABSTRACT: Controlled translation of Moo objects into Hashes

use v5.10;

use strict;
use warnings;

our $VERSION = '0.03';

use Safe::Isa;
use Ref::Util qw( is_ref is_blessed_ref is_arrayref is_hashref );
use MooX::Tag::TO_HASH::Util ':all';

sub _process_value {

    return \$_[0] unless is_ref( $_[0] );    ## no critic

    my $ref   = $_[0];
    my $value = $ref;

    if ( is_blessed_ref( $ref ) ) {
        # turtles all the way down...
        my $mth = $ref->$_can( UC_TO_HASH );
        $value = $ref->$mth if defined $mth;
    }
    elsif ( is_arrayref( $ref ) ) {
        my %new;
        for my $idx ( 0 .. @{$ref} - 1 ) {
            my $ref = _process_value( $ref->[$idx] );
            $new{$idx} = $$ref if defined $ref;
        }
        if ( keys %new ) {
            my @replace = @$ref;
            $replace[$_] = delete $new{$_} for keys %new;
            $value = \@replace;
        }
    }
    elsif ( is_hashref( $ref ) ) {
        my %new;
        for my $key ( keys %$ref ) {
            my $ref = _process_value( $ref->{$key} );
            $new{$key} = $$ref if defined $ref;
        }
        if ( keys %new ) {
            my %replace = %$ref;
            $replace{$_} = delete $new{$_} for keys %new;
            $value = \%replace;
        }
    }

    return \$value;
}

use Moo::Role;
use MooX::TaggedAttributes -propagate,
  -tags    => LC_TO_HASH,
  -handler => sub { make_tag_handler( LC_TO_HASH ) };

use namespace::clean -except => [ '_tags', '_tag_list' ];









sub TO_HASH {
    my $self = shift;

    my $to_hash = $self->_tags->tag_attr_hash->{ +LC_TO_HASH } // {};

    # the structure of %to_hash is complicated because has() may take
    # multiple attributes.  For example,

    # has ['foo','bar'] => ( is => 'ro', to_hash => '1' );

    # results in %to_hash looking like this:

    # bar => {
    #          bar => { omit_if_empty => 0, predicate => "has_bar" },
    #          foo => { omit_if_empty => 0, predicate => "has_foo" },
    #        },
    # foo => {
    #          bar => { omit_if_empty => 0, predicate => "has_bar" },
    #          foo => { omit_if_empty => 0, predicate => "has_foo" },
    #        },

    my %hash;
    for my $attr ( keys %{$to_hash} ) {
        my $opt = $to_hash->{$attr}{$attr};
        # hashes returned by the _tags method are readonly, so need to
        # check if key exists before querying it to avoid an exception
        next
          if exists $opt->{ +IF_EXISTS }
          && !$self->${ \$opt->{ +PREDICATE } };

        next
          if exists $opt->{ +IF_DEFINED }
          && !defined $self->${ \$attr };

        my $name
          = exists $opt->{ +ALT_NAME }
          ? $opt->{ +ALT_NAME } // $attr
          : $attr;

        my $value = $self->$attr;

        # return 'as is' if we're not supposed to recurse, or $value
        # is a normal scalar
        if ( exists $opt->{ +NO_RECURSE } ) {
            # do nothing
        }
        # possibly turtles all the way down...
        else {
            my $ref_to_value = _process_value( $value );
            $value = ${$ref_to_value} if defined $ref_to_value;
        }

        $hash{$name} = $value;
    }

    if ( defined ( my $mth = $self->can( 'modify_hashr' ) ) ) {
        $self->$mth( \%hash );
    }

    return \%hash;
}




1;

#
# This file is part of MooX-Tag-TO_HASH
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

MooX::Tag::TO_HASH - Controlled translation of Moo objects into Hashes

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 package My::Farm;
 
 use Moo;
 with 'MooX::Tag::TO_HASH';
 
 has cow            => ( is => 'ro', to_hash => 1 );
 has duck           => ( is => 'ro', to_hash => 'goose,if_exists', );
 has horse          => ( is => 'ro', to_hash => ',if_defined', );
 has hen            => ( is => 'ro', to_hash => 1, );
 has secret_admirer => ( is => 'ro', );
 
 # and somewhere else...
 
 use Data::Dumper;
 my $farm = My::Farm->new(
     cow            => 'Daisy',
     duck           => 'Frank',
     secret_admirer => 'Fluffy',
 );
 
 print Dumper $farm->TO_HASH;

# resulting in

 $VAR1 = {
           'cow' => 'Daisy',
           'hen' => undef,
           'goose' => 'Frank'
         };

=head1 DESCRIPTION

C<MooX::Tag::TO_HASH> is a L<Moo::Role> which provides a controlled method of converting your
L<Moo> based object into a hash.

Simply mark each field that should be output with the special option
C<to_hash> when declaring it:

    has field => ( is => 'ro', to_hash => 1 );

and call the L</TO_HASH> method on your instantiated object.

   my %hash = $obj->TO_HASH;

Fields inherited from superclasses or consumed from roles which use
C<MooX::Tag::TO_HASH> are automatically handled.

If a field's value is another object, L</TO_HASH> will automatically
turn that into a hash if it has its own C<TO_HASH> method (you can
also prevent that).

=head2 Modifying the generated hash

[Originally, this module recommended using a method modifier to the
L<TO_HASH> method, this is no longer recommended. See discussion
under L<DEPRECATED BEHAVIOR> below.].

If the class provides a C<modify_hashr> method, it will be called as

    $self->modify_hashr( \%hash );

and should modify the passed hash in place.

=head2 Usage

Add the C<to_hash> option to each field which should be
included in the hash.  C<to_hash> can either take a value of C<1>,
e.g.

    has field => ( is => 'ro', to_hash => 1 );

or a string which looks like one of these:

   alternate_name
   alternate_name,option_flag,option_flag,...
   ,option_flag,option_flag,...

If C<alternate_name> is specified, that'll be the key used in the
output hash.

C<option_flag> may be one of the following:

=over

=item C<if_exists>

Only output the field if it was set. This uses L</Moo>'s attribute
predicate (one will be added to the field if it not already
specified).

It I<will> be output if the field is set to C<undef>.

A synonym for this is C<omit_if_empty>, for compatibility with
L<MooX::TO_JSON>.

=item C<if_defined>

Only output the field if it was set and its value is defined.

=item C<no_recurse>

If a field is an object, don't try and turn it into a hash via its
C<TO_HASH> method.

(Yes, this name is backwards, but eventually a separate C<recurse>
option may become available which limits the recursion depth).

=back

=head1 METHODS

=head2 TO_HASH

  %hash = $obj->TO_HASH

This method is added to the consuming class or role.

=head1 EXAMPLES

=head2 Modifying the generated hash

 package My::Test::C4;
 
 use Moo;
 with 'MooX::Tag::TO_HASH';
 
 has cow            => ( is => 'ro', to_hash => 1 );
 has duck           => ( is => 'ro', to_hash => 'goose,if_exists', );
 has horse          => ( is => 'ro', to_hash => ',if_defined', );
 has hen            => ( is => 'ro', to_hash => 1, );
 has secret_admirer => ( is => 'ro', );
 
 # upper case the hash keys
 sub modify_hashr {
     my ( $self, $hashr ) = @_;
     $hashr->{ uc $_ } = delete $hashr->{$_} for keys %$hashr;
 };
 
 # and elsewhere:
 use Data::Dumper;
 
 print Dumper(
     My::Test::C4->new(
         cow            => 'Daisy',
         hen            => 'Ruby',
         duck           => 'Donald',
         horse          => 'Ed',
         secret_admirer => 'Nemo'
     )->TO_HASH
 );

# resulting in

 $VAR1 = {
           'HORSE' => 'Ed',
           'GOOSE' => 'Donald',
           'COW' => 'Daisy',
           'HEN' => 'Ruby'
         };

=head1 DEPRECATED BEHAVIOR

=head2 Using method modifiers to modify the results

Previously it was suggested that the C<around> method modifier be used
to modify the resultant hash. However, if both a child and parent
class consume the C<MooX::Tag::TO_HASH> role and the parent has
modified C<TO_HASH>, the parent's modified C<TO_HASH> will not be run;
instead the original C<TO_HASH> will. For example

 package Role {
     use Moo::Role;
     sub foo { print "Role\n" }
 }
 
 package Parent {
     use Moo;
     with 'Role';
     before 'foo' => sub { print "Parent\n" };
 }
 
 package Child {
     use Moo;
     extends 'Parent';
     with 'Role';
     before 'foo' => sub { print "Child\n" };
 }
 
 Child->new->foo;

results in

 Child
 Role

Note it does not output C<Parent>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-moox-tag-to_hash@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Tag-TO_HASH

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-tag-to_hash

and may be cloned from

  https://gitlab.com/djerius/moox-tag-to_hash.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooX::Tag::TO_JSON - the sibling class to this one.|MooX::Tag::TO_JSON - the sibling class to this one.>

=item *

L<MooX::TO_JSON - this is similar, but doesn't handle fields inherited from super classes or consumed from roles.|MooX::TO_JSON - this is similar, but doesn't handle fields inherited from super classes or consumed from roles.>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
