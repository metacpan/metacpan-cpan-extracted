#!/usr/bin/perl 

use strict;

use Test::More tests => 12;

use_ok( 'POE::Component::IKC' ) or die;
use_ok( 'POE::Component::IKC::Specifier' );
use_ok( 'POE::Component::IKC::ClientLite' );
use_ok( 'POE::Component::IKC::Freezer' );
use_ok( 'POE::Component::IKC::Proxy' );
use_ok( 'POE::Component::IKC::Channel' ) or die;
use_ok( 'POE::Component::IKC::LocalKernel' );
use_ok( 'POE::Component::IKC::Responder' ) or die;
use_ok( 'POE::Component::IKC::Server' );
use_ok( 'POE::Component::IKC::Timing' );
use_ok( 'POE::Component::IKC::Util' );

package other;
::use_ok( 'POE::Component::IKC::Client' );
