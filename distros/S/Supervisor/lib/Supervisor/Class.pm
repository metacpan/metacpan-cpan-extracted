package Supervisor::Class;

use Badger::Class
  uber     => 'Badger::Class',
  constant => {
      UTILS     => 'Supervisor::Utils',
      CONSTANTS => 'Supervisor::Constants',
  }
;

1;

__END__

=head1 NAME

Supervisor::Class - A Perl extension for the Supervisor environment

=head1 SYNOPSIS

 use Supervisor::Class
    version => '0.01',
    base    => 'Supervisor::Base',
   ...
 ;
   
=head1 DESCRIPTION

This module inherits from Badger::Class and exposes the additinoal constants 
and utiltiy functions that are needed by the Supervisor environment.

=head1 SEE ALSO

 Badger::Class

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

Kevin Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
