package Perl::Metrics::Lite::Analysis::Sub::Plugin::Lines;
use strict;
use warnings;

sub init {
}

sub measure {
    my ( $self, $context, $sub ) = @_;

    my $sub_length
        = Perl::Metrics::Lite::Analysis::Util::get_node_length($sub);
    return $sub_length;
}

1;

__END__
