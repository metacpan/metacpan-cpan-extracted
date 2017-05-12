package POE::Component::RemoteTail::CustomEngine::NetSSHPerl;

use strict;
use warnings;
use Net::SSH::Perl;

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;
    return $self;
}

sub process_entry {
    my $self  = shift;
    my $arg   = shift;

    my $host     = $arg->{host};
    my $path     = $arg->{path};
    my $user     = $arg->{user};
    my $password = $arg->{password};
    my $cmd      = "tail -f $path";

    my $ssh = Net::SSH::Perl->new( $host, protocol => "2", interractive => 0, debug => 9 );
    $ssh->login($user, $password);
    $ssh->register_handler(
        "stdout",
        sub {
            my ( $channel, $buffer ) = @_;
            my $log = $buffer->bytes;
            print $log;
            unless ($log) { exit; }
        }
    );
    my ( $stdout, $stderr, $exit ) = $ssh->cmd($cmd);
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail::CustomEngine::NetSSHPerl - Pure Perl SSH engine

=head1 SYNOPSIS

  use POE::Component::Remotetail;
  
  my $tailer = POE::Component::RemoteTail->spawn();
  
  my $job = $tailer->job(
      host          => $host1,
      path          => $path,
      user          => $user,
      password      => $password,
      process_class => "POE::Component::RemoteTail::CustomEngine::NetSSHPerl"
  );
  
  POE::Session->create(
      inline_states => {
          _start => sub {
              my $kernel = @_[KERNEL];
              $kernel->post($tailer->session_id(), "start_tail" => {job => $job});
              $kernel->delay_add("stop_job", 100);
          },
          stop_job => sub {
              my $kernel = @_[KERNEL];
              $kernel->post($tailer->session_id(), "stop_tail" => {job => $job}); 
          }
      }
  );
  
  POE::Kernel->run();

=head1 DESCRIPTION

POE::Component::RemoteTail::CustomEngine::NetSSHPerl adopts Net::SSH::Perl inside.

Every engine has to override 'process_entry()' method.

=head1 METHOD

=head2 new()

=head2 process_entry()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
