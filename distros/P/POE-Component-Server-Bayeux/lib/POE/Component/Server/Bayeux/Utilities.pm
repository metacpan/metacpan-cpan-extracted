package POE::Component::Server::Bayeux::Utilities;

use strict;
use warnings;

use base qw(Exporter);
our %EXPORT_TAGS = ( all => [qw(channel_match)] );
our @EXPORT_OK = qw(channel_match);

sub channel_match {
    my ($from, $to) = @_;

    # Should channel $from be delivered to someone subscribed to channel $to?

    return 1 if $from eq $to;

    my @from = split /\//, $from;
    my @to   = split /\//, $to;

    for (my $i = 0; $i <= $#from; $i++) {
        return 0 if ! defined $to[$i];

        # Match all
        return 1 if $to[$i] eq '**';

        # If simple glob '*' and from has no more parts
        return 1 if $to[$i] eq '*' && $#from == $i;

        return 0 if $from[$i] ne $to[$i];
    }

    return 0 if int @to > int @from;

    # If here, it matched
    return 1;
}

1;
