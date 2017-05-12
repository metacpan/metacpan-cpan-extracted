#!perl -T

use Test::More;

my $test_data = {

    testcases       => [
        {
            description     => 'Simple regexes without replacements',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            reggrp      => [
                {
                    regexp  => qr/ab/
                },
                {
                    regexp  => qr/yz/
                },
                {
                    regexp  => qr/foo/
                }
            ]
        },
        {
            description     => 'Simple regexes with scalar replacements',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'ABcdefghijklmnopqrstuvwxYZABcdefghijklmnopqrstuvwxYZ',
            reggrp      => [
                {
                    regexp      => qr/ab/,
                    replacement => 'AB'
                },
                {
                    regexp      => qr/yz/,
                    replacement => 'YZ'
                },
                {
                    regexp      => qr/foo/,
                    replacement => 'BAR'
                }
            ]
        },
        {
            description     => 'Simple regexes with sub replacements I',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'bacdefghijklmnopqrstuvwxyYZbacdefghijklmnopqrstuvwxyYZ',
            reggrp      => [
                {
                    regexp      => qr/(a)(.)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[1], $submatches->[0] );
                    }
                },
                {
                    regexp      => qr/((y)z)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[1], uc( $submatches->[0] ) );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Simple regexes with sub replacements II',
            input_string    => 'a1a2a0a1a0a2a3bcde',
            expected_output => 'a1a2a0a1a0a2a3bcde',
            reggrp      => [
                {
                    regexp      => qr/(a)(\d)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};

                        return sprintf( "%s%s", $submatches->[0], $submatches->[1] );
                    }
                }
            ]
        },
        {
            description     => 'Regexes with backreferences 1',
            input_string    => 'abcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyz',
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z).+(\1)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[0], uc( $submatches->[1] ) );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Regexes with backreferences 2',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => ( $] < 5.010000 ) ? 'bcxyzaAbcxyzabcxyz' : 'bcxyzaAbcxyzYyz',
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z)(.+)(\g{2})/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Store replacements',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => "\x01" . '0' . "\x01" . 'bcx' . "\x01" . '1' . "\x01" . 'z',
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Restore replacements',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyzYyz',
            test_restore    => 1,
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Store replacements with custom pattern',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => '~~0~~bcx~~1~~z',
            restore_pattern => qr/~~(\d+)~~/,
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $store_index = $in_ref->{store_index};
                        return sprintf( "~~%d~~", $store_index );
                    },
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $store_index = $in_ref->{store_index};
                        return sprintf( "~~%d~~", $store_index );
                    },
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Restore replacements with custom pattern',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyzYyz',
            restore_pattern => qr/~~(\d+)~~/,
            test_restore    => 1,
            reggrp      => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $store_index = $in_ref->{store_index};
                        return sprintf( "~~%d~~", $store_index );
                    },
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $store_index = $in_ref->{store_index};
                        return sprintf( "~~%d~~", $store_index );
                    },
                    store       => sub {
                        my $in_ref      = shift;
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref      = shift;
                        my $match       = $in_ref->{match};
                        my $submatches  = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                    }
                }
            ]
        },
        {
            description     => 'Modifier test 1',
            input_string    => "   \n\n\n\t   \n  a \nb\n  c\n\n",
            expected_output => "\n\n\n\na\nb\nc\n\n",
            reggrp      => [
                {
                    regexp      => '^[^\S\n]*',
                    replacement => ''
                },
                {
                    regexp      => '[^\S\n]$',
                    replacement => ''
                },
                {
                    regexp      => 'B',
                    replacement => 'd'
                }
            ]
        },
        {
            description     => 'Modifier test 2',
            input_string    => "   \n\n\n\t   \n  a \n\n\nb\n  c\n\n",
            expected_output => "a \n\n\nd\n  c",
            reggrp      => [
                {
                    regexp      => '^\s*',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => '\s*$',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => 'B',
                    replacement => 'd',
                    modifier    => 'i'
                }
            ]
        },
        {
            description     => 'Zero-length submatch test',
            input_string    => "   \n\n\n\t   \n  a \n\n\nb\n  c\n\n",
            expected_output => "a \n\n\nx\nc",
            reggrp      => [
                {
                    regexp      => '^\s*',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => '^[^\S\n]*',
                    replacement => '',
                    modifier    => 'm'
                },
                {
                    regexp      => '\s*$',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => 'b',
                    replacement => 'x'
                }
            ]
        }
    ]
};

SKIP: {
    my $not = scalar( @{$test_data->{testcases}} ) * 2;

    eval( 'use Regexp::RegGrp::Data' );
    skip( 'Regexp::RegGrp::Data not installed!', $not ) if ( $@ );

    eval( 'use Regexp::RegGrp' );
    skip( 'Regexp::RegGrp not installed!', $not ) if ( $@ );

    plan tests => $not;

    foreach my $tc ( @{$test_data->{testcases}} ) {
        my $reggrp  = Regexp::RegGrp->new( { reggrp => $tc->{reggrp}, restore_pattern => $tc->{restore_pattern} } );
        my $input   = $tc->{input_string};

        $reggrp->exec( \$input );

        if ( $tc->{test_restore} ) {
            $reggrp->restore_stored( \$input );
        }

        is( $input, $tc->{expected_output}, $tc->{description} . ' - void context' );

        $reggrp->flush_stored();

        $input = $tc->{input_string};

        my $output = $reggrp->exec( \$input );

        if ( $tc->{test_restore} ) {
            $output = $reggrp->restore_stored( \$output );
        }

        is( $output, $tc->{expected_output}, $tc->{description} . ' - scalar context' );
    }
}