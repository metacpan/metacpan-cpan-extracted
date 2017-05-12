package Test::C2FIT;

#use 5.008006;
use Test::C2FIT::FileRunner;
use Test::C2FIT::WikiRunner;
use Exporter();
use Getopt::Std;
@ISA    = qw(Exporter);
@EXPORT = qw(file_runner wiki_runner fit_shell);
use strict;
use warnings;

our $VERSION = '0.08';

sub file_runner {
    my $param = {};
    die "unsupported param!" unless getopt( "L:", $param );
    local $SIG{'__WARN__'} = _commonLogging( $param->{L} );

    unshift( @INC, '.' ) unless grep { /^\.$/ } @INC;
    Test::C2FIT::FileRunner->new()->run(@ARGV);
}

sub wiki_runner {
    my $param = {};
    die "unsupported param!" unless getopt( "L:", $param );
    local $SIG{'__WARN__'} = _commonLogging( $param->{L} );

    unshift( @INC, '.' ) unless grep { /^\.$/ } @INC;
    Test::C2FIT::WikiRunner->new()->run(@ARGV);
}

sub fit_shell {
    my $shell = Test::C2FIT::_Shell->new();
    $shell->init;
    $shell->runShell(*STDIN);
}

sub _commonLogging {
    my $loglevel = shift;
    $loglevel = 3 unless defined($loglevel);

    return sub {
        local ( $_, $&, $1 );

        if ( defined( $_[0] ) && $_[0] =~ /^(\d+)/ ) {
            return unless $1 >= $loglevel;
        }

# my ($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time);
# $mon++;
# $year = $year + 1900;
# print STDERR sprintf("%02d.%02d.%04d %02d:%02d:%02d ",$mday,$mon,$year,$hour,$min,$sec);
        print STDERR @_;
    };
}

