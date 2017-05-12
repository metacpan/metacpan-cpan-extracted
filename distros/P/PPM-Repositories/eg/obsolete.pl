# Print out all *Active* repositories for perl 5.8.x
use strict;
use warnings;
use PPM::Repositories;

for my $rep ( sort keys %Repositories ) {
    next unless $Repositories{$rep}->{Active};
    next unless grep { $_ == 5.8 } @{ $Repositories{$rep}->{PerlV} };
    print "$rep\n";
    print "  $Repositories{$rep}->{location}\n";
    print "  $Repositories{$rep}->{Notes}\n\n";
}
