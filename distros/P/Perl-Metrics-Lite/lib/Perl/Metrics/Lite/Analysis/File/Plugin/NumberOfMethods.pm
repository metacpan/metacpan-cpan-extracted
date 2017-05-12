package Perl::Metrics::Lite::Analysis::File::Plugin::NumberOfMethods;
use strict;
use warnings;

sub init { }

sub measure {
    my ( $class, $context, $file ) = @_;
    my $sub_elements = $file->find('PPI::Statement::Sub');
    return 0 unless $sub_elements;
    my $number_of_subs =  scalar @{$sub_elements};
    return $number_of_subs;
}

1;
