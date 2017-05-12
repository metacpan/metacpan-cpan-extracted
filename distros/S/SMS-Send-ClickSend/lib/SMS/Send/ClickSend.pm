package SMS::Send::ClickSend;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use SMS::Send::Driver ();
use SMS::ClickSend;

use vars qw{@ISA};
BEGIN {
    @ISA = 'SMS::Send::Driver';
}

sub new {
    my $pkg = shift;
    my %p = @_;
    my $self = bless \%p, $pkg;
    $self->{_clicksend} = SMS::ClickSend->new({
        username => $p{_username},
        api_key  => $p{_api_key}
    });
    return $self;
}

sub send_sms {
    my $self = shift;
    my %p = @_;

    $p{message} = delete $p{text};
    my $sms = $self->{_clicksend}->send(\%p) or return 0;

    return 0 unless $sms->{messages}->[0]->{result} eq '0000';
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

SMS::Send::ClickSend - SMS::Send joins SMS::ClickSend

=head1 SYNOPSIS

    use SMS::Send;

    my $sender = SMS::Send->new('ClickSend',
        _username => 'username',
        _api_key => 'api_key',
    );

    # Send a message
    my $sent = $sender->send_sms(
        text => 'This is a test message',
        to   => '+61411111111',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print "Failed to send message\n";
    }

=head1 DESCRIPTION

Please read L<SMS::ClickSend> for more details.

=head1 send_sms

that's wrap of B<send> on L<SMS::ClickSend>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
