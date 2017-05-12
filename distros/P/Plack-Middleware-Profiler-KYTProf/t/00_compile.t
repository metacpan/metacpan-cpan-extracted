use strict;
use warnings;
use Test::More;

use_ok('Plack::Middleware::Profiler::KYTProf');
use_ok('Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine');
use_ok('Plack::Middleware::Profiler::KYTProf::Profile::KVS');

done_testing;
