package Plack::App::ServiceStatus::NetStomp;

# ABSTRACT: Check Net::Stomp connection

our $VERSION = '0.913'; # VERSION

use 5.018;
use strict;
use warnings;
use Module::Runtime qw(require_module);
use Try::Tiny;

sub check {
    my ( $class, $stomp ) = @_;

    if ( ref $stomp eq 'CODE' ) {
        $stomp = $stomp->();
    }

    require_module 'Net::Stomp::Frame';
    my $reconnect_attempts = $stomp->reconnect_attempts();
    return try {
        $stomp->reconnect_attempts(1);
        my $transaction_id = $stomp->_get_next_transaction;
        my $begin_frame    = Net::Stomp::Frame->new(
            {
                command => 'BEGIN',
                headers => { transaction => $transaction_id }
            }
        );
        $stomp->send_frame($begin_frame);
        my $abort_frame = Net::Stomp::Frame->new(
            {
                command => 'ABORT',
                headers => { transaction => $transaction_id }
            }
        );
        $stomp->send_frame($abort_frame);
        return 'ok';
    }
    catch {
        return 'nok', 'Not connected: ' . $_;
    }
    finally {
        $stomp->reconnect_attempts($reconnect_attempts);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::ServiceStatus::NetStomp - Check Net::Stomp connection

=head1 VERSION

version 0.913

=head1 SYNOPSIS

  my $stomp = Net::Stomp->new(
      { hostname => 'localhost', port => '61613' }
  );
  $stomp->connect( { login => 'hello', passcode => 'there' } );
  my $status_app = Plack::App::ServiceStatus->new(
      app      => 'your app',
      NetStomp => $stomp,
  );

=head1 CHECK

Temporarily reduces the C<reconnect_attempts> to 1, and then starts a new STOMP
transaction which is immediately aborted again. If this is successful, the check
returns C<ok>, otherwise C<nok> and the exception.

=head1 PARAMETERS

Takes either a L<Net::Stomp> instance (where C<connect()> was already called on)
or a code reference which returns such a L<Net::Stomp> instance when called.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
