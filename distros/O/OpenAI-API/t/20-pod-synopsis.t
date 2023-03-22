#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my @test_cases = qw(
    OpenAI::API
    OpenAI::API::Config
    OpenAI::API::Request::Chat
    OpenAI::API::Request::Completion
    OpenAI::API::Request::Edit
    OpenAI::API::Request::Embedding
    OpenAI::API::Request::File::List
    OpenAI::API::Request::File::Retrieve
    OpenAI::API::Request::Image::Generation
    OpenAI::API::Request::Model::List
    OpenAI::API::Request::Model::Retrieve
    OpenAI::API::Request::Moderation
);

for my $module (@test_cases) {
    use_ok($module);

    my $code = _extract_code_from_synopsis($module);

    if ($code) {
        eval($code);
        if ($@) {
            fail("Error: $@");
        } else {
            pass('eval(SYNOPSIS)');
        }
    } else {
        fail('synopsis code not found');
    }
}

done_testing();

sub _extract_code_from_synopsis {
    my ($module) = @_;

    my $filename = $INC{ $module =~ s{::}{/}gr . '.pm' };

    my $file = do { local ( @ARGV, $/ ) = $filename; <> };

    my ($code) = $file =~ m{=head1 SYNOPSIS\n(.+?)=head1}ms;

    return $code;
}
