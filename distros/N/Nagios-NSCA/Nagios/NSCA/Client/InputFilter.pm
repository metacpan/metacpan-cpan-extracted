package Nagios::NSCA::Client::InputFilter;
use strict;
use warnings;
use Nagios::NSCA::DataPacket;
use Nagios::NSCA::Client::Settings;
use base 'Nagios::NSCA::Client::Base';
use constant NSCA_PACKET_VERSION => 3;

our $VERSION = sprintf("%d", q$Id: InputFilter.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $settings = Nagios::NSCA::Client::Settings->new();
    my $fields = {
        delimiter => $settings->delimiter(),
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);
    
    $self->delimiter($args{delimiter});

    return $self;
}

sub line2packet {
    my ($self, $line) = @_;
    my $packet;

    if ($line) {
        my $d = $self->delimiter;
        my %data; 

        if ($line =~ /^(.+?)$d(.+?)$d(\d+)$d(.+)$/) {  # Service checks
            %data = (host => $1, service => $2, code => $3, output => $4);
        } elsif ($line =~ /^(.+?)$d(\d+)$d(.+)$/) { # Host checks
            %data = (host => $1, service => "", code => $2, output => $3);
        } 
    
        if (%data) {
            $packet = Nagios::NSCA::DataPacket->new(%data);
        }
    }

    return $packet;
}

1;
