package MooX::Tag::TO_HASH::Util;

use v5.10;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';

use Sub::Util qw( set_subname );


our %CONSTANTS;

BEGIN {
    %CONSTANTS = (
        LC_TO_JSON => 'to_json',
        LC_TO_HASH => 'to_hash',
        UC_TO_JSON => 'TO_JSON',
        UC_TO_HASH => 'TO_HASH',
        map { uc( $_ ) => $_ } 'omit_if_empty',
        'if_exists', 'if_defined', 'no_recurse', 'alt_name', 'predicate',
        'type',      'bool',       'num',        'str'
    );
}

use constant \%CONSTANTS;

use constant TYPES => ( BOOL, NUM, STR );

our %EXPORT_TAGS = ( all => [ 'make_tag_handler', keys %CONSTANTS ] );
our @EXPORT_OK   = ( map { @$_ } values %EXPORT_TAGS );

our %ALLOWED = (
    +( LC_TO_JSON ) => {
        map { $_ => undef } OMIT_IF_EMPTY,
        IF_EXISTS, IF_DEFINED, BOOL, NUM, STR
    },
    +( LC_TO_HASH ) =>
      { map { $_ => undef } OMIT_IF_EMPTY, IF_EXISTS, IF_DEFINED, NO_RECURSE },
);

sub _croak {
    require Carp;
    goto \&Carp::croak;
}






sub make_tag_handler {
    my ( $tag ) = @_;
    my $package = caller();

    my $allowed = $ALLOWED{$tag};

    _croak( "unsupported tag: $tag" )
      unless defined $allowed;

    set_subname "$package\::tag_handler" => sub {
        my ( $orig, $attrs, %opt ) = @_;
        my $spec = $opt{$tag};

       # if no to_$tag, or to_$tag has been processed (e.g. it's now a json ref)
       # pass on to original routine.
        return $orig->( $attrs, %opt )
          if !defined $spec || ref( $spec );

        my %spec;
        if ( $spec ne '1' ) {
            my ( $alt_name, @stuff ) = split( ',', $spec );
            defined $_ and _croak( "unknown option: $_ " )
              for grep { !exists $allowed->{$_} } @stuff;
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

            if ( $tag eq UC_TO_JSON ) {
                $spec{ +TYPE } = do {
                    my ( $type, @types ) = grep exists $spec{$_}, TYPES;
                    _croak( "specify exactly zero or one of "
                          . join( ', ', TYPES ) )
                      if @types;
                    $type;
                };
            }

            $spec{ +IF_EXISTS } = delete $spec{ +OMIT_IF_EMPTY }
              if exists $spec{ +OMIT_IF_EMPTY };

            $opt{ +PREDICATE } //= '1'
              if $spec{ +IF_EXISTS };
        }


        # if there is more than one attribute being defined by this
        # has call, we can either call has multiple times, setting the
        # tag value individually for each, or we can call has a single
        # time, as the user has done, but then the tag value has to
        # have the same value for both.  We choose the latter, just in
        # case the underlying Moo::has code does something special.
        # but this results in duplicate information (see the top level
        # TO_HASH and TO_JSON implementations for more info).

        my %to;
        for my $attr ( ref $attrs ? @{$attrs} : $attrs ) {
            $to{$attr} = {%spec};
            if ( $spec{ +IF_EXISTS } ) {
                $opt{ +PREDICATE } //= 1;
                $to{$attr}{ +PREDICATE }
                  = $opt{ +PREDICATE } eq '1'
                  ? 'has_' . $attr
                  : $opt{ +PREDICATE };
            }
        }
        $opt{$tag} = \%to;
        return $orig->( $attrs, %opt );
    };
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

MooX::Tag::TO_HASH::Util

=head1 VERSION

version 0.03

=for Pod::Coverage make_tag_handler

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

L<MooX::Tag::TO_HASH|MooX::Tag::TO_HASH>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
