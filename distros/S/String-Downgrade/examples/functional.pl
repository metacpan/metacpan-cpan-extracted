#!/usr/bin/perl -w

use strict;
use utf8;
use String::Downgrade::Amharic;

my @list = downgrade ( "ዓለም" );
my $count = 0;
foreach (@list) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
@list = downgrade ( "ፀሐይ" );
$count = 0;
foreach (@list) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
$count = 0;
foreach ( downgrade ( "ኹኔታ" ) ) {
	$count++;
	printf "%2i: $_\n", $count;
}
print "----------------\n";
$count = 0;
foreach ( downgrade ( "ኀይለ ሥላሴ" ) ) {
	$count++;
	printf "%2i: $_\n", $count;
}


__END__

=head1 NAME

functional.pl - Amharic downgrade demonstrator for 5 sample words (Functional Usage).

=head1 SYNOPSIS

./functional.pl

=head1 DESCRIPTION

This is a simple demonstration script that generates decayed, though
accpetable, forms of sample canonical words.  The script demonstrates
usage of the functional interface to the L<String::Downgrade::Amharic> package.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<String::Downgrade::Amharic>

=cut
