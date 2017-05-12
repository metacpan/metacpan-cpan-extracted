package StatusFile;

use strict;
use warnings;

use File::Temp qw/ tempdir /;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _dir
{
    my $self = shift;

    if (@_)
    {
        $self->{_dir} = shift;
    }

    return $self->{_dir};
}

sub fn
{
    my $self = shift;

    if (@_)
    {
        $self->{fn} = shift;
    }

    return $self->{fn};
}

sub _init
{
    my ($self, $args) = @_;

    $self->_dir(scalar tempdir( CLEANUP => 1));

    $self->fn($self->_dir . '/server-status.txt');

    return;
}

1;
