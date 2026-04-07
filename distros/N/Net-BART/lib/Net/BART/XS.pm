package Net::BART::XS;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Net::BART::XS', $VERSION);

1;

__END__

=head1 NAME

Net::BART::XS - XS/C implementation of Balanced Routing Tables

=head1 SYNOPSIS

    use Net::BART::XS;

    my $table = Net::BART::XS->new;

    $table->insert("10.0.0.0/8", "private");
    $table->insert("10.1.0.0/16", "office");

    my ($val, $ok) = $table->lookup("10.1.2.3");
    # $val = "office", $ok = 1

    my $found = $table->contains("10.1.2.3");  # 1

    my ($val, $ok) = $table->get("10.0.0.0/8");
    my ($old, $ok) = $table->delete("10.1.0.0/16");

=head1 DESCRIPTION

Drop-in replacement for L<Net::BART> implemented in C via XS for maximum
performance. Same API, typically 10-20x faster.

=cut
