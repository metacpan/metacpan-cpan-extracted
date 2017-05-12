package Monitoring::Spooler::Transport::Smstrade;
$Monitoring::Spooler::Transport::Smstrade::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Transport::Smstrade::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a monitoring spooler transport for the smstrade service

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
use LWP::UserAgent;
use URI::Escape;

# extends ...
extends 'Monitoring::Spooler::Transport';
# has ...
has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'lazy'    => 1,
    'builder' => '_init_ua',
);

has 'url' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'default' => 'https://gateway.smstrade.de/',
);

has 'apikey' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 1,
);

has 'route' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'default' => 'basic',
);

has 'responses' => (
    'is'    => 'ro',
    'isa'   => 'HashRef',
    'lazy'  => 1,
    'builder' => '_init_responses',
);
# with ...
# initializers ...
sub _init_ua {
    my $self = shift;

    my $UA = LWP::UserAgent::->new();
    $UA->agent('Monitoring::Spooler/0.11');
    if($UA->can('ssl_opts')) {
        $UA->ssl_opts( verify_hostname => 0, );
    }

    return $UA;
}

sub _init_responses {
    my $self = shift;

    # see http://www.smstrade.de/pdf/SMS-Gateway_HTTP_API_v2_de.pdf, page 5
    my $resp_ref = {
        '10'    => 'Destination Number not correct (Parameter: to)',
        '20'    => 'Source Number not correct (Parameter: from)',
        '30'    => 'Message not correct (Parameter: message)',
        '31'    => 'Message type not correct (Parameter: messagetype)',
        '40'    => 'SMS Route not correct (Parameter: route)',
        '50'    => 'Identification failed (Parameter: key)',
        '60'    => 'Insufficient Funds.',
        '70'    => 'Destination Network not covered. Use another route.',
        '71'    => 'Feature not available. Use another route.',
        '80'    => 'Failed to submit to SMS-C. Use another route or contact support.',
        '100'   => 'SMS successfull submitted.',
    };

    return $resp_ref;
}

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

    $destination = $self->_clean_number($destination);
    $message = substr($message,0,159);

    my %args = (
        'key'       => $self->apikey(),
        'message'   => $message,
        'to'        => $destination,
        'route'     => $self->route(),
        'from'      => 'Zabbix',
        'cost'      => 1,
        'message_id' => 1,
        'count'     => 1,
    );

    my $content = join('&', map { uri_escape($_).'='.uri_escape($args{$_}) } keys %args);

    my $req = HTTP::Request::->new( GET => $self->url().'?'.$content, );
    my $res = $self->_ua()->request($req);

    $self->logger()->log( message => 'Requesting URL '.$self->url(), level => 'debug', );

    if($res->is_success() && $res->content() =~ m/^100\D/) {
        $self->logger()->log( message => 'Sent '.$message.' to '.$destination, level => 'debug', );
        return 1;
    } else {
        my $errstr = $res->content();
        if($self->responses()->{$errstr}) {
            $errstr .= ' - '.$self->responses()->{$errstr};
        }
        $self->logger()->log( message => 'Failed to send '.$message.' to '.$destination.'. Error: '.$errstr, level => 'debug', );
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

Monitoring::Spooler::Transport::Smstrade - a monitoring spooler transport for the smstrade service

=head1 NAME

Monitoring::Spooler::Transport::Smstrade - SMStrade transport

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
