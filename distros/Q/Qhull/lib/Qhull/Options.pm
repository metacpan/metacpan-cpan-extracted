package Qhull::Options;

# ABSTRACT: A container for Qhull to minimize re-parsing

use v5.26;
use strict;
use warnings;
use experimental 'signatures', 'declared_refs';
use Storable 'dclone';
use Scalar::Util 'blessed';
use List::Util 'first';

our $VERSION = '0.01';

use Readonly::Tiny 'readonly', 'readwrite';
use Qhull::Util::Options 'parse_options', -categories, -options;
use Qhull::Util 'supported_output_format';

use namespace::clean;

our @CARP_NOT = qw( Qhull::PP Qhull::Util::Options );

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

my sub _new ( $class, $attr ) {
    my $self = bless $attr, $class;
    readonly \$self;
    return $self;
}









sub new_from_options ( $class, $user_options ) {
    return _new( $class, { by_position => parse_options( $user_options ) } );
}











sub new_from_specs ( $class, $specs = [] ) {
    readonly $specs;
    return _new( $class, { by_position => $specs } );
}










sub clone_with_specs ( $self, $added_specs = [] ) {

    require Storable;
    my @old_specs = readwrite( dclone $self->{by_position} )->@*;

    my %specs;
    @specs{ map { $_->[0] } $added_specs->@* } = ();

    my @new_specs = grep { !exists $specs{ $_->[0] } } @old_specs;
    push @new_specs, $added_specs->@*;
    return blessed( $self )->new_from_specs( \@new_specs );
}










sub clone_with_options ( $self, $options = [] ) {
    return $self->clone_with_specs( parse_options( $options ) );
}

































