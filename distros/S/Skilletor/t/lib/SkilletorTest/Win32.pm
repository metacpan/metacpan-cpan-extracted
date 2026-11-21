package SkilletorTest::Win32;
# ABSTRACT: Drive Skilletor::Process's Windows path on any system

use strict;
use warnings;

use Exporter qw( import );
use POSIX ();

our @EXPORT_OK = qw( win32_os parse_cmdline );

# A command line split as the C runtime's parser (CommandLineToArgvW, VS 2008 and later) splits
# it: whitespace (space, tab) between arguments outside quotes; a quote toggles quoting, two
# inside quotes are one literal quote; 2n backslashes before a quote are n and the quote is
# syntax, 2n+1 are n and a literal quote; other backslashes are literal.
sub parse_cmdline {
  my ( $line ) = @_;
  my ( @args, $cur );
  my $quoted = 0;
  my ( $i, $n ) = ( 0, length $line );
  while ( $i < $n ) {
    my $c = substr $line, $i, 1;
    if ( $c eq '\\' ) {
      my $j = $i;
      $j++ while $j < $n && substr( $line, $j, 1 ) eq '\\';
      my $count = $j - $i;
      $cur //= '';
      if ( $j < $n && substr( $line, $j, 1 ) eq '"' ) {
        $cur .= '\\' x int( $count / 2 );
        if   ( $count % 2 ) { $cur .= '"'; $i = $j + 1 }
        else                { $i = $j }
      }
      else {
        $cur .= '\\' x $count;
        $i = $j;
      }
      next;
    }
    if ( $c eq '"' ) {
      $cur //= '';
      if ( $quoted && substr( $line, $i + 1, 1 ) eq '"' ) { $cur .= '"'; $i += 2; next }
      $quoted = !$quoted;
      $i++;
      next;
    }
    if ( !$quoted && ( $c eq ' ' || $c eq "\t" ) ) {
      push @args, $cur if defined $cur;
      undef $cur;
      $i++;
      next;
    }
    $cur = ( $cur // '' ).$c;
    $i++;
  }
  push @args, $cur if defined $cur;
  return @args;
}

# The primitives of the Windows path, done the POSIX way: spawn forks and execs the program with
# the arguments its quoted command line parses back to – the child inherits fds 0 to 2, the cwd
# and %ENV as they are at the moment of the spawn, as a Windows child would – and detach records
# what it was given. Every call lands in @$calls: [ spawn|detach => $program, $line, \%env ].
sub win32_os {
  my ( $calls ) = @_;
  $calls //= [];
  return {
    calls => $calls,
    spawn => sub {
      my ( $program, @line ) = @_;
      my $line = join ' ', @line;
      push @$calls, [ spawn => $program, $line, {%ENV} ];
      my @argv = parse_cmdline($line);
      my $pid  = fork;
      return ( undef, 0 + $! ) unless defined $pid;
      if ( !$pid ) {
        { no warnings 'exec'; exec {$program} @argv; }
        POSIX::_exit(127);
      }
      return $pid;
    },
    detach => sub {
      my ( $program, $line ) = @_;
      push @$calls, [ detach => $program, $line, {%ENV} ];
      return 1;
    },
  };
}

1;
