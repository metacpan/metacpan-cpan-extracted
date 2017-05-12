package t::Utils;
use strict;
use warnings;
use Test::More;
use String::Diff;
use Data::Dumper;
use Term::ANSIColor qw(color);
use base 'Exporter';

our @EXPORT = qw/color_diff/;

sub color_diff {
    my ($out, $exp) = @_;

    diag String::Diff::diff(
        $out, $exp,
        (
            remove_open  => color('black on_red'),
            remove_close => color('reset'),
            append_open  => color('black on_green'),
            append_close => color('reset'),
        )
    );
}

1;
