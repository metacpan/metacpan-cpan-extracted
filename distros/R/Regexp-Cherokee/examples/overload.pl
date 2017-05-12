#!/usr/bin/perl -w
use strict;
use utf8;
use Regexp::Cherokee 'overload';

my $hello = "ᎣᏏᏲ";

print "$hello does not contain a [#1#]\n" unless ( $hello =~ /[#1#]/ );
print "$hello does not contain a [#2#]\n" unless ( $hello =~ /[#2#]/ );
print "$hello contains a [#3#]\n" if ( $hello =~ /[#3#]/ );
print "$hello contains a [#4#]\n" if ( $hello =~ /[#4#]/ );
print "$hello does not contain a [#5#]\n" unless ( $hello =~ /[#5#]/ );
print "$hello does not contain a [#6#]\n" unless ( $hello =~ /[#6#]/ );

print "$hello contains a [#Ꭰ#]\n" if ( $hello =~ /[#Ꭰ#]/ );
print "$hello contains a [#Ꮜ#]\n" if ( $hello =~ /[#Ꮜ#]/ );
print "$hello does not contain a [#Ꮎ#]\n" unless ( $hello =~ /[#Ꮎ#]/ );
print "$hello contains a character of range [ᎠᎭ-Ꮎ]{#2,4-6#}\n" if ( $hello =~ /[ᎠᎭ-Ꮎ]{#2,4-6#}/ );

print "\n";
my $dumbTest = $hello;
$dumbTest =~ s/Ꮟ/Ꮐ/;

print "$dumbTest contains a [=Ꮎ=]\n" if ( $dumbTest =~ /[=Ꮎ=]/ );
print "$dumbTest does not contain a [=Ꮬ=]\n" unless ( $dumbTest =~ /[=Ꮬ=]/ );


__END__

=head1 NAME

overload.pl - Test Cherokee RE Overloading.

=head1 SYNOPSIS

./overload.pl

=head1 DESCRIPTION

A demonstrator script to illustrate regular expressions for Cherokee.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
