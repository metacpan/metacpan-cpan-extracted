#!/usr/bin/perl -w

require Regexp::Ethiopic::Amharic;

use strict;
use utf8;
binmode(STDOUT, ":utf8");


my $string = "([=አ=])ለም[=ጸ=][=ሃ=]ይ";
my $re = Regexp::Ethiopic::Amharic::getRe ( $string );

print "The expected expansion for $string\n";
print " is: ([አዓዐኣ])ለም[ጸፀ][ሀሃሐሓኀኃኻ]ይ\n";
print "got: $re\n";


my $test = "ዓለምፀሐይ";

print "The test string \"$test\" should be matched by the RE...\n";

if ( $test =~ /$re/ ) {
	print "  It matches! The test is a success.\n";
}
else {
	print "  Does NOT match! The test has failed :(\n";
}


__END__


=head1 NAME

asfunction.pl - Test Ethiopic RE String Generation.

=head1 SYNOPSIS

./asfunction.pl

=head1 DESCRIPTION

A demonstrator script to illustrate regular expressions for Amharic.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
