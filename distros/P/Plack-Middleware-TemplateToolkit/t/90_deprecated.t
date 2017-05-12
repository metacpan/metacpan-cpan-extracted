use strict;
use Test::More 0.98;
use Test::Warn;

use Plack::Middleware::TemplateToolkit;

my $tt;
warnings_exist { 
    $tt = Plack::Middleware::TemplateToolkit->new( 
        INCLUDE_PATH => '.',  process => 1 ); 
} ['deprecated'], 'deprecated accessor';

$tt = Plack::Middleware::TemplateToolkit->new( INCLUDE_PATH => '.' );
warnings_exist { $tt->eval_perl(1); } ['deprecated'], 'deprecated method';
is $tt->EVAL_PERL, 1, 'can still be used';

done_testing;
