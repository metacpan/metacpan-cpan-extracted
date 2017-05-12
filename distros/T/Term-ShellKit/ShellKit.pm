#!/usr/bin/perl

# my $self_running = ( ! caller );
# END {  Term::ShellKit::shell if ( $self_running  ); }

######################################################################

package Term::ShellKit;

$VERSION = 1.002;
@EXPORT = qw( shell );
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

use strict;
use Carp;
use Text::ParseWords;

######################################################################

use vars qw( $Prompt $SubReadLine );

$SubReadLine = ( -t STDIN ) ? \&readline_term : \&readline_raw;
$Prompt ||= 'Term::ShellKit> ';

sub readline_raw {
  my $prompt = scalar(@_) ? shift : $Prompt;
  print($prompt); 
  $_ = <>; 
  chomp if defined $_; 
  print($_."\n"); 
  $_ 
}

my $TermReadLine;

sub readline_term {
  if ( ! $TermReadLine ) {
    require Term::ReadLine;
    $TermReadLine = Term::ReadLine->new('Term-ShellKit');
    
    # $ShellReadLine->OUT is autoflushed anyway
    my $odef = select STDERR;
    $| = 1;
    select STDOUT;
    $| = 1;
    select $odef;
  }
  my $prompt = scalar(@_) ? shift : $Prompt;
  $TermReadLine->readline( $prompt )
}

######################################################################

use vars qw( $SubDoCommand $CurrentPackage @CommandPackages );

$SubDoCommand = \&do_command;
$CurrentPackage ||= 'main';

use vars qw( @CommandQueue );

sub do_command {
  my $input = shift;

  length $input or return;
  
  $input =~ /\A\s*(\S+)(?:\s(?![\)])(.*))?\Z/ 
    or die "Can't parse command line '$input'\n";
  
  my ($command, $args) = ( $1, $2 );
  
  my $sub;
  if ( $command =~ /^(.*)::([^:]+)$/ ) {
    my ($pack, $func) = ($1, $2);
    $sub = UNIVERSAL::can($pack, $func);
  } else {
    foreach my $package ( $CurrentPackage, @CommandPackages ) {
      if ( $sub = UNIVERSAL::can($package, $command) ) {
	last;
      }
    }
  }
  if ( ! $sub ) {
    foreach my $package ( @CommandPackages ) {
      my $rewriter = UNIVERSAL::can($package, '_shell_rewrite') or next;
      my @out = &$rewriter( $input );
      if ( scalar @out ) {
	unshift @CommandQueue, @out;
	return;
      }
    }
    die "Can't find command or function named '$command'\n";
  }
  
  my $ptype = prototype( $sub );
  my @args;
  if ( ! defined $ptype or $ptype eq '@' ) {
    eval { @args = Text::ParseWords::shellwords($args) };
    croak("Can't parse arguments for $command($ptype): $@") if $@;
  } elsif ( $ptype eq ';$' ) {
    @args = defined($args) ? $args : ();
  } elsif ( $ptype eq '$' ) {
    croak("Missing required argument for $command($ptype)") unless (length $args);
    @args = $args;
  } else {
    eval { @args = Text::ParseWords::shellwords($args) };
    croak("Can't parse arguments for $command($ptype): $@") if $@;
  }
  &$sub( @args );
}

sub command_rewrite {
  unshift @CommandQueue, @_;
  die "Term::ShellKit command completed";
}

######################################################################

use vars qw( $PrintResultsSub );
$PrintResultsSub = \&print_results;

# require Dumpvalue;
# $Dumper = Dumpvalue->new();
# print $Dumper->dumpValue($value);
sub print_results {
  print join '', map { /\n\Z/m ? $_ : "$_\n" } grep { length $_ } @_;
}

######################################################################

use vars qw( @DefaultStartup );
@DefaultStartup = ( 
  'Term::ShellKit::require_package Term::ShellKit::Commands',
  'Term::ShellKit::Commands::echo Term::ShellKit: Starting interactive shell; commands include help, exit.',
  'Term::ShellKit::load_kit Commands', 
  @ARGV,
);

sub shell {
  local $Prompt = $Prompt;
  local @CommandQueue = scalar(@_) ? @_ : @DefaultStartup;
  
  while ( 1 ) {    
    if ( ! scalar @CommandQueue ) {
      my $get_cmd = $SubReadLine or confess "No \$SubReadLine";
      @CommandQueue = &$get_cmd();
    }
    
    my $cmd = shift @CommandQueue;
    ( defined $cmd ) or last;
    
    my @results = eval { &$SubDoCommand( $cmd ) };
    if ( $@ ) {
      if ( $@ =~ /Term::ShellKit command completed/ ) {
	next;
      } else {
	warn "Exception: $@";
      }
    }
    &$PrintResultsSub( @results );
  }
}

######################################################################

sub require_package {
  my $package = shift;
  $package =~ s/;\s*$//;
  
  (my $file = $package . '.pm' ) =~ s|::|/|go;
  return $package if ( $::INC{ $file } );
  
  eval { 
    local $SIG{__DIE__} = '';
    require $file;
  };
  
  if ( $@ ) { 
    die "Unable to dynamically load $package: $@" 
  }
  
  return
}

sub load_kit {
  my $package = shift;
  $package =~ s/;\s*$//;
  
  $package = "Term::ShellKit::$package" unless $package =~ /::/;
  
  require_package($package);
  $package->import if ( $package->can('import') );
  
  push @CommandPackages, $package;
  "Activating $package";
}

######################################################################

package main;
Term::ShellKit::shell unless caller;

######################################################################

1;

__END__

######################################################################

=head1 NAME

Term::ShellKit - Reusable command-line Perl environment

=head1 SYNOPSIS

  > perl -MTerm::ShellKit -eshell
  Term::ShellKit: Starting interactive shell
  
  Term::ShellKit> eval join ', ', 1 .. 10 
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  
  Term::ShellKit> alias incr eval $i += 1
  Term::ShellKit> incr
  1
  Term::ShellKit> incr
  2
  
  Term::ShellKit> help
  NAME
      Term::ShellKit - Generic Perl command-line environment
  ...
  
  Term::ShellKit> exit

=head1 DESCRIPTION

Term::ShellKit provides a Perl-oriented interactive command-line interpretation framework.


=head1 COMMANDS

Commands can start with a function name defined in one of the Command Packages, or with a fully-qualified Package::function name.

That function is checked for a prototype which will control how the rest of the line is processed. By default, space-separated words and quoted phrases are split and used as arguments to the function.

A number of pre-defined functions in Term::ShellKit::Commands are available by default, and you can load additional command packages with the kit function it provides.


=head1 SEE ALSO

See L<Term::ShellKit::ReadMe> for distribution information

See L<Term::ShellKit::Commands> for information on the default commands supported.

SeeL<Term::ShellKit::Dev>, L<Term::ShellKit::File>, and L<Term::ShellKit::DBI> for additiional loadable commands.

=cut
