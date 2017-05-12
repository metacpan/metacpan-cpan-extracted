#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::3
# For unclear reason, it only works when both lib and blib versions of
# a pod get modified.

use warnings;
use strict;

use blib;

my @pods   = map +($_, "blib/$_"), @ARGV;

my %tables =
  ( confstr  => [ 'POSIX::1003::Confstr',  \&table_confstr  ]
  , errno    => [ 'POSIX::1003::Errno',    \&table_errno    ]
  , fcntl    => [ 'POSIX::1003::Fcntl',    \&table_fcntl    ]
  , fdio     => [ 'POSIX::1003::FdIO',     \&table_fdio     ]
  , fsys     => [ 'POSIX::1003::FS',       \&table_fsys     ]
  , math     => [ 'POSIX::1003::Math',     \&table_math     ]
  , pathconf => [ 'POSIX::1003::Pathconf', \&table_pathconf ]
  , poll     => [ 'POSIX::1003::Events',   \&table_poll     ]
  , property => [ 'POSIX::1003::Properties', \&table_props  ]
  , rlimit   => [ 'POSIX::1003::Limit',    \&table_rlimit   ]
  , signals  => [ 'POSIX::1003::Signals',  \&table_signals  ]
  , sigactions=>[ 'POSIX::1003::Signals',\&table_sigactions ]
  , sysconf  => [ 'POSIX::1003::Sysconf',  \&table_sysconf  ]
  , termios  => [ 'POSIX::1003::Termios',  \&table_termios  ]
  , ulimit   => [ 'POSIX::1003::Limit',    \&table_ulimit   ]
  );

sub produce_table($$);
sub format_rows($$);

our $pod;   # sorry :(

foreach $pod (sort @pods)
{   $pod =~ m/\.pod$/
        or next;

    open POD, '<', $pod
        or die "cannot read $pod: $!\n";

    my $podtmp = "$pod.tmp";
    open NEW, '>', $podtmp
        or die "cannot write to $podtmp: $!\n";

    my $changes = 0;

    while(my $old = <POD>)
    {   print NEW $old;
        $old =~ m/^\#TABLE_(\w+)_START/
            or next;
        my $table = $1;

        do { $old = <POD> }
        until $old =~ m/^\#TABLE_${table}_END/;

        print NEW "\n";
        print NEW produce_table($pod, lc $table);
        $changes++;

        print NEW "\n\n=for comment\n$old\n\n";
    }

    close NEW or die "write error in $podtmp: $!\n";
    close POD or die "read error in $pod: $!\n";

    if($changes)
    {   unlink $pod;  # Windows' rename() does not work when $dest exists
        rename $podtmp, $pod or die "rename $podtmp $pod: $!";
    }
    else
    {   unlink $podtmp       or die "unlink $podtmp: $!";
    }
}

sub sorted(@) { sort {lc($a) cmp lc($b)} @_ }

sub produce_table($$)
{   my ($fn, $name) = @_;
    my $table = $tables{$name}
        or die "unknown table $name";

    my ($pkg, $handler) = @$table;
    eval "require $pkg";
    die "Compilation errors in module $pkg: $@" if $@;

    $pkg->import(':all');
    $handler->($pkg);
}

sub table_confstr($)
{   my $pkg = shift;
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted confstr_names();
    format_rows confstr => \@rows;
}

sub table_sysconf($)
{   my $pkg = shift;
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted sysconf_names();
    format_rows sysconf => \@rows;
}

sub table_pathconf($)
{   my $pkg = shift;
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted pathconf_names();
    format_rows pathconf => \@rows;
}

sub table_rlimit($)
{   my $pkg = shift;
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted rlimit_names();
    format_rows rlimit => \@rows;
}

sub table_ulimit($)
{   my $pkg = shift;
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted ulimit_names();
    format_rows ulimit => \@rows;
}

sub table_math($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Math::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows math => \@rows;
}

sub table_signals($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Signals::EXPORT_TAGS{signals};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows signals => \@rows;
}

sub table_sigactions($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Signals::EXPORT_TAGS{actions};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows actions => \@rows;
}

sub table_fcntl($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Fcntl::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows fcntl => \@rows;
}

sub table_fdio($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::FdIO::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows fdio => \@rows;
}

sub table_fsys($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::FS::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows fsys => \@rows;
}

sub table_termios($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Termios::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows termios => \@rows;
}

sub table_poll($)
{   my $pkg   = shift;
    my $poll = $POSIX::1003::Events::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted grep /^POLL/, sort @$poll;
    format_rows poll => \@rows;
}

sub table_props($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Properties::EXPORT_TAGS{constants};
    my @rows  = map { [$_, $pkg->exampleValue($_)] }
        sorted @$constants;
    format_rows property => \@rows;
}

sub table_errno($)
{   my $pkg   = shift;
    my $constants = $POSIX::1003::Errno::EXPORT_TAGS{constants};
    my @rows;
    foreach my $err (sorted @$constants)
    {   my $val = $pkg->exampleValue($err);
        my $str = strerror($val // 'undef');
        push @rows, [$err, $val, $str];
    }
    format_rows errno => \@rows;
}

sub format_rows($$)
{   my ($manual, $rows) = @_;

    my $longest_name = 0;
    my $longest_val  = 5;  # at least 'undef'
    my $longest_more = 0;

    my $nr_rows      = @$rows;
    my $nr_undef     = 0;

    for (@$rows)
    {   $longest_name = length $_->[0] if $longest_name < length $_->[0];
        $longest_val  = length $_->[1] if $longest_val  < length $_->[1];
        $longest_more = length $_->[2]
                            if @$_ > 2 && $longest_more < length $_->[2];
    }

    my $longest_row   = 0;
    my @lines;
    foreach (@$rows)
    {   my ($name, $value, $more) = @$_;
        $name   .= ' ' x ($longest_name - length $name);
        my $line = "$name  $value";
        if($longest_more)
        {   $line .= ' ' x ($longest_val - length $value);
            $line .= $more;
        }
        push @lines, $line;
        $longest_row  = length $line if $longest_row < length $line;
        $nr_undef++ if $value eq 'undef';
    }

    if($longest_row < 20)
    {    push @lines, '' while @lines %3;
         my $rows   = @lines / 3;
         my @left   = splice @lines, 0, $rows;
         chomp @left;
         my @middle = splice @lines, 0, $rows;
         chomp @middle;
         my @right = @lines;
         @lines = ();
         push @lines, sprintf "%-20s  %-20s  %s"
           , shift @left, shift @middle, shift @right
                 while @left;
    }
    elsif($longest_row < 30)
    {    push @lines, '' if @lines %2;
         my @left  = splice @lines, 0, @lines/2;
         my @right = @lines;
         @lines = ();
         push @lines, sprintf "%-30s  %s", shift @left, shift @right
             while @left;
    }

    warn sprintf "module %-8s has %3d constants, %2d are undefined\n",
        $manual, $nr_rows, $nr_undef
            if $pod !~ m/blib/;

    if(@lines)
    {   my $text = "  ".join("\n  ", @lines)."\n";
        warn $text if $ENV{AUTOMATED_TESTING};
        return $text;
    }

    <<_NONE;
  There were no symbols detected for this category during installation.
  This can mean that the related command is not supported, or that this
  module did not get ported to (your version of) your Operating System.
  In the latter case, please help us making it work.
_NONE
}
