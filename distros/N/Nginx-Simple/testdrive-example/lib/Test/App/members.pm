package Test::App::members;

use base 'Test::App';
use strict;

use nginx;

sub primary :Index
{
    my $self = shift;

    $self->print('Good morning, sir (or madam)!<br>');
    $self->print('This area is for our memberz!');

    return OK;
}

sub ok { warn 'beep' };

sub darn :Action
{
    my $self = shift;
    $self->print('tummy is too fat.');
}

sub farm :Action
{
    shift->print('tummy is too fat.');
}

1;
