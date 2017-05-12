package OpenOffice::Wordlist;

use strict;
use warnings;

=head1 NAME

OpenOffice::Wordlist - Read/write OpenOffice.org wordlists

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This module allows reading and writing of OpenOffice.org wordlists
(dictionaries).

For example:

  use OpenOffice::Wordlist;

  my $dict = OpenOffice::Wordlist->new;
  $dict->read(".openoffice.org/3/user/wordlist/standard.dic");

  # Print all words.
  foreach my $word ( @{ $dict->words } ) {
      print $word, "\n";
  }

  # Add some words.
  $dict->append( "openoffice", "great" );

  # Write a new dictionary.
  $dict->write("new.dic");

When used as a program this module will read all dictionaries given on
the command line and write the resultant list of words to standard
output. For example,

  $ perl OpenOffice/Wordlist.pm standard.dic

=head1 METHODS

=head2 $dict = new( [ type => 'WDSWG6', language => 2057, neg => 0 ] )

Creates a new dict object.

Optional arguments:

type => 'WBSWG6' or 'WBSWG2' or 'WBSWG5'.

'WBSWG6' (default) indicates a UTF-8 encoded dictionary, the others
indicate a ISO-8859.1 encoded dictionary.

language => I<code>

The code for the language. I assume there's an extensive list of these
codes somewhere. Some values determined experimentally:

    255   All
   1031   German (Germany)
   1036   French (France)
   1043   Dutch (Netherlands)
   2047   English UK
   2057   English USA

neg => 0 or 1

Whether the dictionary contains exceptions (neg = 1) or regular words
(neg = 0).

If language and neg are not specified they are taken from the first
file read, if any.

=cut

use Encode;

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless { type => 'WBSWG6', words => [], %opts }, $pkg;
    $self->_set_type( $self->{type} );
    return $self;
}

=head2 $dict->read( $file )

Reads the contents of the indicated file. 

=cut

sub read {
    my ( $self, $file ) = @_;
    open( my $dict, '<:raw', $file )
      or die("$file: $!\n");

    my $data = do { local $/; <$dict> };
    die( "$file: Invalid dict type\n")
      unless substr( $data, 0, 8, '' ) =~ /\x06\x00(WBSWG[256])/;
    my $type = $self->_set_type($1);

    my $lang = substr( $data, 0, 2, '' );
    $self->{language} = unpack( "v", $lang )
      unless defined $self->{language};

    my $neg = substr( $data, 0, 1, '' );
    $self->{neg} = unpack( "C", $neg )
      unless defined $self->{neg};;

    while ( $data ) {
	my $length = substr( $data, 0, 2, '' );
	$length = unpack( "v", $length );
	push( @{$self->{words}},
	      decode( $self->{encoding}, substr( $data, 0, $length, '' ) ) );
    }

    $self->_set_type($type) if $type;
    return $self;
}

# Internal.
sub _set_type {
    my ( $self, $type ) = @_;
    ( $self->{type}, $type) = ( $type, $self->{type} );
    $self->{encoding} = $self->{type} eq 'WBSWG6' ? 'utf-8' : 'iso-8859-1';
    return $type;		# previous type
}

=head2 $dict->append( @words )

Append a list of words to the dictionary. To avoid unpleasant
surprises, the words must be encoded in Perl's internal encoding.

The arguments may be constant strings or references to lists of strings.

=cut

sub append {
    my ( $self, @words ) = @_;

    foreach my $word ( @words ) {
	if ( UNIVERSAL::isa( $word, 'ARRAY' ) ) {
	    push( @{$self->{words}}, @$word );
	}
	else {
	    push( @{$self->{words}}, $word );
	}
    }

    return $self;
}

=head2 $dict->words

Returns a reference to the list of words in the dictionary,

The words are encoded in Perl's internal encoding.

=cut

sub words {
    my ( $self ) = @_;
    $self->{words};
}

=head2 $dict->write( $file [ , $type ] )

Writes the contents of the object to a new dictionary.

Arguments: The name of the file to be written, and (optionally) the
type of the file to be written (one of 'WBSWG6', 'WBSWG5', 'WBSWG2')
overriding the type of the dictionary as establised at create time.

=cut

sub write {
    my ( $self, $file, $type ) = @_;

    $type = $self->_set_type($type) if $type;

    open( my $dict, '>:raw', $file )
      or die("$file: $!\n");

    print { $dict } ( $self->__pfx( $self->{type} ),
		      pack( "v", $self->{language} || 0),
		      pack( "C", $self->{neg} || 0 ) );

    require bytes;

    foreach ( @{$self->{words}} ) {
	print { $dict } ( $self->__pfx($_) );
    }
    close($dict) or die("$file: $!\n");

    $type = $self->_set_type($type) if $type;

    return $self;
}

# Internal.
sub __pfx {
    my ( $self, $string ) = @_;
    $string = encode( $self->{encoding}, $string );
    pack( "v", bytes::length($string) ) . $string;
}

=head1 EXAMPLE

This example reads all dictionaries that are supplied on the command
file, merges them, and writes a new dictionary.

  my $dict = OpenOffice::Wordlist->new( type => 'WBSWG6' );
  $dict->read( shift );
  foreach ( @ARGV ) {
    my $extra = OpenOffice::Wordlist->new->read($_);
    $dict->append( $extra->words );
  }
  $dict->write("new.dic");

Settings like the language and exceptions are copied from the file
that is initially read.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

There's currently no checking done on dictionary types arguments.

Please report any bugs or feature requests to
C<bug-openoffice-wordlist at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenOffice-Wordlist>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenOffice::Wordlist

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenOffice-Wordlist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenOffice-Wordlist>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenOffice-Wordlist>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package main;

unless ( caller ) {
    binmode( STDOUT, ':encoding(utf-8)' );
    my $dict = OpenOffice::Wordlist->new( type => 'WBSWG6' );
    $dict->read( shift(@ARGV) );
    foreach ( @ARGV ) {
	my $extra = OpenOffice::Wordlist->new->read($_);
	$dict->append( $extra->words );
    }
    foreach ( @{ $dict->words } ) {
	print "$_\n";
    }
}

1;
