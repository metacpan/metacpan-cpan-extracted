package Scrapar::DataHandler::_fromsub;

use strict;
use warnings;
use base qw(Scrapar::DataHandler::_base);

sub new {
    my $class = shift;
    my $code_ref = shift;

    die "Only code-ref is accepted" unless ref $code_ref eq 'CODE';

    bless {
	code_ref => $code_ref,
    } => ref($class) || $class;
}

sub handle {
    my $self = shift;
    my $data = shift;
    return $self->{code_ref}->($data);
}

1;
