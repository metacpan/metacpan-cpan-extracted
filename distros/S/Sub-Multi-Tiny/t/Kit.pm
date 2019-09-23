# -*- perl -*-

# Kit.pm: test kit for Sub::Multi::Tiny
package # hide from PAUSE
    Kit;

use 5.006;
use strict;
use warnings;

use parent 'Exporter';
use vars::i '@EXPORT' => qw(fails_ok find_file_in_t get_perl_filename here
                            is_covering run_perl true false);

use Config;
use Cwd 'abs_path';
use Data::Dumper;
use File::Spec;
use Import::Into;
use IPC::Run3;
use Test::More;

# is_covering: is Devel::Cover running?
sub is_covering {
    return !!(eval 'Devel::Cover::get_coverage()');
} #is_covering()

# Set verbosity:
#   - on for coverage of _hlog statements
#   - on for debugging of test failures in <5.18    XXX DEBUG
# Note that verbosity will also be on if $ENV{SUB_MULTI_TINY_VERBOSE} is set.
use Sub::Multi::Tiny::Util '*VERBOSE';
BEGIN {
    $VERBOSE = 99 if is_covering || $] lt '5.018';
}

use constant {
    true => !!1,
    false => !!0,
};


# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    die "Could not find perl interpreter" unless $secure_perl_path;
    return $secure_perl_path;
} # get_perl_filename()

# }}}1

# find_file_in_t($filename[, checks]).  Assumes caller is in t/.
sub find_file_in_t {
    my (undef, $filename) = caller;

    my $here = abs_path($filename);
    die "Could not find my file location: $!" unless defined $here;
    my ($volume,$directories,undef) = File::Spec->splitpath( $here );

    my $pl_file = File::Spec->catpath(
        $volume,
        $directories,
        shift
    );

    # File tests, if requested.
    foreach(@_) {
        die "Can not read $pl_file" if $_ eq 'r' && !( -f $pl_file && -r _);
        die "Can not write $pl_file" if $_ eq 'w' && !( -w $pl_file );
        die "Can not execute $pl_file" if $_ eq 'x' && !( -f $pl_file && -x _);
    }

    return $pl_file;
} #find_file_in_t

# ($out, $err, $exitstatus) = run_perl(args arrayref, [$stdin text if any])
sub run_perl {
    my $perl = get_perl_filename;
    my ($lrArgs, $in) = @_;
    $in = '' unless defined $in;
    my ($out, $err);

    # Check if we are running under cover(1) from Devel::Cover
    diag is_covering() ? 'Devel::Cover running' : 'Devel::Cover not covering';

    # Note: See App-PRT/t/App-PRT-CLI.t for code to find test scripts in
    # script vs. blib/script, if that later becomes necessary.

    # Make the command to run script/prt.
    my @cmd = ($perl, is_covering() ? ('-MDevel::Cover=-silent,1') : ());

    push @cmd, map { "-I$_" } @INC;
    push @cmd, @$lrArgs;
    diag 'Running ', join ' ', @cmd;
    run3 \@cmd, \$in, \$out, \$err;     # Dies on error

    my $exitstatus = $?;
    diag "Error message was '$err'" if $err;
    return ($out, $err, $exitstatus);
} #run_perl

# here: Return the caller's line number, in parentheses.
# Useful for the message on an ok() or is().
sub here {
    my (undef, undef, $lineno) = caller;
    return "line $lineno";
} #here

# Execute a file and check its error message.  Skips on Windows.
# Usage: fails_ok('filename in t', qr/regex error should match/);
sub fails_ok {
    my ($filename, $regex) = @_;
    my (undef, undef, $lineno) = caller;

    SKIP: {
        # Skip rather than falsely fail - see
        # https://github.com/rjbs/IPC-Run3/pull/9 and RT#95308.  Example at
        # http://www.cpantesters.org/cpan/report/277b2ad8-6bf8-1014-b7dc-c8197f9146ad
        skip 'MSWin32 gives a false failure on this test', 2
            if $^O eq 'MSWin32';

        # We have to run the test in a separate Perl process so we can see
        # errors at INIT time

        # Find the Perl file to run
        my $pl_file = find_file_in_t($filename, 'r');
        my ($out, $err, $exitstatus) = run_perl([$pl_file]);

        cmp_ok $exitstatus>>8, '!=', 0,
            "returned a failure indication (line $lineno)";
        like $err, $regex, "error message as expected (line $lineno)";

    }
} #fails_ok

# Import
sub import {
    my ($target, $filename) = caller;
    __PACKAGE__->export_to_level(1, @_);
    $_->import::into($target) foreach qw(strict warnings Config Cwd
        File::Spec IPC::Run3 Test::More);

    $Data::Dumper::Indent = 1;  # fixed indentation per level

    diag '#' x 40;
    diag $filename;
}

1;
# Documentation {{{1
__END__

=head1 NAME

Kit - Test kit for Sub::Multi::Tiny

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
