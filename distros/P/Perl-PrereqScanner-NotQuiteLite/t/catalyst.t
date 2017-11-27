use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# from Catalyst's pod
test('qw', <<'END', {Catalyst => 0, 'Catalyst::Plugin::My::Module' => 0, 'Fully::Qualified::Plugin::Name' => 0});
use Catalyst qw/
        My::Module
        +Fully::Qualified::Plugin::Name
    /;
END

# GSHANK/HTML-FormHandler-Model-DBIC-0.29/t/lib/BookDB.pm
test('-debug', <<'END', {Catalyst => 0, 'Catalyst::Plugin::Static::Simple' => 0});
use Catalyst ('-Debug',
              'Static::Simple',
);
END

# FLORA/Catalyst-Engine-Apache-1.16/t/lib/PluginTestApp.pm
# TestApp::Plugin::ParameterizedRole is ignored for now
test('eval', <<'END', {Catalyst => 0, 'Catalyst::Plugin::Test::Plugin' => 0, 'TestApp::Plugin::FullyQualified' => 0});
use Catalyst (
    'Test::Plugin',
    '+TestApp::Plugin::FullyQualified',
    (eval { require MooseX::Role::Parameterized; 1 }
        ? ('+TestApp::Plugin::ParameterizedRole' => { method_name => 'affe' })
        : ()),
);
END

done_testing;
