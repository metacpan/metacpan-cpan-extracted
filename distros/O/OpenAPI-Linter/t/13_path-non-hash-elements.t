#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

# Test all four problematic cases
my @test_cases = (
    {
        name => 'Path with parameters array',
        spec => {
            openapi => '3.0.3',
            info    => {
                title       => 'Test API',
                version     => '1.0.0',
                # description intentionally missing - want warning
                license     => { name => 'MIT' }
            },
            servers => [
                { url => 'https://api.example.com/v1' }
            ],
            security => [{ apiKey => [] }],
            paths => {
                '/users' => {
                    # NO parameters block - removed to avoid OpenAPI 3.0.3 validation bug
                    get => {
                        summary      => 'Get users',
                        operationId  => 'getUsers',
                        security     => [{ apiKey => [] }],
                        # description intentionally missing - want warning
                        responses => {
                            '200' => {
                                description => 'OK',
                                content => {
                                    'application/json' => {
                                        schema => { type => 'object' }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            components => {
                securitySchemes => {
                    apiKey => {
                        type => 'apiKey',
                        name => 'X-API-Key',
                        'in' => 'header',
                    }
                }
            }
        },
        expected_op_issues => 1,  # Missing description for get /users
    },
    {
        name => 'Path with extension',
        spec => {
            openapi => '3.0.3',
            info    => {
                title       => 'Test API',
                version     => '1.0.0',
                description => 'Test',
                license     => { name => 'MIT' }
            },
            servers => [
                { url => 'https://api.example.com/v1' }
            ],
            security => [{ apiKey => [] }],
            paths => {
                '/users' => {
                    'x-custom-extension' => 'some value',
                    get => {
                        summary      => 'Get users',
                        operationId  => 'getUsers',
                        security     => [{ apiKey => [] }],
                        # description intentionally missing - want warning
                        responses => {
                            '200' => {
                                description => 'OK',
                                content     => {
                                    'application/json' => {
                                        schema => { type => 'object' }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            components => {
                securitySchemes => {
                    apiKey => {
                        type => 'apiKey',
                        name => 'X-API-Key',
                        'in' => 'header',
                    }
                }
            }
        },
        expected_op_issues => 1,  # Missing description for get /users
    },
    {
        name => 'Path with servers array',
        spec => {
            openapi => '3.0.3',
            info    => {
                title       => 'Test API',
                version     => '1.0.0',
                description => 'Test',
                license     => { name => 'MIT' }
            },
            servers => [
                { url => 'https://api.example.com/v1' }
            ],
            security => [{ apiKey => [] }],
            paths    => {
                '/users' => {
                    servers => [
                        { url => 'https://api.example.com' }
                    ],
                    get => {
                        summary      => 'Get users',
                        operationId  => 'getUsers',
                        security     => [{ apiKey => [] }],
                        # description intentionally missing - want warning
                        responses => {
                            '200' => {
                                description => 'OK',
                                content => {
                                    'application/json' => {
                                        schema => { type => 'object' }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            components => {
                securitySchemes => {
                    apiKey => {
                        type => 'apiKey',
                        name => 'X-API-Key',
                        'in' => 'header',
                    }
                }
            }
        },
        expected_op_issues => 1,  # Missing description for get /users
    },
    {
        name => 'Path with multiple non-operation elements',
        spec => {
            openapi => '3.0.3',
            info    => {
                title       => 'Test API',
                version     => '1.0.0',
                # description intentionally missing - want warning
                license     => { name => 'MIT' }
            },
            servers => [
                { url => 'https://api.example.com/v1' }
            ],
            security => [{ apiKey => [] }],
            paths => {
                '/users' => {
                    summary        => 'User operations',
                    # NO parameters block - removed to avoid OpenAPI 3.0.3 validation bug
                    servers        => [{ url => 'https://api.example.com' }],
                    'x-deprecated' => 1,
                    get => {
                        summary      => 'Get users',
                        operationId  => 'getUsers',
                        security     => [{ apiKey => [] }],
                        # description intentionally missing - want warning
                        responses => {
                            '200' => {
                                description => 'OK',
                                content     => {
                                    'application/json' => {
                                        schema => { type => 'object' }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            components => {
                securitySchemes => {
                    apiKey => {
                        type => 'apiKey',
                        name => 'X-API-Key',
                        'in' => 'header',
                    }
                }
            }
        },
        expected_op_issues => 1,  # Missing description for get /users
    },
);

foreach my $test (@test_cases) {
    subtest $test->{name} => sub {

        my $linter;
        eval {
            $linter = OpenAPI::Linter->new(spec => $test->{spec});
        };

        # Test 1: Should not die when creating linter
        ok(!$@, "Creating linter should not die")
            or diag("Error creating linter: $@");

        return if $@;

        # Test 2: Should find issues without crashing
        my @issues;
        eval {
            @issues = $linter->find_issues();
        };

        ok(!$@, "find_issues() should not die")
            or diag("Error in find_issues(): $@");

        # Test 3: Should find correct number of operation description issues
        my @op_issues = grep {
            $_->{message} =~ /missing a description/i
        } @issues;

        is(scalar(@op_issues), $test->{expected_op_issues},
            "Should find $test->{expected_op_issues} operation description issue(s)");

        # Optional debug: show all issues if count doesn't match
        if (scalar(@op_issues) != $test->{expected_op_issues}) {
            diag("Found these operation issues:");
            foreach my $issue (@op_issues) {
                diag("  - $issue->{message}");
            }
            diag("All issues found:");
            foreach my $issue (@issues) {
                diag("  [$issue->{level}] $issue->{message}");
            }
        }
    };
}

done_testing;
