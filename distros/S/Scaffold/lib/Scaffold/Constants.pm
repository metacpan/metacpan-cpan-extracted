package Scaffold::Constants;

use strict;
use warnings;

use base 'Badger::Constants';

use constant {
    LOCK              => '__LOCK__',
    #
    STATE_PRE_ACTION  => 1,
    STATE_ACTION      => 2,
    STATE_POST_ACTION => 3,
    STATE_PRE_RENDER  => 4,
    STATE_RENDER      => 5,
    STATE_POST_RENDER => 6,
    STATE_FINI        => 7,
    #
    PLUGIN_NEXT       => 1,
    PLUGIN_ABORT      => 2,
    #
    SESSION_ID        => '__session_id__',
    TOKEN_ID          => '__token_id__',
};

__PACKAGE__->export_all( 
    qw( 
        LOCK STATE_PRE_ACTION STATE_ACTION STATE_POST_ACTION 
        STATE_PRE_RENDER STATE_RENDER STATE_POST_RENDER 
        STATE_FINI PLUGIN_NEXT PLUGIN_ABORT SESSION_ID
        TOKEN_ID 
    )
);

__PACKAGE__->export_any(
    qw( 
        LOCK STATE_PRE_ACTION STATE_ACTION STATE_POST_ACTION 
        STATE_PRE_RENDER STATE_RENDER STATE_POST_RENDER 
        STATE_FINI PLUGIN_NEXT PLUGIN_ABORT SESSION_ID
        TOKEN_ID 
    )
);

__PACKAGE__->export_tags(
    state   => [ qw(STATE_PRE_ACTION STATE_ACTION STATE_POST_ACTION 
                STATE_PRE_RENDER STATE_RENDER STATE_POST_RENDER 
                STATE_FINI) ],
    plugins => [ qw(PLUGIN_NEXT PLUGIN_ABORT) ],
);

1;

__END__

=head1 NAME

Scaffold::Constants - Define useful constants for the Scaffold environment

=head1 SYNOPSIS

 use Scaffolc::Class
   version => '0.01',
   base    => 'Scaffold::Base',
   constants => 'SESSION_ID'
 ;

=head1 DESCRIPTION

The module is defines constants for the Scaffold environment.

=head1 EXPORTS

These constants are used by the handler's state engine.

 STATE_PRE_ACTION
 STATE_ACTION
 STATE_POST_ACTION
 STATE_PRE_RENDER
 STATE_RENDER
 STATE_POST_RENDER
 STATE_FINI

They can be loaded using the tag ":state".

These constants are used by plugins.

 PLUGIN_NEXT
 PLUGIN_ABORT

They can be loaded using the tag ":plugins".

These constants are used by the Session manager and the Uaf authentication
and authorization modules.

 SESSION_ID
 TOKEN_ID

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
