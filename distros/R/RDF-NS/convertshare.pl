#!/usr/bin/perl
#PODNAME: Helper script to change share layout after version 20120827

use RDF::NS;

qx(touch share/prefix.cc) unless -e 'share/prefix.cc';
my $old = RDF::NS->new( 'share/prefix.cc' );

my @files = sort grep { /\d{8}/ } <share/*>;

foreach my $file (@files) {
    $file =~ /(\d{8})\.txt$/;
    my $date = $1;

    my $ns  = RDF::NS->new( $file );

    printf "$file (%d prefixes)\n", $ns->COUNT;
    my $diff = $ns->UPDATE( 'share/prefix.cc', $date );

    foreach my $c (qw(create update delete)) {
        printf " $c\t %s\n", join(",",@{$diff->{$c}}) if @{$diff->{$c}};
    }

    $old = $ns;
}

