package Net::YahooMessenger::ReceiveBuddyList;
use base 'Net::YahooMessenger::Event';
use strict;

use constant YMSG_SEPARATER => "\xC0\x80";

sub source {
    my $self = shift;

    if (@_) {
        $self->SUPER::source(@_);
        my $yahoo      = $self->get_connection;
        my @buddy_list = split( YMSG_SEPARATER, @_[0] );
        my $group      = '';
        my $next_token = 0;
        while (@buddy_list) {
            my $token = shift @buddy_list;
            if ( $token == 7 ) {
                my $buddy = shift @buddy_list;
                $yahoo->add_buddy_by_name( $group, $buddy );
            }
            if ( $token == 65 ) {
                $group = shift @buddy_list;
            }
        }
    }
    $self->SUPER::source();
}

sub body {
    my $self = shift;
    $self->_get_by_name('BUDDY_LIST');
}

sub code {
    return 0x55;
}

sub to_string {
    my $self = shift;

    #	sprintf "%s: transit to '%s'", $self->{sender}, $self->{body};
}

1;
__END__