#
#   (help-) Package implementing an interactive shell
#
{

    package Test::C2FIT::_Shell;
    use Config;
    use strict;
    use warnings;

    sub new {
        my $pkg  = shift;
        my $self = {
            lastCmd    => undef,
            perlBinary => $Config{perlpath},
            options    => {
                input     => ".",
                output    => ".",
                inc       => ".",
                perl_opt  => undef,
                log_level => undef,
                runner    => 'file_runner',
                verbose   => 0,
            },
            cmdDispatch => {
                help   => \&Test::C2FIT::_Shell::help,
                show   => \&Test::C2FIT::_Shell::show,
                set    => \&Test::C2FIT::_Shell::set,
                run    => \&Test::C2FIT::_Shell::run,
                runall => \&Test::C2FIT::_Shell::runall,
                nop    => sub { 1 },
                quit   => sub { undef },
            },
            parseRunDispatch => {
                rerun  => \&Test::C2FIT::_Shell::rerun,
                infile => \&Test::C2FIT::_Shell::runInfile,
                files  => \&Test::C2FIT::_Shell::runFiles,
                inout  => \&Test::C2FIT::_Shell::runInOut,
            }
        };
        return bless $self, $pkg;
    }

    sub init {
        my $self = shift;

        #
        #   check if input/output/lib exists
        #
        my $v = {};

        $v->{input}  = "input"  if ( -d "./input" );
        $v->{output} = "output" if ( -d "./output" );
        $v->{inc}    = "lib"    if ( -d "./lib" );

        if ( scalar(%$v) ) {
            while ( my ( $ik, $iv ) = each(%$v) ) {
                $self->{options}->{$ik} = $iv;
            }
            $self->msg(
                "INFO: input/ouptut/lib diretories found, using them!\n");
            $self->show;
        }
    }

    sub help {
        print <<'_EOH_'; return 1;
# Supported commands:
# help      - show this help
# show      - show variables
# set <variable> <value> - set operational variables
#   input                - directory where html files are searched
#   output               - directory where result html will be written
#   inc                  - INC path. This will be added to the perl-process
#                          upon creation (perl -Ip1 -Ip2 etc.)
#                          multiple Entries should be separated either by
#                          colon (:) or by semicolon, e.g. lib:.:../test
#                          if @ is given, then then contents of @INC of the
#                          fit_shell-process will be set
#   perl_opt             - optional perl-parameters to the perl process.
#                          e.g. -d for debugging
#   log_level            - will be passed to the runner
#   runner               - either file_runner or wiki_runner
#   verbose              - either 0 or 1. When 1, then the command actually
#                          run will be printed too
# run      - run a document. There are different ways to specify it:
#   run BinaryChop       - runs a file named $input/BinaryChop.html
#                          output goes to $output/BinaryChop.html
#   run BinaryChop out   - runs a file named $input/BinaryChop 
#                          (without extension!!!)
#                          output goes to $output/out (without extension!)
#
#   run                  - rerun last run command
#
#   run *.htm*           - run all files $input/*.htm*
#                          (same as runall)
#   run a*.html b*.html  - run all files $input/a*.html $input/b*.html
#                          (Difference to the other two-Param run-call: 
#                           here, wildcards are used)
#   runall               - same as run *.htm*
#
#   quit                 - terminate this shell
#   
#   For each run, a new perl process is started.
#
#   There are some shortcuts/aliases too:
#
#   !                   is an alias for "run"
#   [EMPTY LINE]        (i.e. just pressing the enter key) rerun last run
#
#   Lines starting with # will be ignored
#
#   All output of the fit_shell starts with "#", so you can easily eliminate
#   it (e.g. grep -v "^#")
#
_EOH_
    }

    sub msg {
        my $self = shift;
        print "# ", @_;
        1;
    }

    sub show {
        my $self = shift;
        my @k    = sort keys %{ $self->{options} };

        for my $k (@k) {
            my $v = $self->{options}->{$k};
            $v = "<not defined>" unless defined($v);
            print sprintf( "# %10s: %s\n", $k, $v );
        }
        1;
    }

    sub set {
        my ( $self, $rest ) = @_;
        return $self->msg("WARN: wrong syntax for set!\n")
          unless $rest =~ /(\S+)(?:\s+(\S.*))?$/;

        my $key = $1;
        my $val = $2;

        return $self->msg("WARN: invalid variable $key!\n")
          unless exists $self->{options}->{$key};

        if ( $key eq "inc" && $val eq "@" ) {
            $val = join( ":", @INC );
        }

        $self->{options}->{$key} = $val;
        $self->{lastCmd} = undef;
        1;
    }

    sub runall {
        my $self = shift;
        $self->run("*.htm*");
    }

    sub run {
        my ( $self, $rest ) = @_;
        my $dispatch = $self->{parseRunDispatch};

        my ( $key, @vals ) = $self->parseRunCmd($rest);
        die "internal error. unknown state: $key\n"
          unless exists $dispatch->{$key};

        my $code = $dispatch->{$key};
        return $code->( $self, @vals );
    }

    sub rerun {
        my $self = shift;
        return $self->msg("WARN: no cmd to rerun!\n")
          unless defined( $self->{lastCmd} );
        return $self->_run( $self->{lastCmd} );
    }

    #
    #   runInOut($in,$out) - both filenames with path and suffix
    #
    sub runInOut {
        my ( $self, $in, $out ) = @_;

        return $self->msg("WARN: in and out identical: $in Will be ignored!\n'")
          if $in eq $out;

        my $cmd = $self->_buildCmd;
        $cmd .= " $in $out";
        return $self->_run($cmd);
    }

    #
    #   runInfile (path+filename) * optionally without the .html suffix
    #
    sub runInfile {
        my ( $self, $in ) = @_;
        my $input  = quotemeta( $self->{options}->{input} );
        my $output = $self->{options}->{output};

        $in .= ".html" unless $in =~ /\.html$/i;
        my $out = $in;
        $out =~ s/^$input/$output/;

        return $self->runInOut( $in, $out );
    }

    #
    #   runFiles(@files) - list of input file names with path and extension
    #
    sub runFiles {
        my ( $self, @files ) = @_;
        for my $f (@files) {
            $self->runInfile($f);
        }
        1;
    }

    sub _run {
        my ( $self, $cmd ) = @_;
        die "no cmd given!" unless defined($cmd);
        $self->{lastCmd} = $cmd;
        $self->msg("# CMD:$cmd\n") if $self->{options}->{verbose};
        system($cmd);
        1;
    }

    sub _buildCmd {    # setup the command up to ARGV
        my $self    = shift;
        my $cmd     = $self->{perlBinary};
        my $options = $self->{options};

        $cmd .= " " . $options->{perl_opt} . " "
          if defined( $options->{perl_opt} );

        if ( defined( $options->{inc} ) ) {
            my @inc = split( /[:;]/, $options->{inc} );
            my $inc = " -I" . join( " -I", @inc );
            $cmd .= $inc;
        }

        $cmd .= " -MTest::C2FIT -e " . $options->{runner} . " -- ";

        my $logLevel = $options->{log_level};
        $cmd .= " -L $logLevel " if defined($logLevel);

        return $cmd;
    }

    sub parseRunCmd {
        my ( $self, $rest ) = @_;
        my $input        = $self->{options}->{input};
        my $output       = $self->{options}->{output};
        my $hasWildcards = 0;
        my @files        = ();

        return ("rerun") unless defined($rest);

        my @items = map { /\*/ && $hasWildcards++; $_ } split /\s+/, $rest;

        if ($hasWildcards) {
            for my $item (@items) {
                push( @files, glob("$input/$item") );
            }
            return ( "files", @files );
        }
        if ( 2 == @items ) {
            return ( "inout", "$input/$items[0]", "$output/$items[1]" );
        }
        return ( "infile", "$input/$items[0]" );
    }

    sub runShell {    # main loop of fit_shell
        my ( $self, $inFH ) = @_;
        my $line;
        my $dispatch = $self->{cmdDispatch};
        my $prompt   = ( -t "$inFH" ) ? "fit> " : "";

        $| = 1;

        print $prompt;
        while ( $line = <$inFH> ) {
            $line =~ s/(\012\015?|\015\012?)$//;
            my ( $cmd, $rest ) = $self->parseCmd($line);

            die "internal error. Unknown command/state: $cmd\n"
              unless exists $dispatch->{$cmd};

            my $code = $dispatch->{$cmd};
            my $rv = $code->( $self, $rest );
            last unless $rv;
            print $prompt;
        }
    }

    sub parseCmd {
        my ( $self, $line ) = @_;

        return ( "run", undef ) if !defined($line) || $line eq "";
        return ("nop") if $line =~ /^\s*#/;

        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ( $line =~ /^!\s*(\S.*)?$/ ) {    # ! is alias for "run"
            return ( "run", $1 );
        }
        if ( $line =~ /^(\w+)\b\s*(\S.*)?$/ ) {
            return ( $1, $2 );
        }
        return ("nop");
    }

    1;
};

