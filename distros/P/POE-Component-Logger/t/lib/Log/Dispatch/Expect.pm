package t::lib::Log::Dispatch::Expect;
use strict;
use warnings;

use base 'Log::Dispatch::Output';
use Carp;

sub new
{
    my $proto = shift;
    my %args = @_;
    my $self = bless {}, (ref $proto || $proto);
    $self->_basic_init(%args);
    croak "'expected' argument expected" unless exists $args{expected};
    croak "ARRAY argument expected" unless (ref $args{expected}) eq 'ARRAY';
    $self->{expected} = $args{expected};
    $self
}

sub log_message
{
    my ($self, %p) = @_;
    local $::a = \%p;
    local $::b = shift @{$self->{expected}};
    $self->expect($::a, $::b);
    undef
}

sub expect
{
    die 'message does dot match!' if $::a->{message} ne $::b->{message};
    die 'level does dot match!' if exists($::b->{level}) && $::a->{level} ne $::b->{level};
}

1;
