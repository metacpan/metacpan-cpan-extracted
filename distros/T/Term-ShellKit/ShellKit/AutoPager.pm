package Term::ShellKit::AutoPager;

# based on IO::WrapTie.pm 

require 5.004;
use Carp;

use IO::Handle;
@ISA = qw(IO::Handle);

use vars qw( $PageHandle $PagerProgram $Buffer );

$PagerProgram = '/usr/bin/more';
$Buffer = '';

######################################################################

sub import {
  tie( *STDOUT, 'Term::ShellKit::AutoPager', \*STDOUT );
  $Term::ShellKit::PrintResultsSub = \&print_results;
}

sub unimport {
  untie( *STDOUT );
}

sub print_results {
  $PageHandle->PRINT( join '', map { /\n\Z/m ? $_ : "$_\n" } grep { length $_ } @_ );
  $PageHandle->FLUSH;
}

######################################################################

sub TIEHANDLE {
  my $class = shift;
  my $stdout = shift or confess;
  my $filenum = $$stdout->fileno 
 	or croak "Invalid LogFile target: $stdout\n";
  open(SAVEOUT, ">&$filenum") or warn "Unable to clone STDOUT: $!\n";
  $PageHandle = bless [ $stdout ], $class;
}

sub PRINT {
  my $self = shift;
  
  $Buffer .= join($, , @_) . $\;
}

sub FLUSH {
  my $self = shift;
  if ( -t STDIN and length($Buffer) > 200 or $Buffer =~ /(.*?\n){10,}/ ) {
    open FH, "|$PagerProgram"; 
    print FH $Buffer; 
    close FH;
  } else {
    SAVEOUT->print( $Buffer );
  }
  $Buffer = '';
}

######################################################################

1;

__END__

######################################################################

=head1 NAME

Term::ShellKit::AutoPager - Paging for STDOUT

=head1 SYNOPSIS

  > perl -MTerm::ShellKit -eshell
  Term::ShellKit: Starting interactive shell

  Term::ShellKit> kit AutoPager
  Activating Term::ShellKit::AutoPager
  
  Term::ShellKit> help
  NAME
      Term::ShellKit::Commands - Basic shell functions
  
  SYNOPSIS
	> perl -MTerm::ShellKit -eshell
  [more]
	Term::ShellKit: Starting interactive shell
    
	Term::ShellKit> eval join ', ', 1 .. 10 
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  [more]

=head1 DESCRIPTION

Loading this module causes Term::ShellKit to buffer printed output, and to run any lengthy results through C<more> or your preferred pager program.

=head1 SEE ALSO

L<Term::ShellKit>

=cut
