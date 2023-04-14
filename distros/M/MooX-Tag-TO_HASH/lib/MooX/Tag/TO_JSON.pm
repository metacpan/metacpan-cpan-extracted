package MooX::Tag::TO_JSON;

# ABSTRACT: Controlled translation of Moo objects into JSON appropriate Hashes

use v5.10;

use strict;
use warnings;

our $VERSION = '0.05';

use Safe::Isa;
use JSON::MaybeXS ();
use MooX::Tag::TO_HASH::Util ':all';

use Moo::Role;
use MooX::TaggedAttributes -propagate,
  -tags    => LC_TO_JSON,
  -handler => sub { make_tag_handler( LC_TO_JSON ) };

use namespace::clean -except => [ '_tags', '_tag_list' ];









sub TO_JSON {
    my $self = shift;

    my $to_json = $self->_tags->tag_attr_hash->{ +LC_TO_JSON } // {};

    # the structure of %to_json is complicated because has() may take
    # multiple attributes.  For example,

    # has ['foo','bar'] => ( is => 'ro', to_json => '1' );

    # results in %to_json looking like this:

    # bar => {
    #          bar => { omit_if_empty => 0, predicate => "has_bar" },
    #          foo => { omit_if_empty => 0, predicate => "has_foo" },
    #        },
    # foo => {
    #          bar => { omit_if_empty => 0, predicate => "has_bar" },
    #          foo => { omit_if_empty => 0, predicate => "has_foo" },
    #        },

    my %json;
    for my $attr ( keys %{$to_json} ) {

        # TBH, all of this should have been put into a bespoke
        # generated sub in the tag_handler.

        my $opt = $to_json->{$attr}{$attr};
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

        if ( defined $value ) {
            # force types
            if ( exists $opt->{ +BOOL } ) {
                $value = $value ? JSON::MaybeXS::true : JSON::MaybeXS::false;
            }
            elsif ( exists $opt->{ +NUM } ) {
                $value = 0+ $value;
            }
            elsif ( exists $opt->{ +STR } ) {
                $value = q{} . $value;
            }
        }
        $json{$name} = $value;
    }

    if ( defined( my $mth = $self->can( '_modify_jsonr' ) // $self->can( 'modify_jsonr' ) ) ) {
        $self->$mth( \%json );
    }
    elsif ( defined( $mth = $self->can( 'modify_json' ) ) ) {
        %json = $self->$mth( %json );
    }

    return \%json;
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

MooX::Tag::TO_JSON - Controlled translation of Moo objects into JSON appropriate Hashes

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 package My::Farm;
 
 use Moo;
 with 'MooX::Tag::TO_JSON';
 
 has cow              => ( is => 'ro', to_json => 1 );
 has duck             => ( is => 'ro', to_json => 'goose,if_exists', );
 has horse            => ( is => 'ro', to_json => ',if_defined', );
 has hen              => ( is => 'ro', to_json => 1, );
 has barn_door_closed => ( is => 'ro', to_json => ',bool' );
 has secret_admirer   => ( is => 'ro', );
 
 # and somewhere else...
 
 use Data::Dumper;
 my $farm = My::Farm->new(
     cow              => 'Daisy',
     duck             => 'Frank',
     barn_door_closed => 0,
     secret_admirer   => 'Fluffy',
 );
 
 print Dumper $farm->TO_JSON;

# resulting in

 $VAR1 = {
           'hen' => undef,
           'cow' => 'Daisy',
           'goose' => 'Frank',
           'barn_door_closed' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' )
         };

=head1 DESCRIPTION

C<MooX::Tag::TO_JSON> is a L<Moo::Role> which provides a controlled
method of converting your L<Moo> based object into a hash appropriate
for passing to a JSON encoder.  It provides a L<TO_JSON> method which
is recognized by most (?) JSON encoders and used to serialize the
object.

Simply mark each field that should be output with the special option
C<to_json> when declaring it:

    has field => ( is => 'ro', to_json => 1 );

and call the L</TO_JSON> method on your instantiated object.

   my %hash = $obj->TO_JSON;

Fields inherited from superclasses or consumed from roles which use
C<MooX::Tag::TO_JSON> are automatically handled.

If a field's value is another object, L</TO_JSON> will automatically
turn that into a hash if it has its own C<TO_JSON> method (you can
also prevent that).

=head2 Modifying the generated JSON

[Originally, this module recommended using a method modifier to the
L<TO_JSON> method, this is no longer recommended. See discussion
under L<DEPRECATED BEHAVIOR> below.].

If the class provides a C<_modify_jsonr> method (or, for backwards
capability, C<modify_jsonr>), it will be called as

    $self->_modify_jsonr( \%json );

and should modify the passed hash in place.

For compatibility with L<MooX::TO_JSON>, if the class provides a
C<modify_json> method it will be called as

    %json = $self->modify_json( %json );

=head2 Usage

Add the C<to_json> option to each field which should be
included in the json.  C<to_json> can either take a value of C<1>,
e.g.

    has field => ( is => 'ro', to_json => 1 );

or a string which looks like one of these:

   alternate_name
   alternate_name,option_flag,option_flag,...
   ,option_flag,option_flag,...

If C<alternate_name> is specified, that'll be the key used in the
output json.

C<option_flag> may be one of the following:

=over

=item C<bool>

Force the value into a JSON Boolean context. Compatible with L<MooX::TO_JSON>.

=item C<int>

Force the value into a JSON numeric context. Compatible with L<MooX::TO_JSON>.

=item C<str>

Force the value into a JSON numeric context. Compatible with L<MooX::TO_JSON>.

=item C<if_exists>

Only output the field if it was set. This uses L</Moo>'s attribute
predicate (one will be added to the field if it not already
specified).

It I<will> be output if the field is set to C<undef>.

A synonym for this is C<omit_if_empty>, for compatibility with
L<MooX::TO_JSON>.

=item C<if_defined>

Only output the field if it was set and its value is defined.

=back

=head1 METHODS

=head2 TO_JSON

  %hash = $obj->TO_JSON

This method is added to the consuming class or role.

=head1 EXAMPLES

=head2 Modifying the generated json

 package My::Test::C4;
 
 use Moo;
 with 'MooX::Tag::TO_JSON';
 
 has cow              => ( is => 'ro', to_json => 1 );
 has duck             => ( is => 'ro', to_json => 'goose,if_exists', );
 has horse            => ( is => 'ro', to_json => ',if_defined', );
 has hen              => ( is => 'ro', to_json => 1, );
 has barn_door_closed => ( is => 'ro', to_json => ',bool' );
 has secret_admirer   => ( is => 'ro', );
 
 # upper case the json keys
 sub modify_jsonr {
     my ( $self, $jsonr ) = @_;
     $jsonr->{ uc $_ } = delete $jsonr->{$_} for keys %$jsonr;
 };
 
 # and elsewhere:
 use Data::Dumper;
 
 print Dumper(
     My::Test::C4->new(
         cow              => 'Daisy',
         hen              => 'Ruby',
         duck             => 'Donald',
         horse            => 'Ed',
         barn_door_closed => 1,
         secret_admirer   => 'Nemo'
     )->TO_JSON
 );

# resulting in

 $VAR1 = {
           'HEN' => 'Ruby',
           'COW' => 'Daisy',
           'BARN_DOOR_CLOSED' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
           'GOOSE' => 'Donald',
           'HORSE' => 'Ed'
         };

=head1 DEPRECATED BEHAVIOR

=head2 Using method modifiers to modify the results

Previously it was suggested that the C<before> method modifier be used
to modify the resultant hash. However, if both a child and parent
class consume the C<MooX::Tag::TO_JSON> role and the parent has
modified C<TO_JSON>, the parent's modified C<TO_HASH> will not be run;
instead the original C<TO_HASH> will. For example,

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

Please report any bugs or feature requests to bug-moox-tag-to_hash@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Tag-TO_HASH>

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-tag-to_hash

and may be cloned from

  https://gitlab.com/djerius/moox-tag-to_hash.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooX::Tag::TO_HASH|MooX::Tag::TO_HASH>

=item *

L<MooX::Tag::TO_HASH - sibling class to this one.|MooX::Tag::TO_HASH - sibling class to this one.>

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
