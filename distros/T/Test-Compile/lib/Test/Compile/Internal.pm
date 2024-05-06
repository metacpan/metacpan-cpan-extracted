package Test::Compile::Internal;

use warnings;
use strict;

use version; our $VERSION = version->declare("v3.3.3");
use File::Find;
use File::Spec;
use Test::Builder;
use IPC::Open3 ();

=head1 NAME

Test::Compile::Internal - Assert that your Perl files compile OK.

=head1 SYNOPSIS

    use Test::Compile::Internal;
    my $test = Test::Compile::Internal->new();
    $test->all_files_ok();
    $test->done_testing();

=head1 DESCRIPTION

C<Test::Compile::Internal> is an object oriented tool for testing whether your
perl files compile.

It is primarily to provide the inner workings of C<Test::Compile>, but it can
also be used directly to test a CPAN distribution.

=head1 METHODS

=over 4

=item C<new()>

A basic constructor, nothing special.
=cut

sub new {
    my ($class, %self) = @_;
    my $self = \%self;

    $self->{test} = Test::Builder->new();

    bless ($self, $class);
    return $self;
}

=item C<all_files_ok(@search)>

Looks for perl files and tests them all for compilation errors.

If C<@search> is defined then it is taken as an array of files or
directories to be searched for perl files, otherwise it searches the default
locations you'd expect to find perl files in a perl module - see
L</all_pm_files> and L</all_pl_files> for details.

=cut
sub all_files_ok {
    my ($self, @search) = @_;

    my $pm_ok = $self->all_pm_files_ok(@search);
    my $pl_ok = $self->all_pl_files_ok(@search);

    return ( $pm_ok && $pl_ok );
}


=item C<all_pm_files_ok(@search)>

Checks all the perl module files it can find for compilation errors.

If C<@search> is defined then it is taken as an array of files or
directories to be searched for perl files, otherwise it searches the default
locations you'd expect to find perl files in a perl module - see
L</all_pm_files> for details.

=cut
sub all_pm_files_ok {
    my ($self, @search) = @_;

    my $test = $self->{test};

    my $ok = 1;
    for my $file ( $self->all_pm_files(@search) ) {
        my $testok = $self->pm_file_compiles($file);
        $ok = $testok ? $ok : 0;
        $test->ok($testok, "$file compiles");
    }
    return $ok;
}


=item C<all_pl_files_ok(@search)>

Checks all the perl program files it can find for compilation errors.

If C<@search> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pl_files>.

=cut
sub all_pl_files_ok {
    my ($self, @search) = @_;

    my $test = $self->{test};

    my $ok = 1;
    for my $file ( $self->all_pl_files(@search) ) {
        my $testok = $self->pl_file_compiles($file);
        $ok = $testok ? $ok : 0;
        $test->ok($testok, "$file compiles");
    }
    return $ok;
}


=item C<verbose($verbose)>

An accessor to get/set the verbosity.  The default value (undef) will suppress output
unless the compilation fails.  This is probably what you want.

If C<verbose> is set to true, you'll get the output from 'perl -c'. If it's set to
false, all diagnostic output is suppressed.

=cut

sub verbose {
    my ($self, $verbose) = @_;

    if ( @_ eq 2 ) {
        $self->{_verbose} = $verbose;
    }

    return $self->{_verbose};
}

=item C<all_pm_files(@search)>

Searches for and returns a list of perl module files - that is, files with a
F<.pm> extension.

If you provide C<@search>, it'll use that as a list of files to
process, or directories to search for perl modules.

If you don't provide C<search>, it'll search for perl modules in the F<blib/lib>
directory (if that directory exists). Otherwise it'll search the F<lib> directory.

Skips any files in F<CVS>, F<.svn>, or F<.git> directories.

=cut

sub all_pm_files {
    my ($self, @search) = @_;

    if ( ! @search ) {
        @search = $self->_default_locations('lib');
    }

    my @pm;
    for my $file ( $self->_find_files(@search) ) {
        if ( $self->_perl_module($file) ) {
            push @pm, $file;
        }
    }
    return @pm;
}

=item C<all_pl_files(@search)>

Searches for and returns a list of perl script files - that is, any files that
either have a case insensitive F<.pl>, F<.psgi> extension, or have no extension
but have a perl shebang line.

If you provide C<@search>, it'll use that as a list of files to
process, or directories to search for perl scripts.

If you don't provide C<search>, it'll search for perl scripts in the
F<blib/script/> and F<blib/bin/> directories if F<blib> exists, otherwise
it'll search the F<script/> and F<bin/> directories

Skips any files in F<CVS>, F<.svn>, or F<.git> directories.

=cut

sub all_pl_files {
    my ($self, @search) = @_;

    if ( ! @search ) {
        @search = $self->_default_locations('script', 'bin');
    }

    my @pl;
    for my $file ( $self->_find_files(@search) ) {
        if ( $self->_perl_script($file) ) {
            push @pl, $file;
        }
    }
    return @pl;
}

=item C<pl_file_compiles($file)>

Returns true if C<$file> compiles as a perl script.

=cut

sub pl_file_compiles {
    my ($self, $file) = @_;

    return $self->_perl_file_compiles($file);
}

=item C<pm_file_compiles($file)>

Returns true if C<$file> compiles as a perl module.

=back

=cut

sub pm_file_compiles {
    my ($self, $file) = @_;

    return $self->_perl_file_compiles($file);
}

=head1 TEST METHODS

C<Test::Compile::Internal> encapsulates a C<Test::Builder> object, and provides
access to some of its methods.

=over 4

