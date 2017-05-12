package Monitoring::Spooler::Transport::SmsSend;
$Monitoring::Spooler::Transport::SmsSend::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Transport::SmsSend::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a monitoring spooler transport using the SMS::Send framework

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use SMS::Send;

# extends ...
extends 'Monitoring::Spooler::Transport';
# has ...
has '_sender' => (
    'is'      => 'rw',
    'isa'     => 'SMS::Send',
    'lazy'    => 1,
    'builder' => '_init_sender',
);

has 'driver' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);

has 'privargs' => (
    'is'    => 'ro',
    'isa'   => 'HashRef',
    'required'  => 1,
);
# with ...
# initializers ...
sub _init_sender {
    my $self = shift;

    my $Sender = SMS::Send::->new($self->driver(), %{$self->privargs()},);

    return $Sender;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref $_[0] ) {
        # move private SMS::Send args to privargs hash ...
        my $privargs = {};
        foreach my $key (keys %{$_[0]}) {
            if($key =~ m/^_/) {
                $privargs->{$key} = $_[0]->{$key};
                delete $_[0]->{$key};
            }
        }
        $_[0]->{'privargs'} = $privargs;
        return $class->$orig( $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
    # direct hash calling style is not supported yet
};

# your code here ...
sub provides {
    my $self = shift;
    my $type = shift;

    if($type =~ m/^text$/i) {
        return 1;
    }

    return;
}

sub run {
    my $self = shift;
    my $destination = shift;
    my $message = shift;

    $message = substr($message,0,159);

    my $result = $self->_sender->send_sms(
        text => $message,
        to   => $destination,
    );

    if($result) {
        $self->logger()->log( message => 'Sent '.$message.' to '.$destination, level => 'debug', );
        return 1;
    } else {
        $self->logger()->log( message => 'Failed to send '.$message.' to '.$destination.'.', level => 'debug', );
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Transport::SmsSend - a monitoring spooler transport using the SMS::Send framework

=head1 NAME

Monitoring::Spooler::Transport::SmsSend - Send text messages using SMS::Send.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
