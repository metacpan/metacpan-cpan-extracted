# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::FdIO;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

# Blocks resp from unistd.h, limits.h, and stdio.h
my (@constants, @seek, @mode, @at);
my @functions = qw/closefd creatfd dupfd dup2fd openfd pipefd
  readfd seekfd writefd tellfd truncfd fdopen/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , seek      => \@seek
 , mode      => \@mode
 , at        => \@at
 , tables    => [ qw/%seek %mode %at/ ]
 );

my $fdio;
our (%fdio, %seek, %mode, %at);

BEGIN {
    $fdio = fdio_table;
    push @constants, keys %$fdio;

    # initialize the :seek export tag
    push @seek, grep /^SEEK_/, keys %$fdio;
    my %seek_subset;
    @seek_subset{@seek} = @{$fdio}{@seek};
    tie %seek,  'POSIX::1003::ReadOnlyTable', \%seek_subset;

    # initialize the :mode export tag
    push @mode, grep /^O_/, keys %$fdio;
    my %mode_subset;
    @mode_subset{@mode} = @{$fdio}{@mode};
    tie %mode,  'POSIX::1003::ReadOnlyTable', \%mode_subset;

    # initialize the :at export tag
    push @at, grep /^AT_/, keys %$fdio;
    my %at_subset;
    @at_subset{@at} = @{$fdio}{@at};
    tie %at,  'POSIX::1003::ReadOnlyTable', \%at_subset;
}


sub seekfd($$$)   { goto &POSIX::lseek }
sub openfd($$;$)  { goto &POSIX::open  }
sub closefd($)    { goto &POSIX::close }
sub readfd($$;$)  { push @_, SSIZE_MAX()  if @_==2; goto &POSIX::read  }
sub writefd($$;$) { push @_, length $_[1] if @_==2; goto &POSIX::write }
sub pipefd()      { goto &POSIX::pipe  }
sub dupfd($)      { goto &POSIX::dup   }
sub dup2fd($$)    { goto &POSIX::dup2  }
sub statfd($)     { goto &POSIX::fstat }
sub creatfd($$)   { openfd $_[0], O_WRONLY()|O_CREAT()|O_TRUNC(), $_[1] }


# This is implemented via CORE::open, because we need an Perl FH, not a
# FILE *.

sub fdopen($$)
{   my ($fd, $mode) = @_;
   
    $mode =~ m/^([rwa]\+?|\<|\>|\>>)$/
        or die "illegal fdopen() mode '$mode'\n";

    my $m = $1 eq 'r' ? '<' : $1 eq 'w' ? '>' : $1 eq 'a' ? '>>' : $1;

    die "fdopen() mode '$mode' (both read and write) is not supported\n"
        if substr($m,-1) eq '+';

    open my($fh), "$m&=", $fd;
    $fh;
}


#------------------

sub tellfd($)     {seekfd $_[0], 0, SEEK_CUR() }
sub rewindfd()    {seekfd $_[0], 0, SEEK_SET() }


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fdio->{$name};
    sub() {$val};
}

1;
