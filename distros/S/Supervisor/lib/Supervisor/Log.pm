package Supervisor::Log;

use 5.008;

use DateTime;
use base Badger::Log::File;

our $FORMAT = "[<time>][<system>] <level>: <message>";

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub log {
    my ($self, $level, $message) = @_;

    my $handle = $self->{handle} || $self->acquire;

    $message = defined($message) ? $message : "";
    my $output = sprintf($self->format($level, $message));
    $output =~ s/\n+$//;
    $handle->printflush($output, "\n");

    $self->release unless $self->{keep_open};

}

sub format {
    my $self = shift;

    my $dt = DateTime->now(time_zone => 'local');
    my $args = {
      time    => sprintf("%s %s", $dt->ymd('/'), $dt->hms),
      system  => $self->{system},
      level   => shift,
      message => shift,
    };
    
    my $format = $self->{format};

    $format =~ 
        s/<(\w+)>/
        defined $args->{ $1 } 
            ? $args->{ $1 }
            : "<$1>"
            /eg;

    return $format;

}

1;

__END__

=head1 NAME

Supervisor::Log - A simple logger for the Supervisor environment

=head1 SYNOPSIS

 $log = Supervisor::Log->new(
     info     => 1,
     warn     => 1,
     error    => 1,
     fatal    => 1,
     debug    => 0,
     system   => $self->config('Name'),
     filename => $self->config('Logfile'),
 );

 $log->info("It's working");

=head1 DESCRIPTION

The supervisor captures the stdout and stderr streams from each managed 
process and redirects them into a log file. The logfile name can be 
specified. 

This module inherits from the Badger::Log::File module. It specifies a logging 
format and overrides the log() and format() methods to do what I want them to 
do. 

=head1 SEE ALSO

 Badger::Log
 Badger::Log::File

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
