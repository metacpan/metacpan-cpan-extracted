# Related information:
# https://rt.cpan.org/Public/Bug/Display.html?id=47865
# https://rt.cpan.org/Public/Bug/Display.html?id=52474
# https://rt.cpan.org/Public/Bug/Display.html?id=57683
# http://www.nntp.perl.org/group/perl.moose/2010/06/msg1767.html

# Summary: If we disable the "auto_help" option in Getopt::Long, then
# getoptions() will not call into pod2usage() (causing program termination)
# when --help is passed (and MooseX::ConfigFromFile is in use).

use strict;
use warnings;

use Test::Needs { 'MooseX::SimpleConfig' => '0.07' };
use Test::More 0.88;
use Test::Deep;
use Test::Fatal 0.003;
use Test::Warnings 0.009 qw(:no_end_test :all);

my $fail_on_exit = 1;
{
    package Class;
    use strict; use warnings;

    use Moose;
    with
        'MooseX::SimpleConfig',
        'MooseX::Getopt';

    # this is a hacky way of being able to check that we made it past the
    # $opt_parser->getoptions() call in new_with_options, because it is
    # still going to bail out later on, on seeing the --help flag
    has configfile => (
        is => 'ro', isa => 'Str',
        default => sub {
            $fail_on_exit = 0;
            'this_value_unimportant',
        },
    );

    around print_usage_text => sub {
        my ($orig, $self, $usage) = @_;
        die $usage->text;
    };

    no Moose;
    1;
}

@ARGV = ('--help');

my @warnings = warnings {
    like(
        exception { Class->new_with_options },
        qr/^usage: [\d\w]+.+\Q[long options...]\E\n.*--usage --help\s+Prints this usage information/ms,
        'usage information looks good',
    );
};

cmp_deeply(
    \@warnings,
    [ re(qr/^Specified configfile \'this_value_unimportant\' does not exist, is empty, or is not readable$/) ],
    'Our dummy config file doesn\'t exist',
) or diag join "\n", @warnings;

ok(!$fail_on_exit, 'getoptions() lives');

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
