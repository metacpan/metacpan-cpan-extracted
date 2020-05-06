#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::3
# For unclear reason, it only works when both lib and blib versions of
# a pod get modified.

use warnings;
use strict;

use blib;
use POSIX  qw/strerror setlocale LC_ALL/;

use IO::Handle ();  # required by some older Perl versions

# please errno in english
warn "LOCALE="
  , setlocale(LC_ALL, 'en_US.utf8')
 || setlocale(LC_ALL, 'POSIX')
 || setlocale(LC_ALL, 'C');
my @pods          = map +($_, "blib/$_"), @ARGV;
my $constindex_fn = 'constindex.txt';

my %tables =
  ( confstr   => 'POSIX::1003::Confstr'
  , errno     =>
      { pkg      => 'POSIX::1003::Errno'
      , more     => sub { strerror($_[0] // 'undef') }
      }
  , fcntl     => 'POSIX::1003::Fcntl'
  , fdio      => 'POSIX::1003::FdIO'
  , fsys_stat =>
      { pkg      => 'POSIX::1003::FS'
      , select   => sub { $_[0] =~ m/^S_I/ }
      }
  , fsys_acc  =>
      { pkg      => 'POSIX::1003::FS'
      , select   => sub { $_[0] =~ m/_OK$|MAX/ }
      }
  , fsys_glob =>
      { pkg      => 'POSIX::1003::FS'
      , select   => sub { $_[0] =~ m/^(?:GLOB|FNM|WRDE)_/ }
      }
  , locale   => 'POSIX::1003::Locale'
  , math     => 'POSIX::1003::Math'
  , os       => 'POSIX::1003::OS'
  , poll     =>
      { pkg      => 'POSIX::1003::Events'
      , select   => sub { $_[0] =~ m/^E?POLL/ }
      }
  , pathconf => 'POSIX::1003::Pathconf'
  , property => 'POSIX::1003::Properties'
  , proc     => 'POSIX::1003::Proc'
  , rlimit   =>
     { pkg       => 'POSIX::1003::Limit'
     , select    => sub { $_[0] =~ m/^RLIM/ }
     }

  , signals    =>
     { pkg       => 'POSIX::1003::Signals'
     , select    => sub { $_[0] !~ m/^SA_|^SIG_/ }
     }
  , sigactions =>
     { pkg       => 'POSIX::1003::Signals'
     , select    => sub { $_[0] =~ m/^SA_/ }
     }
  , sighandlers =>
     { pkg       => 'POSIX::1003::Signals'
     , select    => sub { $_[0] =~ m/^SIG_/ }
     }
  , socket     =>
     { pkg       => 'POSIX::1003::Socket'
     , select    => sub { $_[0] !~ m/^(?:SOL|SO|AF|PF)_/ }
     }
  , socket_sol =>
     { pkg       => 'POSIX::1003::Socket'
     , select    => sub { $_[0] =~ m/^SOL_/ }
     }
  , socket_so  =>
     { pkg       => 'POSIX::1003::Socket'
     , select    => sub { $_[0] =~ m/^SO_/ }
     }
  , socket_af  =>
     { pkg       => 'POSIX::1003::Socket'
     , select    => sub { $_[0] =~ m/^AF_/ }
     }
  , socket_pf  =>
     { pkg       => 'POSIX::1003::Socket'
     , select    => sub { $_[0] =~ m/^PF_/ }
     }

  , sysconf  => 'POSIX::1003::Sysconf'
  , termios  => 'POSIX::1003::Termios'
  , time     => 'POSIX::1003::Time'
  , ulimit   =>
     { pkg       => 'POSIX::1003::Limit'
     , select    => sub { $_[0] !~ m/^RLIM/ }
     }
  );

sub produce_table($$);
sub format_rows($$);

my ($sum_tables, $sum_rows, $sum_undef) = (0, 0, 0);
sub summerize();

our $pod;        # sorry :(

open my $constindex, ">:encoding(utf8)", $constindex_fn
    or die "cannot write $constindex_fn: $!";

my $sys;
if(open $sys, '<:encoding(utf8)', 'system.c')
{   $constindex->print(<$sys>);
}
close $sys;

foreach $pod (sort @pods)
{
    $pod =~ m/\.pod$/ or next;
    $pod =~ m/blib/ or next;

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

        my $line;
        do { $line = <POD> }
        while $line =~ m/^\s*$/;

        print NEW "\n";
        print NEW produce_table($pod, lc $table);
        $changes++;

        print NEW "\n\n=for comment\n$old\n$line";
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

summerize;

close $constindex
    or die "errors at close $constindex_fn: $!";

exit 0;

### HELPERS

sub sorted(@) { sort {lc($a) cmp lc($b)} @_ }

sub produce_table($$)
{   my ($fn, $name) = @_;
    my $config = $tables{$name};
    unless($config)
    {   warn "unknown table $name";
        return;
    }

    ref $config
        or $config = { pkg => $config };

    my $pkg = $config->{pkg};
    eval "require $pkg";
    die "Compilation errors in module $pkg: $@" if $@;

    my $subset = $config->{select} || sub { $_[0] =~ m/^[A-Z0-9_]+$/ }; 
    my $more   = $config->{more}   || sub { undef };

    no strict 'refs';
    my $consts = ${"${pkg}::EXPORT_TAGS"}{constants} || [];

    my @consts = sorted grep $subset->($_), @$consts;
    my @rows;
    foreach my $const (@consts)
    {   my $val = $pkg->exampleValue($const);
        push @rows, +[$const, $val, $more->($val)]
    }

    format_rows $name => \@rows;
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
            if defined $_->[2] && $longest_more < length $_->[2];
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

#   if($pod !~ m/blib/)
    {   my $header = sprintf "table %-13s has %4d constants, %3d are undef\n"
          , $manual, $nr_rows, $nr_undef;
        warn $header;
        print $constindex $header;
        $sum_tables++;
        $sum_rows  += $nr_rows;
        $sum_undef += $nr_undef;
    }

    if(@lines)
    {   my $text = "  ".join("\n  ", @lines)."\n";

        print $constindex ':', join('#', map $_ // '', @$_), "\n"
            for @$rows;

        return $text;
    }

    <<_NONE;
  There were no symbols detected for this category during installation.
  This can mean that the related command is not supported, or that this
  module did not get ported to (your version of) your Operating System.
  In the latter case, please help us making it work.
_NONE
}

sub summerize()
{   warn sprintf "        Σ %2d tables have %4d constants, %3d are undefined\n"
      , $sum_tables, $sum_rows, $sum_undef;
}
