package MooX::Tag::TO_HASH;

# ABSTRACT: Controlled translation of Moo objects into Hashes

use v5.10;

use strict;
use warnings;

our $VERSION = '0.01';

use Safe::Isa;
use Sub::Util qw( set_subname );

use constant ( {
    map { uc( $_ ) => $_ } 'omit_if_empty', 'if_exists',
    'if_defined',                           'no_recurse',
    'alt_name',                             'predicate'
} );
use constant ( { FTO_HASH => 'to_hash' } );

our %ALLOWED
  = ( map { $_ => undef } OMIT_IF_EMPTY, IF_EXISTS, IF_DEFINED, NO_RECURSE );

sub _croak {
    require Carp;
    goto \&Carp::croak;
}

sub make_tag_handler {

    set_subname __PACKAGE__ . '::tag_handler' => sub {
        my ( $orig, $attrs, %opt ) = @_;
        my $spec = $opt{ +FTO_HASH };

       # if no to_hash, or to_hash has been processed (e.g. it's now a hash ref)
       # pass on to original routine.
        return $orig->( $attrs, %opt )
          if !defined $spec || ref( $spec );

        my %spec;
        if ( $spec ne '1' ) {
            my ( $alt_name, @stuff ) = split( ',', $spec );
            defined $_ and _croak( "unknown option: $_ " )
              for grep { !exists $ALLOWED{$_} } @stuff;
            $spec{ +ALT_NAME } = $alt_name if length( $alt_name );
            $spec{$_} = 1 for @stuff;

            # consistency checks if more than one attribute is passed to has.
            if ( ref $attrs && @{$attrs} > 1 ) {
                _croak(
                    "can't specify alternate name if more than one attribute is defined"
                ) if exists $spec{ +ALT_NAME };
                _croak(
                    "can't specify predicate name if more than one attribute is defined"
                ) if defined $opt{ +PREDICATE } && $opt{ +PREDICATE } ne '1';
            }

            $spec{ +IF_EXISTS } = delete $spec{ +OMIT_IF_EMPTY }
              if exists $spec{ +OMIT_IF_EMPTY };

            $opt{ +PREDICATE } //= '1'
              if $spec{ +IF_EXISTS };
        }

        my %to_hash;
        for my $attr ( ref $attrs ? @{$attrs} : $attrs ) {
            $to_hash{$attr} = {%spec};
            if ( $spec{ +IF_EXISTS } ) {
                $opt{ +PREDICATE } //= 1;
                $to_hash{$attr}{ +PREDICATE }
                  = $opt{ +PREDICATE } eq '1'
                  ? 'has_' . $attr
                  : $opt{ +PREDICATE };
            }
        }
        $opt{ +FTO_HASH } = \%to_hash;
        return $orig->( $attrs, %opt );
    };
}

use Moo::Role;
use MooX::TaggedAttributes -propagate,
  -tags    => 'to_hash',
  -handler => \&make_tag_handler;

use namespace::clean -except => [ '_tags', '_tag_list' ];









sub TO_HASH {
    my $self = shift;

    my $to_hash = $self->_tags->tag_attr_hash->{to_hash} // {};

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
          && $opt->{ +IF_EXISTS }
          && !$self->${ \$opt->{ +PREDICATE } };

        next
          if exists $opt->{ +IF_DEFINED }
          && $opt->{ +IF_DEFINED }
          && !defined $self->${ \$attr };

        my $alt_name
          = exists $opt->{ +ALT_NAME }
          ? $opt->{ +ALT_NAME } // $attr
          : $attr;
        my $value = $self->$attr;
        if ( exists $opt->{ +NO_RECURSE } && $opt->{ +NO_RECURSE } ) {
            $hash{$alt_name} = $value;
        }
        else {
            # turtles all the way down...
            my $mth = $value->$_can( FTO_HASH );
            $hash{$alt_name} = defined $mth ? $value->$mth : $value;
        }
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

version 0.01

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
           'hen' => undef,
           'cow' => 'Daisy',
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

By applying a method modifier to the L<TO_HASH> method, you can modify
its output after the conversion.

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
 around TO_HASH => sub {
     my ( $orig, $obj ) = @_;
     my $hash = $obj->$orig;
     $hash->{ uc $_ } = delete $hash->{$_} for keys %$hash;
     return $hash;
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
           'COW' => 'Daisy',
           'HEN' => 'Ruby',
           'GOOSE' => 'Donald',
           'HORSE' => 'Ed'
         };

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

L<MooX::TO_JSON - this is similar, but doesn't handle fields inherited from super classes or consumed from roles.|MooX::TO_JSON - this is similar, but doesn't handle fields inherited from super classes or consumed from roles.>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
