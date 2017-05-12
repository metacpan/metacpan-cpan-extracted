use strict;
use warnings;

use Mojolicious::Lite;
use Test::More 1.302067;

isa_ok app->log, 'Mojo::Log';
can_ok app->log, 'history';

require MojoX::Log::Any;
MojoX::Log::Any->import;

isa_ok app->log, 'Log::Any::Proxy';

isa_ok app->log->adapter, 'Log::Any::Adapter::MojoLog';

use Log::Any::Adapter;
Log::Any::Adapter->set('Stderr');

isa_ok app->log->adapter, 'Log::Any::Adapter::Stderr';
can_ok app->log, 'history';
can_ok app->log, 'format';

my $log = app->log;
MojoX::Log::Any->import;
is app->log, $log, 'Do not replace existing adapter';

done_testing();
