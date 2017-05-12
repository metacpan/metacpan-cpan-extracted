#
# (c) 2011 Jan Gehring <jan.gehring@gmail.com>
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#

=head1 NAME

Net::SSH2::Expect - An Expect like module for Net::SSH2

=head1 DESCRIPTION

This is a module to have expect like features for Net::SSH2. Please report bugs at GitHub L<https://github.com/krimdomu/net-ssh2-expect>

=head1 DEPENDENCIES

=over 4

=item *

L<Net::SSH2>

=back

=head1 SYNOPSIS

 use Net::SSH2::Expect;
       
 my $exp = Net::SSH2::Expect->new($ssh2);
 $exp->spawn("passwd");
 $exp->expect($timeout, [
                           qr/Enter new UNIX password:/ => sub {
                                                              my ($exp, $line) = @_;
                                                              $exp->send($new_password);
                                                           },
                           qr/Retype new UNIX password:/ => sub {
                                                              my ($exp, $line) = @_;
                                                              $exp->send($new_password);
                                                           },
                        ]);

=head1 CLASS METHODS

=cut

package Net::SSH2::Expect;

use strict;
use warnings;

our $VERSION = "0.2";

=over 4

=item new($ssh2)

Constructor: You need to parse an connected Net::SSH2 Object. 

=cut

our $Log_Stdout = 1;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = {};

   bless($self, $proto);

   $self->{"__shell"} = $_[0]->channel();
   $self->{"__shell"}->pty("vt100");
   $self->{"__shell"}->shell;

   $self->{"__log_stdout"} = $Net::SSH2::Expect::Log_Stdout;
   $self->{"__log_to"} = sub {};
   $self->{"output"} = [];

   return $self;
}

=item log_stdout(0|1)

Log on STDOUT.

=cut
sub log_stdout {
   my ($self, $log) = @_;
   $self->{"__log_stdout"} = $log;
}

=item log_file($file)

Log everything to a file. $file can be a filename, a filehandle or a subRef.

=cut
sub log_file {
   my ($self, $file) = @_;
   $self->{"__log_to"} = $file;
}

sub shell {
   my ($self) = @_;
   return $self->{"__shell"};
}

=item spawn($command, @parameters)

Spawn $command with @parameters as parameters.

=cut
sub spawn {
   my ($self, $command, @parameters) = @_;

   my $cmd = "$command " . join(" ", @parameters);

   $self->shell->write("echo 'randomnum'\n");

   my $line = "";
   while($line ne "randomnum\r") {
      my $buf;
      $self->shell->read($buf, 1);

      if($buf eq "\n") {
         $line = "";
         next;
      }

      $line .= $buf;
   }

   $cmd .= " && echo ___END___0_";

   #$self->shell->write("PS1=''\n$cmd\necho ___END___\$?_\n");
   $self->shell->write("$cmd\n");
   $self->shell->flush;

   $line = "";
   my $counter = 0;
   while(1) {
      my $buf;
      $self->shell->read($buf, 1);
      if($buf eq "\r") { next; }
      $line .= $buf;

      if($line =~ m/$cmd\n/s) {
         $counter++;
      }

      if($line =~ m/$cmd\n/s && $counter==2) {
         last;
      }

      if($buf eq "\n") {
         $line = "";
         next;
      }
   }

}

=item soft_close()

Currently only an alias to hard_close();

=cut

sub soft_close {
   my ($self) = @_;
   $self->hard_close;
}

=item hard_close();

Stops the execution of the process.

=cut

sub hard_close {
   my ($self) = @_;
   die;
}

=item expect($timeout, @match_patters)

This method controls the execution of your process.

=cut

sub expect {
   my ($self, $timeout, @match_patterns) = @_;

   $? = 1;
   eval {
      my $success = 0;
      local $SIG{'ALRM'} = sub { die; };
      alarm $timeout;

      my $line = "";
      while(1) {
         my $buf;
         $self->shell->read($buf, 1);
         if($buf eq "\r") { next; }

         # log to stdout if wanted
         $line .= $buf;

         if($self->_check_patterns($line, @match_patterns)) {
            $line = "";
            alarm $timeout;
            next;
         }

         if($line =~ m/^___END___0_/) {
            $? = 0;
            $success = 1;
            last;
         }

         print $buf if $self->{"__log_stdout"};
         $self->_log($buf);

         if($buf eq "\n") {
            chomp $line;
            push(@{ $self->{output} }, $line);
            $line = "";
         }

      }

      if($self->{output}->[0] =~ m/^\s*$/) {
         shift @{ $self->{output} };
      }
      return $success;
   } or do {
      return;
   };
}

=item send($string)

Send a string to the running command.

=cut

sub send {
   my ($self, $str) = @_;
   $self->shell->write($str);
}

sub _check_patterns {
   my ($self, $line, @match_patterns) = @_;

   my $pattern_hash = { @{$match_patterns[0]} };

   for my $pattern (keys %{ $pattern_hash }) {
      if($line =~ $pattern) {
         my $code = $pattern_hash->{$pattern};
         &$code($self, $line);
         return 1;
      }
   }
}

sub _log {
   my ($self, $str) = @_;

   my $log_to = $self->{"__log_to"};

   if(ref($log_to) eq "CODE") {
      &$log_to($str);
   }
   elsif(ref($log_to) eq "GLOB") {
      print $log_to $str;
   }
   else {
      # log to a file
      open(my $fh, ">>", $log_to) or die($!);
      print $fh $str;
      close($fh);
   }

}

=back

=cut

1;

