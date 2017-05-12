#!/usr/bin/env perl

use Test::More;
use lib 'lib';

use Mojolicious::Lite;
plugin 'JSUrlFor';
get '/get_test_route' => sub { } => 'simple_route';


require Mojolicious::Command::generate::js_url_for;
my $command = Mojolicious::Command::generate::js_url_for->new();
$command->app(app);

subtest 'Test help' => sub {
    like( $command->description, qr/Generate "url_for" function/, 'should have description' );
    like( $command->usage, qr/\$file - file for saving javascript code/, 'should have usage' );
};

subtest 'Run command' => sub {
    my $file = 'js_url_for_tmp.js';

    unlink($file);
    $command->run($file);

    ok( open(my $fh, '<', $file), 'file should be present and readable' );
    my $content = do {undef $/; <$fh>};

    like($content, qr/function url_for\(route_name, captures\)/, 'content should have url_for function');
    like($content, qr/"simple_route":"\\?\/get_test_route"/, 'routes should be there');

    close($fh);
    ok(unlink($file), 'should remove file after test');
};

subtest 'Negative test: run with wrong options' => sub {
    eval { $command->run };
    ok( $@, 'should throw exception if called without file path' );
    like( $@ ,   qr/\$file - file for saving javascript code/, 'should show help' );
};


done_testing;
