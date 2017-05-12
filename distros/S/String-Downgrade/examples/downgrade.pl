#!/usr/bin/perl -w

use strict;
use utf8;
require String::Downgrade::Amharic;

my $string = new String::Downgrade::Amharic;

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
usage of the OO interface to the L<String::Downgrade::Amharic> package.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<String::Downgrade::Amharic>

=cut
