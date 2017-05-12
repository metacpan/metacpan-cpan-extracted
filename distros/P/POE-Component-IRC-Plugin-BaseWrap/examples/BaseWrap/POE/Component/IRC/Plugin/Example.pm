package POE::Component::IRC::Plugin::Example;

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};
use base 'POE::Component::IRC::Plugin::BaseWrap';

sub _make_default_args {
    return (
        response_event   => 'irc_time_response',
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;
    my $nick = (split /!/, $in_ref->{who})[0];
    return [ "$nick, time over here is: " . scalar localtime ];
}

sub _make_response_event {
    my ( $self, $in_ref ) = @_;
    $in_ref->{time} = localtime;
    return $in_ref;
}

1;
__END__