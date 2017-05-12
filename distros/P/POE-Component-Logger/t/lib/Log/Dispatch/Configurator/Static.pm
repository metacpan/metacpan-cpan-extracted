package t::lib::Log::Dispatch::Configurator::Static;
use strict;
use warnings;

use base 'Log::Dispatch::Configurator';

use Carp;

sub new
{
    my $proto = shift;
    my %config = @_;
    croak "key 'dispatchers' expected" unless exists $config{dispatchers};
    croak "key 'format' expected" unless exists $config{format};
    bless \%config, (ref $proto || $proto);
}

sub get_attrs_global
{
    my $self = shift;
    return {
	format => $self->{format},
	dispatchers => [ keys %{$self->{dispatchers}} ],
    }
}

sub get_attrs
{
    my ($self, $name) = @_;
    croak "invalid dispatcher" unless exists $self->{dispatchers}{$name};
    return $self->{dispatchers}{$name};
}

1;

