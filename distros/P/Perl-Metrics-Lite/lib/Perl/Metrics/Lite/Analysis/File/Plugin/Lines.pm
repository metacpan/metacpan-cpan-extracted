package Perl::Metrics::Lite::Analysis::File::Plugin::Lines;
use strict;
use warnings;

sub init {}

sub measure {
    my ( $class, $context, $file ) = @_;

    my $file_length = Perl::Metrics::Lite::Analysis::Util::get_node_length($file);
    return $file_length;
}

1;
