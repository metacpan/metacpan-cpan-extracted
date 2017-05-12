package Nagios::NSCA::Client::Settings;
use strict;
use warnings;
use Nagios::NSCA::Client::CommandLine;
use Nagios::NSCA::Client::Config;
use base 'Nagios::NSCA::Client::Base';

our $VERSION = sprintf("%d", q$Id: Settings.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

# The magical value that makes this class a singleton
my $__singletonInstance = undef;

sub new {
    return $__singletonInstance if $__singletonInstance;  # Forces singleton

    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    my $commandLine = Nagios::NSCA::Client::CommandLine->new(%args);
    my $config = $args{config} || $commandLine->config;
    my $configFile = Nagios::NSCA::Client::Config->new(config => $config);
    $self->_initFields({%$configFile, %$commandLine});
    $__singletonInstance = $self;

    return $self;
}

1;