=item C<ok($test, $name)>

Your basic test. Pass if C<$test> is true, fail if C<$test> is false. Just
like C<Test::Simple>'s C<ok()>.

=cut
sub ok {
    my ($self, @args) = @_;
    $self->{test}->ok(@args);
}

=item C<done_testing()>

Declares that you got to the end of your test plan, no more tests will be run after
this point.

=cut
sub done_testing {
    my ($self, @args) = @_;
    $self->{test}->done_testing(@args);
}

=item C<plan(tests =E<gt> $count)>

Defines how many tests you plan to run.

=cut
sub plan {
    my ($self, @args) = @_;
    $self->{test}->plan(@args);
}

=item C<diag(@msgs)>

Prints out the given C<@msgs>. Like print, arguments are simply appended
together.

Output will be indented and marked with a # so as not to interfere with
test output. A newline will be put on the end if there isn't one already.

We encourage using this rather than calling print directly.

=cut

sub diag {
    my ($self, @args) = @_;
    $self->{test}->diag(@args);
}

=item C<skip($reason)>

Skips the current test, reporting the C<$reason>.

=cut

sub skip {
    my ($self, @args) = @_;
    $self->{test}->skip(@args);
}

=item C<skip_all($reason)>

Skips all the tests, using the given C<$reason>. Exits immediately with 0.

=back
=cut

sub skip_all {
    my ($self, @args) = @_;
    $self->{test}->skip_all(@args);
}

# Run a subcommand, catching STDOUT, STDERR and return code
sub _run_command {
    my ($self, $cmd) = @_;

    my ($stdout, $stderr);
    my $pid = IPC::Open3::open3(0, $stdout, $stderr, $cmd)
        or die "open3() failed $!";

    my $output = [];
    for my $handle ( $stdout, $stderr ) {
        if ( $handle ) {
            while ( my $line = <$handle> ) {
                push @$output, $line;
            }
        }
    }

    waitpid($pid, 0);
    my $success = ($? == 0 ? 1 : 0);

    return ($success, $output);
}

# Works it's way through the input array (files and/or directories), recursively
# finding files
sub _find_files {
    my ($self, @search) = @_;

    my @filelist;
    my $addFile = sub {
        my ($fname) = @_;

        if ( -f $fname ) {
            if ( !($fname =~ m/CVS|\.svn|\.git/) ) {
                push @filelist, $fname;
            }
        }
    };

    for my $item ( @search ) {
        $addFile->($item);
        if ( -d $item ) {
            no warnings 'File::Find';
            find({wanted => sub{$addFile->($File::Find::name)}, no_chdir => 1}, $item);
        }
    }
    return (sort @filelist);
}

# Check the syntax of a perl file
sub _perl_file_compiles {
    my ($self, $file) = @_;

    if ( ! -f $file ) {
        if ( $self->verbose() ) {
            $self->{test}->diag("$file could not be found");
        }
        return 0;
    }

    my @inc = (File::Spec->catdir("blib", "lib"), @INC);
    my $taint = $self->_taint_mode($file);
    my $command = join(" ", (qq{"$^X"}, (map { qq{"-I$_"} } @inc), "-c$taint", $file));
    if ( $self->verbose() ) {
        $self->{test}->diag("Executing: " . $command);
    }
    my ($compiles, $output) = $self->_run_command($command);
    if ( !defined($self->verbose()) || $self->verbose() != 0 ) {
        if ( !$compiles || $self->verbose() ) {
            for my $line ( @$output ) {
                $self->{test}->diag($line);
            }
        }
    }

    return $compiles;
}

# Where do we expect to find perl files?
sub _default_locations {
    my ($self, @dirs) = @_;

    my $blib = -e 'blib';
    my @locations = ();

    for my $dir ( @dirs ) {
        my $location = File::Spec->catfile($dir);
        if ( $blib ) {
            $location = File::Spec->catfile('blib', $dir);
        }
        if ( -e $location ) {
            push @locations, $location;
        }
    }
    return @locations;
}

# Extract the shebang line from a perl program
sub _read_shebang {
    my ($self, $file) = @_;

    if ( open(my $f, "<", $file) ) {
        my $line = <$f>;
        if (defined $line && $line =~ m/^#!/ ) {
            return $line;
        }
    }
}

# Should the given file be checked with taint mode on?
sub _taint_mode {
    my ($self, $file) = @_;

    my $shebang = $self->_read_shebang($file);
    my $taint = "";
    if ($shebang =~ /^#!\s*[\/\w]+\s+-\w*([tT])/) {
        $taint = $1;
    }
    return $taint;
}

# Does this file look like a perl script?
sub _perl_script {
    my ($self, $file) = @_;

    # Files with .pl or .psgi extensions are perl scripts
    if ( $file =~ /\.p(?:l|sgi)$/i ) {
        return 1;
    }

    # Files with no extension, but a perl shebang are perl scripts
    if ( $file =~ /(?:^[^.]+$)/ ) {
        my $shebang = $self->_read_shebang($file);
        if ( $shebang =~ m/perl/ ) {
            return 1;
        }
    }
}

# Does this file look like a perl module?
sub _perl_module {
    my ($self, $file) = @_;

    return ( $file =~ /\.pm$/ );
}

1;

=head1 AUTHORS

Sagar R. Shah C<< <srshah@cpan.org> >>,
Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>,
Evan Giles, C<< <egiles@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2023 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Strict> provides functions to ensure your perl files compile, with
the added bonus that it will check you have used strict in all your files.

L<Test::LoadAllModules> just handles modules, not script files, but has more
fine-grained control.

=cut
