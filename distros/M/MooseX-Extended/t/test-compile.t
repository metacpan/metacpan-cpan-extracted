#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests module => 'Test::Compile';
use Test::Compile v3.1.0;    # not needed directly, but make sure various cpan clients pick it up
use Test::Compile::Internal;

explain <<'END';
This is an attempt to exercise the bug described in
https://github.com/Ovid/moosex-extended/issues/41.

In short, with Test::Compile, we have intermittent segfault when using
'immutable'. However, that's a proprietary codebase that cannot be shared.
Thus, we're using this to try to shake out the bug, but so far, we can't.
END

package My::Test::Compile {

    # This is naughty, overriding an internal method, but
    # the class doesn't quite do what we want. We might revisit
    # this in the future.
    use parent "Test::Compile::Internal";

    sub all_pl_files {
        my ( $self, @dirs ) = @_;

        @dirs = @dirs ? @dirs : _pl_starting_points();

        my @pl;
        for my $file ( $self->_find_files(@dirs) ) {
            if ( $file =~ /\.p(?:m|l|sgi)$/i ) {

                # Files with .pl or .psgi extensions are perl scripts
                push @pl, $file;
            }
            else {

                # Files with no extension, but a perl shebang are perl scripts
                my $shebang = $self->_read_shebang($file);
                if ( $shebang =~ m/perl/ ) {
                    push @pl, $file;
                }
            }
        }
        return @pl;
    }
}

my $test = My::Test::Compile->new();
$test->all_pl_files_ok(qw/lib t/);
$test->done_testing();
