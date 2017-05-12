package String::MFN;

require 5.008;
use warnings;
use strict;

use Encode;

require Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( &mfn );

=head1 NAME

String::MFN - Normalize a string to produce a sane Unix filename

=head1 VERSION

Version 1.29

=cut

our $VERSION = '1.29';

=head1 SYNOPSIS

    use String::MFN;

    my $clean = mfn($dirty);

=head1 DESCRIPTION

String::MFN exports a single function, C<mfn()>, which modifies a
string to resemble a sane Unix filename.

In a nutshell, this means lowercasing everything and either getting
rid of "funny" characters or replacing them with sane equivalents
which allow the string to maintain some structure. See the test suite
for a battery of examples.

=head1 FUNCTIONS

=head2 mfn

Normalizes a string. Returns the normalized string. If no argument is
given, C<$_> is used.

=cut

sub mfn {
    my $string = ( @_ ? $_[0] : $_ );
    Encode::_utf8_on($string);

    # phase 1 - sanitize
    $string =~ s/(\p{Lowercase})(\p{Uppercase})/$1_$2/g;  # inCap to in_Cap
    $string =~ s/[\{\[\(\<>)\]\}~\|\/]/-/g;               # {[(<>)]}~|/ to '-'
    $string =~ s/[\p{Zs}\t]+/_/g;                         # whitespace to '_'
    $string =~ s/\&+/_and_/g;                             # '&' to "_and_"
    $string =~ s/[^\p{Alphabetic}\p{Nd}\-\.\+_]//g;       # drop not-word chars

    # phase 2 - condense
    $string =~ s/_+-+/-/g;               # collapse _- sequences
    $string =~ s/-+_+/-/g;               # collapse -_ sequences
    $string =~ s/[\-\_]+\././g;          # collapse [-_]. sequences
    $string =~ s/\.[\-\_]+/./g;          # collapse .[-_] sequences
    $string =~ s/\-{2,}/-/g;             # collapse repeating -,
    $string =~ s/\_{2,}/_/g;             #                    _,
    $string =~ s/\.{2,}/./g;             #                and .
    $string =~ s/^(\-|\_|\.)+//;         # remove leading -_.
    $string =~ s/(\-|\_|\.)+$//;         # remove trailing -_. (rare)
    if ($string =~ /\.(\w+?)$/) {        # collapse repeating extensions
	my $ext = $1;
	$string =~ s/(\.$ext)+$/\.$ext/;
    }

    return lc($string);                   # slam lowercase
}

=head1 TODO

=over

=item *

Add "classic" ASCII-oriented function for extra strictness

=item *

Add track/sequence number stuff to mfn(1p)

=back

=head1 BUGS

=over

=item *

C<mfn()> forces Perl's C<_is_utf8> flag on, but does not attempt to
verify that the data being passed to it is valid UTF-8.

=back

Please report any bugs or feature requests to
C<bug-string-mfn@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Shawn Boyette, C<< <mdxi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2003-2007 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of String::MFN
