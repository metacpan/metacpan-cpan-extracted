package Test::Compile::Internal;

use warnings;
use strict;

use version; our $VERSION = qv("v2.2.1");
use File::Spec;
use UNIVERSAL::require;
use Test::Builder;

=head1 NAME

Test::Compile::Internal - Test whether your perl files compile.

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

=item C<all_files_ok(@dirs)>

Checks all the perl files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pm_files(@dirs)> and L</all_pl_files(@dirs)>.

=cut
sub all_files_ok {
    my ($self, @dirs) = @_;

    $self->all_pm_files_ok(@dirs);
    $self->all_pl_files_ok(@dirs);
}


=item C<all_pm_files_ok(@dirs)>

Checks all the perl module files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pm_files(@dirs)>.

=cut
sub all_pm_files_ok {
    my ($self, @dirs) = @_;

    my $test = $self->{test};

    for my $file ( $self->all_pm_files(@dirs) ) {
        my $ok = $self->pm_file_compiles($file);
        $test->ok($ok, "$file compiles");
    }
}


=item C<all_pl_files_ok(@dirs)>

Checks all the perl program files it can find for compilation errors.

If C<@dirs> is defined then it is taken as an array of directories to
be searched for perl files, otherwise it searches some default locations
- see L</all_pl_files(@dirs)>.

=cut
sub all_pl_files_ok {
    my ($self, @dirs) = @_;

    my $test = $self->{test};

    for my $file ( $self->all_pl_files(@dirs) ) {
        my $ok = $self->pl_file_compiles($file);
        $test->ok($ok, "$file compiles");
    }
}


=item C<verbose($verbose)>

An accessor to get/set the verbosity.  The default value (undef) will suppress output
unless the compilation fails.  This is probably what you want.

If C<verbose> is set to true, you'll get the output from 'perl -c'. If it's set to
false, all diagnostic output is supressed.

=cut

sub verbose {
    my ($self, $verbose) = @_;

    if ( @_ eq 2 ) {
        $self->{verbose} = $verbose;
    }

    return $self->{verbose};
}

=item C<all_pm_files(@dirs)>

Returns a list of all the perl module files - that is any files ending in F<.pm>
in C<@dirs> and in directories below. If C<@dirs> is undefined, it
searches F<blib> if F<blib> exists, or else F<lib>.

Skips any files in C<CVS>,  C<.svn>, or C<.git> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.
=cut

sub all_pm_files {
    my ($self, @dirs) = @_;

    @dirs = @dirs ? @dirs : _pm_starting_points();

    my @pm;
    for my $file ( $self->_find_files(@dirs) ) {
        if (-f $file) {
            push @pm, $file if $file =~ /\.pm$/;
        }
    }
    return @pm;
}

=item C<all_pl_files(@dirs)>

Returns a list of all the perl script files - that is, any files in C<@dirs> that
either have a F<.pl> extension, or have no extension and have a perl shebang line.

If C<@dirs> is undefined, it searches F<script> if F<script> exists, or else
F<bin> if F<bin> exists.

Skips any files in C<CVS>,  C<.svn>, or C<.git> directories.

The order of the files returned is machine-dependent. If you want them
sorted, you'll have to sort them yourself.

=cut

sub all_pl_files {
    my ($self, @dirs) = @_;

    @dirs = @dirs ? @dirs : _pl_starting_points();

    my @pl;
    for my $file ( $self->_find_files(@dirs) ) {
        if (defined($file) && -f $file) {
            if ( $file =~ /\.pl$/ ) {
                # Files with a .pl extension are perl scripts
                push @pl, $file;
            }
            elsif ( $file =~ /(?:^[^.]+$)/ ) {
                # Files with no extension, but a perl shebang are perl scripts
                my $shebang = $self->_read_shebang($file);
                if ( $shebang =~ m/perl/ ) {
                    push @pl, $file;
                }
            }
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

=item C<done_testing()>

Declares that you are done testing, no more tests will be run after this point.

=cut
sub done_testing {
    my ($self, @args) = @_;
    $self->{test}->done_testing(@args);
}

=item C<ok($test, $name)>

Your basic test. Pass if C<$test> is true, fail if C<$test> is false. Just
like C<Test::Simple>'s C<ok()>.

=cut
sub ok {
    my ($self, @args) = @_;
    $self->{test}->ok(@args);
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

    my $pid = open my $fh, "-|" // die "$0: fork: $!";
    if ($pid == 0) {
        open STDERR, ">&STDOUT" or die "$0: dup: $!";
        exec $cmd               or die "$0: exec: $!";
    }

    wait();
    my $ok = ($? == 0 ? 1 : 0);
    my $output;
    while (my $line = <$fh>) {
        chomp($line);
        push @$output, $line;
    }
    return ($ok, $output);
}

# Works it's way through the input array (files and/or directories), recursively
# finding files
sub _find_files {
    my ($self, @searchlist) = @_;

    my @output;
    for my $file (@searchlist) {
        if (defined($file) && -f $file) {
            push @output, $file;
        } elsif (defined($file) && -d $file) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;
            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" && $_ ne ".git" } @newfiles;
            for my $newfile (@newfiles) {
                my $filename = File::Spec->catfile($file, $newfile);
                if (-f $filename) {
                    push @output, $filename;
                } else {
                    push @searchlist, File::Spec->catdir($file, $newfile);
                }
            }
        }
    }
    return @output;
}

# Check the syntax of a perl file
sub _perl_file_compiles {
    my ($self, $file) = @_;

    if ( ! -f $file ) {
        $self->{test}->diag("$file could not be found") if $self->verbose();
        return 0;
    }

    my @inc = ('blib/lib', @INC);
    my $taint = $self->_is_in_taint_mode($file);
    my $command = join(" ", ($^X, (map { "-I$_" } @inc), "-c$taint", $file));
    my ($compiles, $output) = $self->_run_command($command);
    if ( $output && (!defined($self->verbose()) || $self->verbose() != 0) ) {
        if ( !$compiles || $self->verbose() ) {
            for my $line ( @$output ) {
                $self->{test}->diag($line);
            }
        }
    }

    return $compiles;
}

# Where do we expect to find perl modules?
sub _pm_starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

# Where do we expect to find perl programs?
sub _pl_starting_points {
    return 'script' if -e 'script';
    return 'bin'    if -e 'bin';
}

# Extract the shebang line from a perl program
sub _read_shebang {
    my ($self, $file) = @_;

    open(my $f, "<", $file) or die "could not open $file";
    my $line = <$f>;
    if (defined $line && $line =~ m/^#!/ ) {
        return $line;
    }
}

# Should the given file be checked with taint mode on?
sub _is_in_taint_mode {
    my ($self, $file) = @_;

    my $shebang = $self->_read_shebang($file);
    my $taint = "";
    if ($shebang =~ /^#!\s*[\/\w]+\s+-\w*([tT])/) {
        $taint = $1;
    }
    return $taint;
}

1;

=head1 AUTHORS

Sagar R. Shah C<< <srshah@cpan.org> >>,
Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>,
Evan Giles, C<< <egiles@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2019 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Strict> provides functions to ensure your perl files compile, with
the added bonus that it will check you have used strict in all your files.

=cut
