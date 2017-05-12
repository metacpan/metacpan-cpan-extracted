package Perl::Metrics::Lite::Analysis::Sub::Plugin::LineNumber;
use strict;
use warnings;

sub init {}

sub measure {
    my ( $class, $context, $sub ) = @_;

    return $sub->line_number;
}

1;

__END__
