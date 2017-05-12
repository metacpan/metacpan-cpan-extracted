use strict;
use warnings;

use Test::Deep qw(cmp_details deep_diag);

sub test_plugin
{
    # got and exp to use in test;
    # expecting an ok?
    # expected diag, if not ok
    my ($data_got, $data_exp, $exp_ok, $exp_diag) = @_;
    return sub {
        my ($ok, $stack) = cmp_details($data_got, $data_exp);

        ok( !($ok xor $exp_ok), 'test ' . ($exp_ok ? 'passed' : 'failed'));
        return if not Test::Builder->new->is_passing;

        if (not $ok)
        {
            my $diag = deep_diag($stack);
            if (__is_regexp($exp_diag))
            {
                like($diag, $exp_diag, 'failure diagnostics');
            }
            else
            {
                is($diag, $exp_diag, 'failure diagnostics');
            }
        }
    };
}

# TODO: put back into Test::Deep
sub cmp_diag
{
    my ($got, $expected) = @_;
    my ($ok, $stack) = cmp_details($got, $expected);
    return $ok if $ok;
    return ($ok, deep_diag($stack));
}

sub __is_regexp
{
    re->can('is_regexp') ? re::is_regexp(shift) : ref(shift) eq 'Regexp';
}

1;
