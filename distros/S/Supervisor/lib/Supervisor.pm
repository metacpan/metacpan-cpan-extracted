package Supervisor;

use strict;
use warnings;

our $VERSION = '0.08';

1;

__END__
  
=head1 NAME

Supervisor - A process to supervisor other processes

=head1 DESCRIPTION

A supervisor is a process that controls other processes. One of the most well
known ones is /sbin/init, which is ran by the *nix kernel to set up the initial
environment. Init is also used to monitor and keep processes running when 
they exit. 

While this supervisor is no replacement for init, it does share some of those
characteristics. A daemon that runs in the background, monitoring a series of 
processes, restarting them should they exit. It also has a command line utility
to start, stop, stat and reload a monitored process.

To do this, the supervisor is broken up into three parts. Each part is 
represented by an object. Each object is a based on a POE session and the 
events that they can respond too. 

One part has the concept of a managed process. It contains the neccessary
methods and events to control a process. When a process exits, an event is 
generated and sent to the supervisor.

A second part has the ability to allow access from external utilities to the
managed processes. This allows utilities to start, stop, stat and/or reload
managed processes. 

And thirdly, there is a part that controls this interaction between the 
managed processes, external events and the neccesity of keeping those processes 
running.

So to do all this, the three parts are broken out over several modules. 

Basic functionality is provided by these modules.

 Supervisor::Base      - sets version number and provides documentation
 Supervisor::Class     - defines the constants and common utilty functions
 Supervisor::Constants - provides uniform constants for the environment
 Supervisor::Log       - provides a common logging interface
 Supervisor::Session   - provides a base POE session
 Supervisor::Utils     - provides common utility functions

Process management is provided by these modules:

 Supervisor::Process        - base module for a managed process
 Supervidor::ProcessFactory - loads multiple processes from a config file

The external interface is provided by these modules:

 Supervisor::RPC::Server    - provide an interface to the external world
 Supervisor::RPC::Client    - used by external world to communcicate

The internal interface between processes and the external world:

 Supervisor::Controller     - controls the processes and external access

These modules all combined togther make a supervisor that will keep a process
running and allow control of that process from external utilties. 

=head1 SEE ALSO

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

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
