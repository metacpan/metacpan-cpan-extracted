#!/usr/bin/perl -w

use strict;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
require String::Equivalence::Amharic;

my $string = new String::Equivalence::Amharic;

my @list = $string->downgrade ( "ዓለም" );
my $count = 0;
foreach (@list) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
@list = $string->downgrade ( "ፀሐይ" );
$count = 0;
foreach (@list) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
$count = 0;
foreach ($string->downgrade ( "ኹኔታ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
$count = 0;
foreach ($string->downgrade ( "ኀይለ ሥላሴ" )) {
	$count++;
	printf "%2i: $_\n", $count;
}


__END__

=head1 NAME

downgrade.pl - Amharic downgrade demonstrator for 5 sample words (OO Usage).

=head1 SYNOPSIS

./downgrade.pl

=head1 DESCRIPTION

This is a simple demonstration script that generates decayed, though
accpetable, forms of sample canonical words.  The script demonstrates
usage of the OO interface to the L<String::Equivalence::Amharic> package.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<String::Equivalence::Amharic>

=cut
