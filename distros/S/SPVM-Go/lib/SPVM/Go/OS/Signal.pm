package SPVM::Go::OS::Signal;



1;

=head1 Name

SPVM::Go::OS::Signal - Signal Manipulation

=head1 Description

The Go::OS::Signal class of L<SPVM> has methods to manipulate signals.

=head1 Usage

  use Go::OS::Signal;
  use Sys::Signal::Constant as SIGNAL;
  use Sys;
  
  my $ch = Go->make(1);
  
  Go::OS::Signal->notify($ch, SIGNAL->SIGTERM);
  
  Sys->kill(SIGNAL->SIGTERM, Sys->process_id);
  
  my $ok = 0;
  my $signal = $ch->read(\$ok);

=head1 Class Methods

=head2 

C<static method ignore : void ($signal : int);>

Ignores the signal $signal.

See L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant> about the values of signals.

=head2 notify

C<static method notify : void ($channel : L<Go::Channel|SPVM::Go::Channel>, $signal : int);>

Creates a goroutine to read the sent signal and write it to the $channel.

See L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant> about the values of signals.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

