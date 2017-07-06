use strict;
use warnings;

package MyTestClass;
use strict;
use warnings;

use Moose;
with 'MooseX::Getopt::Kingpin';

my $lines_default = 10;
has 'lines' => (
    is            => 'ro',
    isa           => 'Int',
    default       => $lines_default,
    documentation => sub {
        my ($kingpin) = @_;
        $kingpin->flag('lines', 'print first N lines')
          ->default($lines_default)
          ->short('n')
          ->int();
    },
);

has 'input_file' => (
    is            => 'ro',
    isa           => 'Path::Tiny',
    required      => 1,
    documentation => sub {
        my ($kingpin) = @_;
        $kingpin->arg('input_file', 'input_file')
          ->required
          ->existing_file();
    },
);

has 'other_attr' => (is => 'ro', isa => 'Str');

package main;
use strict;
use warnings;

use Test::Exit;
use Test::More tests => 6;
use Test::Exception;
use Getopt::Kingpin;

use_ok('MooseX::Getopt::Kingpin');

throws_ok {
    MyTestClass->new_with_options();
} qr/First parameter ins't Getopt::Kingpin instance/, 'kingpin instance';

{
    local @ARGV = ();

    my $kingpin = Getopt::Kingpin->new();

    exits_nonzero {
        MyTestClass->new_with_options($kingpin);
    } 'missing required options';

}

{
    local @ARGV = ($0);

    my $kingpin = Getopt::Kingpin->new();

    my $my = MyTestClass->new_with_options($kingpin);

    is($my->input_file, $0, 'required input_file');
    is($my->lines, 10, 'default lines');
}

{
    local @ARGV = ($0, '--lines', 100);

    my $kingpin = Getopt::Kingpin->new();

    my $my = MyTestClass->new_with_options($kingpin);

    is($my->lines, 100, 'lines');
}
