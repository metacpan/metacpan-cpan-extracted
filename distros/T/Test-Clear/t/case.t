use strict;
use warnings;
use Test::More;
use Test::Clear;
use Test::Mock::Guard;

subtest 'capture' => sub {
    subtest 'embeded scalar variables' => sub {
        my $capture;
        my $guard = mock_guard('Test::Builder' => {
            subtest => sub { $capture = $_[1]; }
        });

        case 'basically name:{name}' => {
            name => 'hixi',
        }, sub { };
        like $capture, qr/basically name:hixi/;
    };
    subtest 'embeded hash variables' => sub {
        my $capture;
        my $guard = mock_guard('Test::Builder' => {
            subtest => sub { $capture = $_[1]; }
        });

        case 'basically person:{person}' => {
            person => {
                name => 'hixi',
            },
        }, sub { };
        like $capture, qr/basically person:{'name' => 'hixi'}/;
    };
};

subtest 'variables' => sub {
    subtest 'using hashref' => sub {
        case 'basically name:{name}' => {
            name => 'hixi',
        }, sub {
            my $dataset = shift;
            is $dataset->{name}, 'hixi';
        };
    };
    subtest 'using coderef' => sub {
        case 'basically uri:{uri}' => sub {
            my $schema    = 'http';
            my $authority = 'example.com';
            my $uri       = $schema. '://'. $authority;
            return {
                schema    => $schema,
                authority => $authority,
                uri       => $uri,
            }
        }, sub {
            my $dataset = shift;
            is $dataset->{schema}, 'http';
            is $dataset->{authority}, 'example.com';
            is $dataset->{uri}, 'http://example.com';
        };
    };
};

done_testing;
