package Nagios::NSCA::Client::Encrypt;
use strict;
use warnings;
use base 'Nagios::NSCA::Encrypt';

our $VERSION = sprintf("%d", q$Id: Encrypt.pm,v 1.2 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;

    # Require an iv argument
    if (not defined $args{iv}) {
        die "No initial value supplied.  iv parameter undefined for new().";
    }

    my $self = $class->SUPER::new(%args);
}

1;
