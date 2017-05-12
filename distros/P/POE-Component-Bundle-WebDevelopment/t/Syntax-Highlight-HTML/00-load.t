#!/usr/bin/env perl

use Test::More tests => 6;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('Syntax::Highlight::HTML');
	use_ok( 'POE::Component::Syntax::Highlight::HTML' );
}

diag( "Testing POE::Component::Syntax::Highlight::HTML $POE::Component::Syntax::Highlight::HTML::VERSION, Perl $], $^X" );

my $poco = POE::Component::Syntax::Highlight::HTML->spawn;

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->parse( {
            event => 'results',
            in    => '<p>Foo <a href="bar">bar</a></p>',
        }
    );
}

sub results {

my $VAR1 = {
          "out" => "<pre>\n<span class=\"h-ab\">&lt;</span><span class=\"h-tag\">p</span><span class=\"h-ab\">&gt;</span>Foo <span class=\"h-ab\">&lt;</span><span class=\"h-tag\">a</span> <span class=\"h-attr\">href</span>=<span class=\"h-attv\">\"bar</span>\"<span class=\"h-ab\">&gt;</span>bar<span class=\"h-ab\">&lt;/</span><span class=\"h-tag\">a</span><span class=\"h-ab\">&gt;</span><span class=\"h-ab\">&lt;/</span><span class=\"h-tag\">p</span><span class=\"h-ab\">&gt;</span></pre>\n",
          "in" => "<p>Foo <a href=\"bar\">bar</a></p>"
        };


    is_deeply( $_[ARG0], $VAR1, 'output matches expected');

    $poco->shutdown;
}