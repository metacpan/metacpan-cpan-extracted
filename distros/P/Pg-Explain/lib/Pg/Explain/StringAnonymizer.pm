package Pg::Explain::StringAnonymizer;
use strict;
use Carp;
use Digest::SHA qw( sha1 );
use warnings;
use strict;

=head1 NAME

Pg::Explain::StringAnonymizer - Class to anonymize sets of strings

=head1 VERSION

Version 0.80

=cut

our $VERSION = '0.80';

=head1 SYNOPSIS

This module provides a way to turn defined set of strings into anonymized version of it, that has 4 properties:

=over

=item * the same original string should give the same output string (within the same input set)

=item * strings shouldn't be very long

=item * it shouldn't be possible to reverse the operation

=item * generated strings should be easy to read, and easy to distinguish between themselves.

=back

Points first and third can be done easily with some hashing function (md5, sha), but generated hashes violate fourth point, and sometimes also second.

Example of usage:

    my $anonymizer = Pg::Explain::StringAnonymizer->new();
    $anonymizer->add( 'a', 'b', 'c');
    $anonymizer->add( 'depesz' );
    $anonymizer->add( [ "any strings, "are possible" ] );
    $anonymizer->finalize();

    print $anonymizer->anonymized( 'a' ), "\n";

    my $full_dictionary = $anonymizer->anonymization_dictionary();

=head1 METHODS

=head2 new

Object constructor, doesn't take any arguments.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{ 'strings' } = {};
    return $self;
}

=head2 add

Adds new string(s) to anonymization list.

Strings can be given either as list of ArrayRef.

It is important to note, that one cannot add() more elements to anonymized set after finalization (call to finalize() method).

If such call will be made (add() after finalize()) it will raise exception.

=cut

sub add {
    my $self = shift;
    croak( "Cannot run ->add() after finalization.\n" ) if $self->{ 'is_finalized' };

    my @input = @_;
    @input = @{ $input[ 0 ] } if 'ARRAY' eq ref( $input[ 0 ] );
    for my $string ( @input ) {
        next if $self->{ 'strings' }->{ $string };
        $self->{ 'strings' }->{ $string } = $self->_hash( $string );
    }
    return;
}

=head2 finalize

Finalizes string set creation, and creates anonymized versions.

It has to be called after some number of add() calls, so that it will have something to work on.

After running finalize() one cannot add() more string.

Also, before finalize() you cannot run anonymized() or anonymization_dictionary() methods.

=cut

sub finalize {
    my $self = shift;
    return if $self->{ 'is_finalized' };
    $self->{ 'is_finalized' } = 1;

    $self->_make_prefixes(
        'keys'  => [ keys %{ $self->{ 'strings' } } ],
        'level' => 0,
    );

    $self->_stringify();

    return;
}

=head2 anonymized

Returns anonymized version of given string, or undef if the string wasn't previously added to anonymization set.

If it will be called before finalize() it will raise exception.

=cut

sub anonymized {
    my $self = shift;
    croak( "Cannot run ->anonymized() before finalization.\n" ) unless $self->{ 'is_finalized' };
    my $input = shift;
    return $self->{ 'strings' }->{ $input };
}

=head2 anonymization_dictionary

Returns hash reference containing all input strings and their anonymized versions, like:

    {
        'original1' => 'anon1',
        'original2' => 'anon2',
        ...
        'originalN' => 'anonN',
    }

If it will be called before finalize() it will raise exception.

=cut

sub anonymization_dictionary {
    my $self = shift;
    croak( "Cannot run ->anonymization_dictionary() before finalization.\n" ) unless $self->{ 'is_finalized' };
    return $self->{ 'strings' };
}

=head1 INTERNAL METHODS

=head2 _hash

Converts given string into array of 32 integers in range 0..31.

This is done by taking sha1 checksum of string, splitting it into 32 5-bit
long "segments", and transposing each segment into integer.

=cut

sub _hash {
    my $self  = shift;
    my $input = shift;

    my $hash = sha1( $input );

    # sha1() (20 bytes) to 32 integers (0..31) transformation thanks to
    # mauke and LeoNerd on #perl on irc.freenode.net

    my $binary_hash = unpack( "B*", $hash );
    my @segments = unpack "(a5)*", $binary_hash;
    return [ map { oct "0b$_" } @segments ];
}

=head2 _word

Returns n-th word from number-to-word translation dictionary.

=cut

sub _word {
    my $self = shift;
    my $n    = shift;
    $n = 0 unless defined $n;
    $n = 0  if $n < 0;
    $n = 31 if $n > 31;
    my @words = qw(
        alpha     bravo      charlie    delta
        echo      foxtrot    golf       hotel
        india     juliet     kilo       lima
        mike      november   oscar      papa
        quebec    romeo      sierra     tango
        uniform   victor     whiskey    xray
        yankee    zulu       two        three
        four      five       six        seven
        );
    return $words[ $n ];
}

=head2 _make_prefixes

Scan given keys, and changes their values (in ->{'strings'} hash) to
shortest unique prefix.

=cut

sub _make_prefixes {
    my $self = shift;
    my %args = @_;

    my $S = $self->{ 'strings' };

    my %unique_ints = ();

    for my $key ( @{ $args{ 'keys' } } ) {
        my $KA              = $S->{ $key };
        my $interesting_int = $KA->[ $args{ 'level' } ];
        $unique_ints{ $interesting_int }++;
    }

    # At this moment, we know how many times given int happened at given
    # level, so we can make sensible decisions

    my %to_redo = ();

    for my $key ( @{ $args{ 'keys' } } ) {
        my $KA              = $S->{ $key };
        my $interesting_int = $KA->[ $args{ 'level' } ];
        if ( 1 == $unique_ints{ $interesting_int } ) {
            splice @{ $KA }, 1 + $args{ 'level' };
            next;
        }
        push @{ $to_redo{ $interesting_int } }, $key;
    }

    # In to_redo, we have blocks of keys, that share prefix (up to given
    # level), so they have to be further processed.

    for my $key_group ( values %to_redo ) {
        $self->_make_prefixes(
            'keys'  => $key_group,
            'level' => $args{ 'level' } + 1,
        );
    }

    return;
}

=head2 _stringify

Converts arrays of ints (prefixes for hashed words) into strings

=cut

sub _stringify {
    my $self = shift;

    for my $key ( keys %{ $self->{ 'strings' } } ) {
        my $ints = $self->{ 'strings' }->{ $key };
        my @words = map { $self->_word( $_ ) } @{ $ints };
        $self->{ 'strings' }->{ $key } = join( '_', @words );
    }
}

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain::StringAnonymizer

=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Pg::Explain::StringAnonymizer