1;

__END__

=head1 NAME

Test::C2FIT - A direct Perl port of Ward Cunningham's FIT 
acceptance test framework for Java.

=head1 VERSION

This document describes Test::C2FIT version 0.06

=head1 SYNOPSIS

	FileRunner.pl input_containing_fit_tests.html test_results.html

	perl -MTest::C2FIT -e file_runner input_containing_fit_tests.html test_results.html

	perl -MTest::C2FIT -e fit_shell

=head1 DESCRIPTION

Great software requires collaboration and communication. Fit is a tool for
enhancing collaboration in software development. It's an invaluable way
to collaborate on complicated problems - and get them right - early
in development.

Fit allows customers, testers, and programmers to learn what their 
software should do and what it does do. It automatically compares
customers' expectations to actual results.

This port of FIT has a featureset equivalent to v1.1 of FIT.  
Dave W. Smith's original port was based on fit-b021021j and I've updated 
most of the core to match the 1.1 version.

This port passes the current FIT spec and also implements a all of the
examples.


The following functions are provided (and exported) by this module:

=over 4

=item B<file_runner($infile,$outfile)>

Process a FIT-document contained in $infile and writes the result to $outfile.

=item B<wiki_runer($infile,$outfile)>

Same as file_runner, except that not E<lt>tableE<gt>, E<lt>trE<gt> and E<lt>tdE<gt>
but E<lt>wikiE<gt>, E<lt>tableE<gt>, E<lt>trE<gt> and E<lt>tdE<gt> is searched for in the input
document.

=item B<fit_shell>

Creates an interactive shell from which you can easily run tests. Start it
and enter "help" for more information.

Suppose, your tests-related files reside in a directory with three subdirectories:
input - where the files come from, output - where the results will be written to and
lib - where your fixtures reside, all you need to do is just to enter "runall"

=back


=head2 Logging

The file_runner and wiki_runner support filtering of warn messages, similar to
java's common logging. To change the log level, use the -L parameter, e.g.:

	perl -MTest::C2FIT -e file_runner -- -L 1 input_containing_fit_tests.html test_results.html

There are following log levels defined: 0 - trace, 1 - debug, 2 - info, 3 - warn,
4 - error, 5 - fatal.

In your code, simply use C<warn "message"> if it should be printed out unconditionally or
C<warn 1, " message"> if it should be printed out, when log level is either TRACE or DEBUG.


=head2 Naming, Namespace(s)

In your FIT-documents, please use the java-style dot-notation for qualifying package names. E.g.
if you want the package Domain::Object::Simple to be used, specify it by entering 
Domain.Object.Simple into your fit document.


Package names should be fully qualified, case is importat.
Special care is taken on the fit.* packages, these can be specified either by fit.Name as
well as Test.C2FIT.Name.


=head1 GOTCHAS AND LIMITATIONS

1) Java is a strongly typed language; Perl is not. The Java version of FIT
cares a lot about types, but Perl takes a more relaxed view of things and
this port reflects that.

2) Perl supports limited introspection. Because there are no method signatures,
it isn't possible to determine method return types. If you want to use
TypeAdapters you have to supply hints. (see examples)

3) Some of the tests from the 'examples' directory expect Java behaviour for
arithmetic (e.g. integer overflow).  Perl doesn't have this type of overflow
so these tests will "fail".

4) The MusicExample uses a clock that doesn't have millisecond accuracy. This
throws off the clock by a second during one of the tests.

5) Perl supports a limited set of primitive types. Dave has used a
GenericTypeAdapter that knows about strings and numbers (and pretends
to know about booleans).


=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/

The 'examples' directory of this distribution contains some sample FIT
tests and sample applications that they test.  Invoke FileRunner.pl on
any of the test input files from examples/input and view the output in
a browser. To invoke the tests use do_tests.bat / do_tests.sh in
the appropriate directory.

The directory examples-perl contains examples written for this perl-port
only.

You should also examine and run the tests in the 'spec' directory.
These are FIT's own acceptance tests.

=head1 AUTHOR

Original port from the Java version by Dave W. Smith.

Updates and modifications by Tony Byrne E<lt>fit4perl@byrnehq.comE<gt>.
Further modifications by Martin Busik E<lt>martin.busik@busik.deE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2006 Cunningham & Cunningham, Inc.
Released under the terms of the GNU General Public License version 2 or later.


=cut
