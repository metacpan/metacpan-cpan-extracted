package Pgtools::Fingerprint;
use strict;
use warnings;
use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(file query));

use File::Spec;

sub exec {
    my ($self, $query, $filename) = @_;

    if($query ne "") {
        $query = &symbolize_query($self, $query);
        &print_queries($self, $query);
        return;
    }
    $filename = File::Spec->rel2abs($filename);

    open(my $in, '<', $filename) or die "$!";
    while(<$in>) {
        chomp $_;
        $_ = &symbolize_query($self, $_);
        &print_queries($self, $_);
    }
}

sub symbolize_query {
    my ($self, $q) = @_;
    $q =~ s/([\s<>=])([-\+])?[.0123456789]+/$1?/g;
    $q =~ s/(true|false)/?/ig;

    return $q;
}

sub print_queries {
    my ($self, $query) = @_;
    print $query."\n";
}

1;

