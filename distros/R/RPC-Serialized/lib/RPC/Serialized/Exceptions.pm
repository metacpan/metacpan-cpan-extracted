#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/Exceptions.pm $
# $LastChangedRevision: 1361 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::Exceptions;
{
  $RPC::Serialized::Exceptions::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use Symbol;
sub import {

    # Exception::Class looks at caller() to insert raise_error into that
    # Namespace, so this hack means whoever use's us, they get a raise_error
    # of their very own.

    *{Symbol::qualify_to_ref('throw_proto',caller())}
        = sub { RPC::Serialized::X::Protocol->throw(@_) };

    *{Symbol::qualify_to_ref('throw_parse',caller())}
        = sub { RPC::Serialized::X::Parse->throw(@_) };

    *{Symbol::qualify_to_ref('throw_invalid',caller())}
        = sub { RPC::Serialized::X::Validation->throw(@_) };

    *{Symbol::qualify_to_ref('throw_system',caller())}
        = sub { RPC::Serialized::X::System->throw(@_) };

    *{Symbol::qualify_to_ref('throw_app',caller())}
        = sub { RPC::Serialized::X::Application->throw(@_) };

    *{Symbol::qualify_to_ref('throw_authz',caller())}
        = sub { RPC::Serialized::X::Authorization->throw(@_) };

    # this is to quiesce Carp::carp which is called from within Data::Serializer
    # and turn its output into Carp::croak.

    use Carp;
    {
        no warnings 'redefine';
        sub Carp::carp {
            die Carp::shortmess @_ if (caller)[0] =~ m/Data::Serializer/;
            warn Carp::shortmess @_;
        }
    }
}

use Exception::Class (
    'RPC::Serialized::X',

    'RPC::Serialized::X::Protocol',
    {   isa         => 'RPC::Serialized::X',
        description => 'RPC protocol error',
        alias       => 'throw_proto',
    },

    'RPC::Serialized::X::Parse',
    {   isa         => 'RPC::Serialized::X',
        description => 'Data::Serializer parse error',
        alias       => 'throw_parse',
    },

    'RPC::Serialized::X::Validation',
    {   isa         => 'RPC::Serialized::X',
        description => 'Data validation error',
        alias       => 'throw_invalid',
    },

    'RPC::Serialized::X::System',
    {   isa         => 'RPC::Serialized::X',
        description => 'System error',
        alias       => 'throw_system',
    },

    'RPC::Serialized::X::Application',
    {   isa         => 'RPC::Serialized::X',
        description => 'Application programming error',
        alias       => 'throw_app',
    },

    'RPC::Serialized::X::Authorization',
    {   isa         => 'RPC::Serialized::X',
        description => 'Authorization failed',
        alias       => 'throw_authz',
    }

);

1;

