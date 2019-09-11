# Kit.pm: test kit for Sub::Multi::Tiny
package # hide from PAUSE
    Kit;

use 5.006;
use strict;
use warnings;

use parent 'Exporter';
use vars::i '@EXPORT' => qw(find_file_in_t get_perl_filename run_perl);

use Config;
use Cwd 'abs_path';
use File::Spec;
use Import::Into;
use IPC::Run3;
use Test::More;

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
    my $is_covering = !!(eval 'Devel::Cover::get_coverage()');
    diag $is_covering ? 'Devel::Cover running' : 'Devel::Cover not covering';

    # Note: See App-PRT/t/App-PRT-CLI.t for code to find test scripts in
    # script vs. blib/script.

    # Make the command to run script/prt.
    my @cmd = ($perl, $is_covering ? ('-MDevel::Cover=-silent,1') : ());

    push @cmd, map { "-I$_" } @INC;
    push @cmd, @$lrArgs;
    diag 'Running ', join ' ', @cmd;
    run3 \@cmd, \$in, \$out, \$err;     # Dies on error

    my $exitstatus = $?;
    diag "Error message was '$err'" if $err;
    return ($out, $err, $exitstatus);
} #run_perl

# Import
sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);
    $_->import::into($target) foreach qw(strict warnings Config Cwd
        File::Spec IPC::Run3 Test::More);
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