sub filter_args ( $self, %opts ) {

    my %passthrough;
    @passthrough{ ( $opts{passthrough} // [] )->@* } = ();

    # always pass through TI and TO
    @passthrough{ 'TI', 'TO' } = ();

    state %strip;
    @strip{ CAT_INPUT, CAT_INPUT_FORMAT, CAT_OUTPUT, CAT_OUTPUT_GEOM } = ();

    my @opts;
    my %stripped = map { $_ => [] } keys %strip;
    for my $opt ( $self->{by_position}->@* ) {
        my $option = $opt->[1];
        next if $option->{strip};
        if ( exists $passthrough{ $option->{name} } ) {
            push @opts, $opt;
        }
        elsif ( exists $strip{ $option->{category} } ) {
            push $stripped{ $option->{category} }->@*, $opt;
        }
        elsif ( $option->{category} eq CAT_OUTPUT_FORMAT ) {
            croak( "unsupported output format: $option->{name}" )
              unless supported_output_format( $option->{name} );
            push @opts, $opt;
        }
        else {
            push @opts, $opt;
        }
    }

    return blessed( $self )->new_from_specs( \@opts );
}









sub specs ( $self ) {

    return $self->{by_position};
}









sub qhull_opts ( $self ) {

    $self->{qhull_opts}
      //= readonly [ map { $_->@[ 0, $_->@* == 3 ? 2 : () ]; } $self->{by_position}->@*, ];

    return $self->{qhull_opts};
}




























sub by_category ( $self ) {

    if ( !defined $self->{by_category} ) {
        my %by_category;
        for my $spec ( $self->{by_position}->@* ) {
            my $option   = $spec->[1];
            my $category = $by_category{ $option->{category} } //= { by_name => {}, by_position => [] };
            $category->{by_name}{ $option->{name} } = $spec;
            push $category->{by_position}->@*, $spec;
        }
        $self->{by_category} = \%by_category;
        readonly $self->{by_category};
    }

    return $self->{by_category};

}









sub by_name ( $self ) {

    if ( !defined $self->{by_name} ) {
        my %by_name = map { $_->[0]{name} => $_ } $self->{by_position}->@*;
        $self->{by_name} = \%by_name;
        readonly $self->{by_name};
    }

    return $self->{by_name};
}

my sub extract_Tx ( $self, $Tx ) {
    my $entry = first { $_->[0] eq $Tx } $self->{by_position}->@*;
    return defined $entry ? $entry->[-1] : undef;
}









sub TI ( $self ) {
    return exists $self->{ +OPTION_TI }
      ? $self->{ +OPTION_TI }
      : $self->{ +OPTION_TI } = extract_Tx( $self, OPTION_TI );
}
sub input;
*input = \&TI;









sub TO ( $self ) {
    return exists $self->{ +OPTION_TO }
      ? $self->{ +OPTION_TO }
      : $self->{ +OPTION_TO } = extract_Tx( $self, OPTION_TO );
}
sub output;
*output = \*TO;








sub has_compute ( $self ) {
    return !!0 unless exists $self->by_category->{ +CAT_COMPUTE };
    my $compute = exists $self->by_category->{ +CAT_COMPUTE };
    return !!( defined( $compute ) && $compute->{by_position}->@* );
}







sub has_output_format ( $self ) {
    return !!0 unless exists $self->by_category->{ +CAT_OUTPUT_FORMAT };
    my $compute = $self->by_category->{ +CAT_OUTPUT_FORMAT };
    return !!( defined( $compute ) && $compute->{by_position}->@* );
}


1;
#
# This file is part of Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory passthrough qhull
readonly

=head1 NAME

Qhull::Options - A container for Qhull to minimize re-parsing

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 CONSTRUCTORS

=head2 new_from_options

   $obj = Qhull::Options->new_from_options( \@qhull_options );

Parse a list of B<qhull> options and return an B<Qhull::Options> object.

=head2 new_from_specs

   $obj = Qhull::Options->new_from_specs( \@qhull_specs );

Create a B<Qhull::Options> object from a list of specifications in
the same format returned by L<Qhull::Util::Options/parse_options>.
The specifications are used directly and made readonly.

=head1 METHODS

=head2 clone_with_specs

  $new_obj = $obj->clone_with_specs( \@new_specs );

Clone B<$obj> appending the specified specs.  If an existing option is
also specified in @new_specs, it is removed from the existing specs.

=head2 clone_with_options

  $new_obj = $obj->clone_with_specs( \@new_options );

Clone B<$obj> appending the specified options.  If an existing option
is also specified in B<@new_options>, it is removed.

=head2 filter_args

  $new_obj = $obj->filter_args( %options );

Filter out B<qhull> arguments in the categories

    CAT_INPUT
    CAT_INPUT_FORMAT
    CAT_OUTPUT
    CAT_OUTPUT_GEOM

as they will break input or output parsing and don't add anything we need.

Note that the B<TI> and B<TO> options are I<never> filtered out, as they
are handled explicitly.

B<%options> can have any of the following entries:

=over

=item *

passthrough

An arrayref of B<qhull> options to pass through.  Be careful, as
they may break output parsing.

=back

=head2 specs

   \@specs = $obj->specs;

Return the list of option specs;  these are immutable.

=head2 qhull_opts

  \@options = $obj->qhull_opts;

Return a list of options in a form that B<qhull> will recognize

=head2 by_category

   \%by_category = $obj->by_category;

Return a hash containing the options specified in the C<$obj> object.  The hash is keyed off of the
category name.  Each value is a hash with two entries:

=over

=item *

by_name

A hashref keyed off of the option names. Values are the option specifications.

=item *

by_position

An arrayref holding the option specifications for this category in the
order they were passed to the object constructor.

=back

=head2 by_name

  \%hash = $obj->by_name;

Return a hash of option specs keyed off of option names.

=head2 TI

=head2 input

Returns I<undef> if the B<TI> option was not specified, otherwise its value.

=head2 TO

=head2 output

Returns I<undef> if the B<TO> option was not specified, otherwise its value.

=head2 has_compute

Returns true if a CAT_COMPUTE option was specified

=head2 has_output_format

Returns true if a CAT_OUTPUT_FORMAT option was specified

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/p5-qhull

and may be cloned from

  https://gitlab.com/djerius/p5-qhull.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Qhull|Qhull>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
