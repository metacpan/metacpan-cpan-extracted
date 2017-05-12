package MooX::POE;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: POE::Session combined with Moo (or Moose, if you want)
$MooX::POE::VERSION = '0.002';
use Moo::Role;
use Package::Stash;

use POE qw(
  Session
);

sub BUILD {
  my $self = shift;
  my $ps = Package::Stash->new(ref $self);
  my $session = POE::Session->create(
    inline_states => {
      _start => sub { POE::Kernel->yield('STARTALL', \$_[5] ) },
      map {
        my $func = $_;
        my ( $event ) = $func =~ /^on_(.*)$/;
        $event, sub {
          my ( @args ) = @_[ ARG0..$#_ ];
          $self->$func(@args);
        };
      } grep { /^on_/ } $ps->list_all_symbols('CODE'),
    },
    object_states => [
      $self => {
        STARTALL => 'STARTALL',
        _stop    => 'STOPALL',
        $self->can('CHILD') ? ( _child => 'CHILD' ) : (),
        $self->can('PARENT') ? ( _parent => 'PARENT' ) : (),
        _call_kernel_with_my_session => '_call_kernel_with_my_session',
      },
    ],
    args => [ $self ],
    heap => ( $self->{heap} ||= {} ),
  );
  $self->{session_id} = $session->ID;
}

sub get_session_id {
  my ( $self ) = @_;
  return $self->{session_id};
}

sub yield { my $self = shift; POE::Kernel->post( $self->get_session_id, @_ ) }
sub call { my $self = shift; POE::Kernel->call( $self->get_session_id, @_ ) }

sub _call_kernel_with_my_session {
  my ( $self, $function, @args ) = @_[ OBJECT, ARG0..$#_ ];
  POE::Kernel->$function( @args );
}
 
sub delay { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay' => @_ ) }
sub alarm { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm', @_ ) }
sub alarm_add { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_add', @_ ) }
sub delay_add { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_add', @_ ) }
sub alarm_set { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_set', @_ ) }
sub alarm_adjust { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_adjust', @_ ) }
sub alarm_remove { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_remove', @_ ) }
sub alarm_remove_all { my $self = shift; $self->call( _call_kernel_with_my_session => 'alarm_remove_all', @_ ) }
sub delay_set { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_set', @_ ) }
sub delay_adjust { my $self = shift; $self->call( _call_kernel_with_my_session => 'delay_adjust', @_ ) }
 
sub STARTALL {
  my ( $self, @params ) = @_;
  $params[4] = pop @params;
  my @isa = @{mro::get_linear_isa(ref $self)};
  for my $caller (@isa) {
    my $can = $caller->can('START');
    $can->( $self, @params ) if $can;
  }
}
 
sub STOPALL {
  my ( $self, $params ) = @_;
  my @isa = @{mro::get_linear_isa(ref $self)};
  for my $caller (@isa) {
    my $can = $caller->can('STOP');
    $can->( $self, $params ) if $can;
  }
}

1;

__END__

=pod

=head1 NAME

MooX::POE - POE::Session combined with Moo (or Moose, if you want)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package Counter;

  use Moo;
  with qw( MooX::POE );

  has count => (
    is => 'rw',
    lazy_build => 1,
    default => sub { 1 },
  );

  sub START {
    my ($self) = @_;
    $self->yield('increment');
  }

  sub on_increment {
    my ( $self ) = @_;
    print "Count is now " . $self->count . "\n";
    $self->count( $self->count + 1 );
    $self->yield('increment') unless $self->count > 3;
  }

  Counter->new();
  POE::Kernel->run();

=head1 DESCRIPTION

This role adds a L<POE::Session> and event handling to the class. Can also be
used the same way with L<Moose>.

=head1 BASED ON

This plugin is based on code of L<MooseX::POE>.

=head1 SUPPORT

IRC

  Join #poe on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-moox-poe
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-moox-poe

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
