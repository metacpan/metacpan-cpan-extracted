package Supervisor::Constants;

use strict;
use warnings;

use base 'Badger::Constants';

use constant {
    START           => 'start',
    STOP            => 'stop',
    EXIT            => 'exit',
    RELOAD          => 'reload',
    STAT            => 'stat',
    #
    RUNNING         => 'running',
    ALIVE           => 'alive',
    DEAD            => 'dead',
    #
    STOPPED         => 'stopped',
    STARTED         => 'started',
    RELOADED        => 'reloaded',
    STATED          => 'stated',
    EXITED          => 'exited',
    #
    SHUTDOWN        => 'shutdown',
    UNKNOWN         => 'unknown',
    KILLME          => 'killme',
    #
    PROC_ROOT       => '/proc',
    #
    JSONRPC         => '2.0',
    DEFAULT_ADDRESS => '127.0.0.1',
    DEFAULT_PORT    => '9505',
    ERR_PARSE       => -32700,
    ERR_REQ         => -32600,
    ERR_METHOD      => -32601,
    ERR_PARAMS      => -32602,
    ERR_INTERNAL    => -32603,
    ERR_SERVER      => -32099,
    SRV_ERR_MIN     => -32000,
    SRV_ERR_MAX     => -32768,
};

our $EXPORT_ALL = 'START STOP RELOAD RUNNING ALIVE DEAD SHUTDOWN 
                   RELOADED STARTED JSONRPC DEFAULT_PORT DEFAULT_ADDRESS
                   ERR_PARSE ERR_REQ ERR_METHOD ERR_PARAMS ERR_INTERNAL
                   ERR_SERVER SRV_ERR_MAX SRV_ERR_MIN STOPPED UNKNOWN 
                   EXIT EXITED KILLME STAT STATED PROC_ROOT';

our $EXPORT_ANY = 'START STOP RELOAD RUNNING ALIVE DEAD SHUTDOWN 
                   RELOADED STARTED JSONRPC DEFAULT_PORT DEFAULT_ADDRESS
                   ERR_PARSE ERR_REQ ERR_METHOD ERR_PARAMS ERR_INTERNAL
                   ERR_SERVER SRV_ERR_MAX SRV_ERR_MIN STOPPED UNKNOWN
                   EXIT EXITED KILLME STAT STATED PROC_ROOT';

our $EXPORT_TAGS = {
    rpc => 'JSONRPC DEFAULT_PORT DEFAULT_ADDRESS ERR_PARSE ERR_REQ ERR_METHOD
            ERR_PARAMS ERR_INTERNAL ERR_SERVER SRV_ERR_MAX SRV_ERR_MIN'
};

1;

__END__

=head1 NAME

Supervisor::Constants - Define useful constants for the Supervisor

=head1 SYNOPSIS

 use Supervisor::Class
   version => '0.01',
   base    => 'Supervisor::Base',
   constants => 'STOPPED STARTED :rpc'
 ;

=head1 DESCRIPTION

This module defines some useful constants that are used thru out the 
supervisor environment. 

=head1 EXPORTS

These can be exported individually or by using :all.

 START
 STOP
 RESTART
 RELOAD
 RUNNING
 STOPPED
 ALIVE
 DEAD
 SHUTDOWN
 RELOADED
 STARTED
 UNKNOWN
 
Additionaly these can be exported by using :rpc.

 JSONRPC
 DEFAULT_HOST
 DEFAULT_PORT
 ERR_PARSE
 ERR_REQ
 ERR_METHOD
 ERR_PARAMS
 ERR_INTERNAL
 ERR_SERVER
 SRV_ERR_MIN
 SRV_ERR_MAX

=head1 SEE ALSO

 Badger::Constants

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
