package TLV::Parser;
use strict;
use warnings;

our ( $VERSION );

BEGIN {
    $VERSION = '1.01';
}

sub new {
    my $class = shift;
    my $href  = shift;
    die "No tags defined!" unless scalar @{$href->{tag_aref}};
    my $self = {};
    my ($tag_href, $tag_len_href);
    foreach ( @{$href->{tag_aref}} ) {
        $tag_href->{$_} = undef;
        my $len         = length $_;
        $tag_len_href->{$len} = undef unless exists $tag_len_href->{$len};
    }
    $self->{tag} = $tag_href;
    $self->{tag_len} = [ keys %{$tag_len_href} ];
    $self->{l_len} = $href->{l_len} || 2;
    
    bless $self, $class;
}

sub parse {
    my $self = shift;
    my $tlv_string = shift || die "no string to parse?";
    my $l_len = $self->{l_len};
    my $result;

    while ( length $tlv_string > 0 ) {
        my $found;
        foreach my $t_len ( @{$self->{tag_len}} ) {
            my $tmp = substr($tlv_string, 0, $t_len);

            if ( exists $self->{tag}->{$tmp} ) {
                my $v_len = hex (substr $tlv_string, $t_len, $l_len);
                my $v = substr $tlv_string, ($t_len + $l_len), 2 * $v_len;
                $result->{$tmp} = $v;
                $found = 1;

                my $offset = $t_len + $l_len + 2 * $v_len;
                $tlv_string = substr $tlv_string, $offset;
                last if $found;
            }
        }
        unless ( $found ) {
            $self->{remain} = $tlv_string;
            $self->{error}  = "parsing incomplete";
            last;
        }
    }
    $self->{result} = $result;
}
1;
  
__END__ 

=head1 NAME

TLV::Parser - A module for parsing TLV strings

=head1 SYNOPSIS

use TLV::Parser;

$tlv = TLV::Parser->new( { tag_aref => ['80', '5F', '9F01'], l_len => 2, } );
$tlv->parse($tlv_string);

# Alternative: no l_len is passed in. The default l_len is 2.
$tlv = TLV::Parser->new( { tag_aref => ['80', '5F', '9F01'], } );
$tlv->parse($tlv_string);

=head1 DESCRIPTION

The TLV::Parser module, provides a simple interface for parsing TLV (Tag-Length-Value) or (Identifier-Length-Contents) strings. 
It takes in a hashref as the input: tag_aref points to the reference to the array of tags, and l_len is the number of bytes defined for the length segment in TLV. 

=head1 METHODS

=over 4

=item new(\%args)

Creates a new TLV::Parser object with the hashref as the input. tag_aref, which points to the array of tags, is mandatory. l_len, which is the number of bytes defined for length segment, is optional with default value of 2.

Parsing TLV string can be done by continuous regex or by cut the 'tag' segment from tlv string and compare it against the defined tags. This module is using cut and compary method, so it stores all the passed in tags into a hash, also store the set of the length of the tags in a hash.


=item parse($tlv_string)

Parses the specified TLV string and store the result in the object itself.
If the TLV string cannot be parsed completely, it will store the remaining segment and store error message 'parsing incomplete'
    'result' => '... ...',
    'remain' => '... ...', 
    'error'  => 'parsing incomplete',
After parsering, TLV (tag, value) pairs hash are pointed by 'result' in the object.

=back

=head1 AUTHOR

Guangsheng He <heguangsheng@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Guangsheng He 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut



