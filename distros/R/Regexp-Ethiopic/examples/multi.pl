#!/usr/bin/perl -w

use Regexp::Ethiopic::Tigrigna 'overload';
require Regexp::Ethiopic::Amharic;
require Regexp::Ethiopic::Geez;

use strict;
use utf8;
binmode(STDOUT, ":utf8");

my $string = "([=አ=])ለም[=ጸ=][=ሃ=]ይ";
my $am = Regexp::Ethiopic::Amharic::getRe  ( $string );
my $ti = Regexp::Ethiopic::Tigrigna::getRe ( $string );
my $gz = Regexp::Ethiopic::Geez::getRe     ( $string );

print "The expected expansion for $string in Amharic\n";
print " is: ([አዓዐኣ])ለም[ጸፀ][ሀሃሐሓኀኃኻ]ይ\n";
print "got: $am\n\n";

print "The expected expansion for $string in Tigrigna\n";
print " is: ([አኣ])ለም[ጸፀ][ሀሃኀኃ]ይ\n";
print "got: $ti\n\n";

print "The expected expansion for $string in Ge'ez\n";
print " is: ([አኣ])ለም[ሀሃ]ይ\n";
print "got: $gz\n";



__END__


=head1 NAME

multi.pl - Test Ethiopic RE String Generation for Three Languages.

=head1 SYNOPSIS

./multi.pl

=head1 DESCRIPTION

A demonstrator script to illustrate regular expressions for Amharic, Ge'ez and Tigrigna.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
