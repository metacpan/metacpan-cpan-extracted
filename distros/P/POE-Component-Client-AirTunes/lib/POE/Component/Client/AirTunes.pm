package POE::Component::Client::AirTunes;

use strict;
our $VERSION = '0.01';

use Carp;
use POE;
use POE qw( Wheel::Run Filter::Line );

sub new {
    my $class = shift;
    croak "Usage: POE::Component::Client::AirTunes->new(\%param)" if @_ & 1;
    my %param = @_;

    my $self = bless \%param, $class;
    $self->{host}   or croak "host parameter is missing";
    $self->{alias}  ||= 'airtunes';
    $self->{parent} ||= 'main';
    $self->{events} ||= {};

    my $session = POE::Session->create(
        object_states => [
            $self => { (map { $_ => 'request' } qw(play pause stop quit volume)) },
            $self => [ qw(_start _stop wheel_close wheel_err wheel_out wheel_stderr ) ],
        ],
    );
    $self->{session_id} = $session->ID;

    $self;
}

sub _start {
    my($kernel, $self) = @_[KERNEL, OBJECT];

    if ($self->{alias}) {
        $kernel->alias_set($self->{alias});
    } else {
        $kernel->refcount_increment($self->{session_id} => __PACKAGE__);
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program      => [ 'raop_play', '-i', $self->{host} ],
        StdioFilter  => POE::Filter::Line->new(),
        StdoutEvent  => 'wheel_out',
        StderrEvent  => 'wheel_stderr',
        ErrorEvent   => 'wheel_err',
        CloseEvent   => 'wheel_close',
    );
}

sub _stop { delete $_[OBJECT]->{wheel} }

sub request {
    my($kernel, $self, $state, $sender) = @_[KERNEL, OBJECT, STATE, SENDER];

    my $cmd  = $state;
       $cmd .= " $_[ARG0]" if defined $_[ARG0];
    warn "command $cmd\n" if $self->{debug};

    $self->{wheel}->put($cmd);
}

sub wheel_out {
    my($kernel, $self, $input) = @_[KERNEL,OBJECT,ARG0];
    warn "OUT: $input\n" if $self->{debug};
    if ($input eq 'connected') {
        $self->post_parent('connected');
    } elsif ($input eq 'done') {
        $self->post_parent('done');
    }
}

sub wheel_stderr {
    my($kernel, $self, $input) = @_[KERNEL,OBJECT,ARG0];
    warn "ERR: $input\n" if $self->{debug};

    if ($input =~ /^DBG: Audio-Jack-Status: ((?:dis)?connected)(?:; type=(analog|digital))?/) {
        $self->{audio_jack}->{status} = $1;
        $self->{audio_jack}->{type}   = $2 if $2;
    } elsif ($input =~ /ERR: exec_request: request failed, error 453/) {
        $self->post_parent('error' => 'Somebody is using this AirTunes speaker.');
    } elsif ($input =~ /ERR: error:get_tcp_nconnect addr=/) {
        $self->post_parent('error' => 'TCP/IP connection failure.');
    }
}

sub wheel_err {
    warn "Wheel $_[ARG3] generated $_[ARG0] error $_[ARG1]: $_[ARG2]\n"
        if $_[OBJECT]->{debug};
}

sub wheel_close { }

sub post_parent {
    my($self, $event, @args) = @_;
    $poe_kernel->post($self->{parent}, $event, @args);
}

sub session_id { $_[0]->{session_id} }
sub audio_jack { $_[0]->{audio_jack} }

1;

__END__

=head1 NAME

POE::Component::Client::AirTunes - Stream music to Airport Express

=head1 SYNOPSIS

  use POE qw( Component::Client::AirTunes );

  POE::Component::Client::AirTunes->new(
      host  => $ip,
      alias => "airtunes",
      events => {
          connected     => 'connected',
          error         => 'error',
          done          => 'done',
      },
  );

  $kernel->post(airtunes => 'volume' => 100);
  $kernel->post(airtunes => 'play'   => "/path/to/foobar.m4a");
  $kernel->post(airtunes => 'stop');

=head1 DESCRIPTION

POE::Component::Client::AirTunes is a POE component to stream music
files to your Airport Express. This module is a frontend for a command
line Airport Express player I<raop_play>, which is included in Airport
Express Client, availabe at L<http://raop-play.sourceforge.net>.

See C<t/01_airtunes.t> for more example. This module is ALPHA software
and its API might change in the future.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module is part of Trickster 2.0. See
http://trickster.bulknews.net/ for details.

=head1 SEE ALSO

raop_play http://sourceforge.net/projects/raop-play/
L<POE>

=cut
