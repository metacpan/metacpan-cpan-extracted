package Mojolicious::Plugin::UserMessages::Message;
{
  $Mojolicious::Plugin::UserMessages::Message::VERSION = '0.511';
}

use Carp;
use strict;

our $AUTOLOAD;

sub new {
    my $class = shift;
    my %args  = @_;

    return bless( \%args, $class);
}

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*://;    # strip fully-qualified portion

    return if $method eq 'DESTROY';

    return $self->{$method};
}

1;
