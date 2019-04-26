# Tests from Perl::Critic::Utils t/05_utils.t

use strict;
use warnings;

use PPI::Document;
use PPIx::Utils::Traversal ':all';
use Test::More;

test_first_arg();
test_parse_arg_list();
test_get_constant_name_elements_from_declaring_statement();

sub test_first_arg {
    my @tests = (
        q{eval { some_code() };}   => q{{ some_code() }},
        q{eval( {some_code() } );} => q{{some_code() }},
        q{eval();}                 => undef,
    );

    for (my $i = 0; $i < @tests; $i += 2) {
        my $code = $tests[$i];
        my $expect = $tests[$i+1];
        my $doc = PPI::Document->new(\$code);
        my $got = first_arg($doc->first_token());
        is($got ? "$got" : undef, $expect, 'first_arg - '.$code);
    }

    return;
}

sub test_parse_arg_list {
    my @tests = (
        [ q/foo($bar, 'baz', 1)/ => [ [ q<$bar> ],  [ q<'baz'> ],  [ q<1> ], ] ],
        [
                q/foo( { bar => 1 }, { bar => 1 }, 'blah' )/
            =>  [
                    [ '{ bar => 1 }' ],
                    [ '{ bar => 1 }' ],
                    [ q<'blah'> ],
                ],
        ],
        [
                q/foo( { bar() }, {}, 'blah' )/
            =>  [
                    [ q<{ bar() }> ],
                    [ qw< {} > ],
                    [ q<'blah'> ],
                ],
        ],
    );

    foreach my $test (@tests) {
        my ($code, $expected) = @{ $test };

        my $document = PPI::Document->new( \$code );
        my @got = parse_arg_list( $document->first_token() );
        is_deeply( \@got, $expected, "parse_arg_list: $code" );
    }

    return;
}

sub test_get_constant_name_elements_from_declaring_statement {
    my @tests = (
        ['use constant FOO => 1;', ['FOO']],
        ['use constant { FOO => 1 };', ['FOO']],
        ['use constant { FOO => 1, BAR => 2 };', ['FOO', 'BAR']],
        ['use constant +{ FOO => 1, BAR => 2 };', ['FOO', 'BAR']],
    );

    foreach my $test (@tests) {
        my ($code, $expected) = @{ $test };

        my $document = PPI::Document->new( \$code );
        my $st = $document->find_first('PPI::Statement::Include');
        my @got = get_constant_name_elements_from_declaring_statement( $st );
        is_deeply( \@got, $expected, "get_constant_name_elements_from_declaring_statement: $code" );
    }
    return;
}

done_testing;

