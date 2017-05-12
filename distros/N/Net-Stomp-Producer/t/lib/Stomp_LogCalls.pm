package Stomp_LogCalls;
use strict;
use warnings;
use Net::Stomp::Frame;

our @calls;

our %returns;

sub new {
    my ($class,@args) = @_;
    push @calls,['new',$class,@args];
    bless {},$class;
}

for my $m (qw(subscribe unsubscribe
              receive_frame ack
              send send_frame send_with_receipt send_transactional
              send_just_testing
         )) {
    no strict 'refs';
    *$m=sub {
        push @calls,[$m,@_];
        if ($returns{$m} && @{$returns{$m}}) {
            return shift @{$returns{$m}};
        }
        else {
            return 1;
        }
    };
}

sub current_host { return 0 }

sub connect {
    push @calls,['connect',@_];
    return Net::Stomp::Frame->new({
        command => 'CONNECTED',
        headers => {
            session => 'ID:foo',
        },
        body => '',
    });
}

1;
