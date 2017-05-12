use strict;
use warnings;

use Test::Spec;
use ObjectDB::Util 'merge_rows';

describe 'merge rows' => sub {

    it 'not merge when different columns' => sub {
        my $merged = merge_rows([{foo => 'bar'}, {bar => 'baz'}]);

        is_deeply($merged, [{foo => 'bar'}, {bar => 'baz'}]);
    };

    it 'not merge when different undefined values' => sub {
        my $merged = merge_rows([{foo => 'bar'}, {foo => undef}]);

        is_deeply($merged, [{foo => 'bar'}, {foo => undef}]);
    };

    it 'not merge when different values' => sub {
        my $merged = merge_rows([{foo => 'bar'}, {foo => 'baz'}]);

        is_deeply($merged, [{foo => 'bar'}, {foo => 'baz'}]);
    };

    it 'merge when same keys and values' => sub {
        my $merged = merge_rows([{foo => 'bar'}, {foo => 'bar'}]);

        is_deeply($merged, [{foo => 'bar'}]);
    };

    it 'not merge when different joins' => sub {
        my $merged = merge_rows(
            [{foo => 'bar', join1 => {}}, {foo => 'bar', join2 => {}}]);

        is_deeply($merged,
            [{foo => 'bar', join1 => {}}, {foo => 'bar', join2 => {}}]);
    };

    it 'merge same joins' => sub {
        my $merged = merge_rows(
            [
                {foo => 'bar', join => {hi => 'there'}},
                {foo => 'bar', join => {hi => 'there'}}
            ]
        );

        is_deeply($merged, [{foo => 'bar', join => {hi => 'there'}}]);
    };

    it 'merge different joins' => sub {
        my $merged = merge_rows(
            [
                {foo => 'bar', join => {hi => 'here'}},
                {foo => 'bar', join => {hi => 'there'}}
            ]
        );

        is_deeply($merged,
            [{foo => 'bar', join => [{hi => 'here'}, {hi => 'there'}]}]);
    };

    it 'merge different joins several times' => sub {
        my $merged = merge_rows(
            [
                {foo => 'bar', join => {hi => 'here'}},
                {foo => 'bar', join => {hi => 'there'}},
                {foo => 'bar', join => {hi => 'everywhere'}}
            ]
        );

        is_deeply(
            $merged,
            [
                {
                    foo => 'bar',
                    join =>
                      [{hi => 'here'}, {hi => 'there'}, {hi => 'everywhere'}]
                }
            ]
        );
    };

    it 'merge rows that do not follow each other' => sub {
        my $merged = merge_rows(
            [
                {foo => 'bar', join => {hi => 'here'}},
                {foo => 'baz', join => {hi => 'there'}},
                {foo => 'bar', join => {hi => 'everywhere'}}
            ]
        );

        is_deeply(
            $merged,
            [
                {
                    foo  => 'bar',
                    join => [{hi => 'here'}, {hi => 'everywhere'}]
                },
                {
                    foo  => 'baz',
                    join => {hi => 'there'}
                }
            ]
        );
    };

};

runtests unless caller;
