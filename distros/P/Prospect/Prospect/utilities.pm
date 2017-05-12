=head1 NAME

Prospect::utilities -- miscellaneous utilities for Prospect
S<$Id: utilities.pm,v 1.9 2003/11/04 01:01:33 cavs Exp $>

=head1 SYNOPSIS

 use Prospect::utilities ;
 my ($scores,@fields) = score_summary( fn );

=head1 DESCRIPTION

B<Prospect::utilities> is a

=head1 ROUTINES & METHODS

=cut


package Prospect::utilities;
use strict;
use warnings;
use Exporter;
our @EXPORT = ();
our @EXPORT_OK = qw( score_summary alignment_summary );
use Prospect::File;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/ );



sub alignment_summary
  {
  my $xfn = shift;							# Prospect xml output
  my $pf = new Prospect::File;
  my @aifields = qw(nident nalign nmatched alignFreq templateFrom 
                  templateTo targetFrom);
  my %sum;
  $pf->open( "<$xfn" )
	or throw Exception ( "couldn't open $xfn" );
  while( my $t = $pf->next_thread() )
	{
	my $tn = $t->tname();
	push( @{$sum{$tn}}, @{$t->{alignmentInfo}}{@aifields} );
	push( @{$sum{$tn}}, $t->{scoreInfo}->{radiusOfGyration} );
	}
  return( \%sum, (@aifields,'rgyr') );
  }




sub score_summary
  {
  my $xfn = shift;							# Prospect xml output
  my $ps = new IO::Pipe;
  my @fields;
  my %scores;
  $ps->reader('sortProspect',$xfn);
  while( my $line = <$ps> )
	{
	my @F = split(' ',$line);
	my $t = shift(@F);
	if ($line =~ m/^:/)
	  { @fields = @F }
	else
	  { @{$scores{$t}} = map { $_ eq '--' or $_ eq '-999.00' ? undef : $_ } @F }
	}
  $ps->close();
  return (\%scores, @fields);
=pod

=over

=item B<score_summary( filename )>

Returns ($score_hashref, @fields) for the given filename.  It is presumed
that filename is the xml output of ONE prospect invocation (i.e., ONE
query sequence).

=back

=cut
  }


sub summary
  {
  my $xfn = shift;							# Prospect xml output
  print(STDERR `date`, "# score_summary on $xfn...\n") if $ENV{DEBUG};
  my ($Sh,@Sf) = score_summary($xfn);
  print(STDERR `date`, "# alignment_summary...\n") if $ENV{DEBUG};
  my ($Ah,@Af) = alignment_summary($xfn);
  print(STDERR `date`, "# done\n") if $ENV{DEBUG};
  push( @{$Sh->{$_}}, @{$Ah->{$_}} ) for keys %$Sh;
  push( @Sf, @Af );
  return ($Sh, @Sf);
=pod

=over

=item B<summary( filename )>

Returns ($hashref, @fields) for the given filename.  It is presumed
that filename is the xml output of ONE prospect invocation (i.e., ONE
query sequence).

=back

=cut
  }



my @signame;
sub signame
  {
  my $n = shift;
  if (not @signame)
	{
	use Config;
	if (defined $Config{sig_name})
	  { @signame = split(' ',$Config{sig_name}); }
	}
  defined $signame[$n] ? 'SIG'.$signame[$n] : 'unknown';
  }



=pod

=head1 BUGS

=head1 SEE ALSO

=cut

1;
