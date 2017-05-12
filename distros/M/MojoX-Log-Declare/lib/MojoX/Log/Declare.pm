package MojoX::Log::Declare;

use Mojo::Base -base;
use Log::Declare;

our $VERSION = '0.03';

use strict;
use warnings;

{
    no strict 'refs';
    no warnings;

    for my $level (@Log::Declare::level_priority) {

        *{ __PACKAGE__ . "::$level" } = sub {
            my $self = shift;
            Log::Declare->log( $level, ['MOJO'], @_ );
        };
    }

    *{ __PACKAGE__ . "::log" } = sub {
        my $self = shift;
        Log::Declare->log( 'info', ['MOJO'], @_ );
    };
}

1;

=head1 NAME

MojoX::Log::Declare - Integrate Log::Declare with Mojolicious

=head1 SYNOPSIS

  use Mojo::Base 'Mojolicious';
  use MojoX::Log::Declare;

  sub startup {
     my $self = shift;

     $self->log( MojoX::Log::Declare->new() );
     # ...
  }

=cut
