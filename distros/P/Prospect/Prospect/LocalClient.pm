=head1 NAME

 Prospect::LocalClient -- execute Prospect locally
 $Id: LocalClient.pm,v 1.30 2003/11/07 18:42:42 cavs Exp $

=head1 SYNOPSIS

 my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
 my $po = new Prospect::Options( seq=>1, svm=>1, global_local=>1,
   templates=>['1alu', '1bgc','1eera']);
 my $pf = new Prospect::LocalClient( {options=>$po );
 
 while ( my $s = $in->next_seq() ) {
   my @threads = $pf->thread( $s );
 }

=head1 DESCRIPTION

B<Prospect::LocalClient> is runs Prospect locally.  It is intended to be
used to facilitate high-throughput protein sequence threading and as the
server-side component of B<Prospect::SoapClient>, with which it is API
compatible.

=head1 ROUTINES & METHODS

=cut


package Prospect::LocalClient;

use base Prospect::Client;

use warnings;
use strict;
use File::Temp qw( tempfile tempdir );
use Carp qw(cluck);
use IO::File;
use Prospect::Exceptions;
use Prospect::utilities;
use Prospect::ThreadSummary;
use Prospect::Init;
use Digest::MD5;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/ );



#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   constructor
 Arguments: hash reference with following key/value pairs
  options => Prospect::Options object (required)
 Returns:   Prospect::LocalClient

=cut


sub new(;%) {
  my $self = shift->SUPER::new(@_);
  $self->_setenv();
  $self->_prepare_options();
  $self->{'xmlCacheName'}  = 'xmlCache';   # name of xml file cache
  $self->{'sortCacheName'} = 'sortCache';  # name of sort file cache
  return $self;
}


#-------------------------------------------------------------------------------
# thread()
#-------------------------------------------------------------------------------

=head2 thread()

 Name:      thread()
 Purpose:   return a list of Thread objects
 Arguments: scalar sequence or Bio::PrimarySeqI-derived object
 Returns:   list of Prospect::Thread objects

=cut

sub thread($$) {
  my ($self,$s) = @_;

  if ( not defined $s or (ref $s and not $s->isa('Bio::PrimarySeqI')) ) { 
    throw Prospect::BadUsage( 
    "Prospect::LocalClient::thread() requires one Bio::PrimarySeqI subclass or " .
    "scalar sequence argument" ); 
  }

  my $seq = ref $s ? $s->seq() : $s;
  my $xfn = $self->_thread_to_file( $seq );
  my $pf = new Prospect::File;
  $pf->open( "<$xfn" ) || throw Prospect::RuntimeError("$xfn: $!\n");

  $self->{'threads'} = [];
  while( my $t = $pf->next_thread() ) {
    push @{$self->{'threads'}}, $t;
  }
  return( @{$self->{'threads'}} );
}


#-------------------------------------------------------------------------------
# thread_summary()
#-------------------------------------------------------------------------------

=head2 thread_summary()

 Name:      thread_summary()
 Purpose:   return a list of ThreadSummary objects
 Arguments: Bio::Seq object
 Returns:   list of rospect2::ThreadSummary objects

=cut

sub thread_summary($$) {
  my ($self,$s) = @_;
  my @summary;

  foreach my $t (  $self->thread($s) ) {
    push @summary, new Prospect::ThreadSummary( $t );
  }
  return( @summary );
}


#-------------------------------------------------------------------------------
# xml()
#-------------------------------------------------------------------------------

=head2 xml()

 Name:      xml()
 Purpose:   return xml string 
 Arguments: Bio::Seq object
 Returns:   string

=cut

sub xml($$) {
  my ($self,$s) = @_;
  my $xfn = $self->_thread_to_file( $s );
  my $in = new IO::File "<$xfn" or throw 
    Prospect::RuntimeError( "can't open $xfn for reading");
  my $xml='';
  while(<$in>){ $xml .= $_; }
  return( $xml );
}


#-------------------------------------------------------------------------------
# DEPRECATED METHODS - will be removed in subsequent releases.
#-------------------------------------------------------------------------------

sub score_summary($$) {
  cluck("This function is deprecated on Oct-23-2003:\n");
  my ($self,$s) = @_;
  my $xfn = $self->thread_to_file( $s );
  return Prospect::utilities::score_summary( $xfn );
}

sub thread_to_file($$) {
  cluck("This function is deprecated on Oct-23-2003:\n");
  return _thread_to_file($_[0],$_[1]);
}


#-------------------------------------------------------------------------------
# INTERNAL METHODS: not intended for use outside this module
#-------------------------------------------------------------------------------

=pod

=head1 INTERNAL METHODS & ROUTINES

The following functions are documented for developers' benefit.  THESE
SHOULD NOT BE CALLED OUTSIDE OF THIS MODULE.  YOU'VE BEEN WARNED.

=cut


#-------------------------------------------------------------------------------
# _get_svm_scores()
#-------------------------------------------------------------------------------

=head2 _get_svm_scores()

 Name:      _get_svm_scores()
 Purpose:   return a hash of svm scores from a prospect sort file
 Arguments: sort filename
 Returns:   hash

=cut

sub _get_svm_scores($$) {
  my ($self,$fn) = @_;
  my %retval;

  my $in = new IO::File $fn || throw Prospect::RuntimeError( "can't open $fn for reading" );
  my @fld;
  while(<$in>) {
    next if m/^:Protein/;
    @fld = split /\s+/;
    $retval{$fld[0]} = $fld[3];
  }
  if ( scalar (keys %retval) == 0 ) {
    throw Prospect::RuntimeError
      ( 'Sort file is empty',
        "The sort file for this sequence is empty.  sortProspect likely failed!",
        "Execute sortProspect on the command-line and check output messages.  sortProspect " .
        "can fail because of erroneous characters in the output xml file (e.g. null character)."
        );
  }
  close($in);
  return %retval;
}


sub _thread_to_file($$)
  {
  my ($self,$s) = @_;
  my $xfn;
  my $seq = ref $s ? $s->seq() : $s;


  # check the cache for a cached file cooresponding to this sequence.
  # if available then return it rather than running prospect
  my $cached = $self->_get_cache_file( Digest::MD5::md5_hex( $seq ), $self->{'xmlCacheName'} );
  if ( defined $cached and -e $cached ) {
    warn("retrieved cache threading info $cached\n") if $ENV{DEBUG};
    return $cached;
  }

  my $ifn = $self->_write_seqfile( $seq );
  $xfn = $self->_thread1( $ifn );
  unlink( $ifn );

  # new version of prospect outputs svm score when threading.  no
  # longer need to run sortProspect in this case.  for backwards
  # compatibility, check the xml file for svmScore tag.  If 
  # not present, then run sortProspect.
  if  ( $self->_hasSvmScore( $xfn ) ) {
    print(STDERR "xml file ($xfn) already contains svm scores - skip sortProspect step\n") if $ENV{DEBUG};
    $self->_put_cache_file( Digest::MD5::md5_hex( $seq ), $self->{'xmlCacheName'}, $xfn );
    return $xfn;
  } else {
    print(STDERR "xml file ($xfn) doesn't contain svm scores - run sortProspect\n") if $ENV{DEBUG};
    # run sortProspect so as to get svm score 
    my $sfn = $self->_sort1( $xfn );

    # insert svm score into the prospect output
    my $ffn = $self->_output_svm_score( $xfn, $sfn );
    unlink( $xfn );
    unlink( $sfn );

    # cache the prospect output filename
    $self->_put_cache_file( Digest::MD5::md5_hex( $seq ), $self->{'xmlCacheName'}, $ffn );
    return $ffn;
  }

=pod

=over

=item B<::_thread_to_file( Bio::Seq | scalar )>

Thread one sequence in the Bio::Seq object or the scalar string.  The xml
ouptut filename is returned.  Threading results are cached by sequence for
the lifetime of the LocalClient object.  See also B<::thread>.

=back

=cut
  }



sub _thread1($$)
  {
  my ($self,$ifn) = @_;
  my $xfn = "$ifn.xml";
  my @cl = @{$self->{commandline}};
  $cl[1] = sprintf($cl[1],$ifn);
  $cl[2] = sprintf($cl[2],$xfn);
  print(STDERR "about to @cl\n") if $ENV{DEBUG};
  if ( eval { system("@cl") } ) {
  my $s = $?;
  if ($s & 127) {
    $s &= 127;
    my $sn = Prospect::utilities::signame($s);
    throw Prospect::RuntimeError
    ( 'failed to execute Prospect',
      "received signal $s ($sn)" );
    }
  $s >>= 8;
  throw Prospect::RuntimeError
    ( 'failed to execute Prospect',
    "system(@cl) exited with status $s",
    'check your prospect installation manually' );
  }
  my $fh = new IO::File;
  $fh->open("<$xfn")
  || throw Prospect::Exception("Prospect failed",
                  "prospect completed but didn't create an output file");
  while(<$fh>) {              # ugh-prospect sometimes barfs
  if (m/<scoreInfo>/) {          # and completes with status 0
    $fh->close(); return $xfn; }      # (e.g., large sequences)
  }
  throw Prospect::Exception("Prospect failed",
               "prospect completed but the output wasn't valid",
               "prospect may fail if the sequence is " 
              ."too large or there's not enough memory.  Try "
              ."running the sequence manually.");
  return undef;
=pod

=over

=item B<::_thread1( filename )>

Threads the fasta-formatted sequence in C<filename> which is passed
directly to prospect.  The name of a temporary file which contains the raw
xml output is returned.  This method will work with multiple sequences in
C<filename>, but other routines in this module will not understand
multi-query xml output reliably.  Most callers should use thread()
instead.

=back

=cut
  }


#-------------------------------------------------------------------------------
# _hasSvmScore()
#-------------------------------------------------------------------------------

=head2 _hasSvmScore()

 Name:      _hasSvmScore()
 Purpose:   check whether the prospect xml file already contains a svmScore tag
 Arguments: prospect xml file
 Returns:   1 (has svm score) or 0 (no svm score)

=cut

sub _hasSvmScore {
  my ($self,$xmlFile) = @_;
  my $in = new IO::File "$xmlFile"  or 
    throw Prospect::RuntimeError("can't open $xmlFile for reading");
  my $retval = 0;
  while(<$in>) {
    if ( m/svmScore/ ) {
      $retval = 1;
      last;
    }
  }
  $in->close();
  return $retval;
}


#-------------------------------------------------------------------------------
# _output_svm_score()
#-------------------------------------------------------------------------------

=head2 _output_svm_score()

 Name:      _output_svm_score()
 Purpose:   output the svm score in the propsect output file
 Arguments: prospect xml file, prospect sort file
 Returns:   prospect xml file with svm score

=cut

sub _output_svm_score {
  my ($self,$xmlFile,$sortFile) = @_;

  my %svm = $self->_get_svm_scores( $sortFile );
 
  my $outFile = "$xmlFile.svm";
  my $in  = new IO::File "$xmlFile"  or throw Prospect::RuntimeError("can't open $xmlFile for reading");
  my $out = new IO::File ">$outFile" or throw Prospect::RuntimeError("can't open $outFile for reading");
 
  local $/ = '</threading>';
  while(<$in>) {
    next if ! m/threading/;  # make sure that we have valid prospect thread
    m#template="(\w+)"#;
    my $t = $1;
    if ( ! defined $svm{$t} or $svm{$t} eq '') {
      throw Prospect::RuntimeError
        ( 'Unable to retrieve svm sort',
          "no svm score for template=$t" );
    }
    s#(<rawScore>.*?</rawScore>)#$1\n<svmScore>$svm{$t}</svmScore>#g;
    print $out $_;
  }
  close($in);
  return( $outFile );
}


#-------------------------------------------------------------------------------
# _sort1()
#-------------------------------------------------------------------------------

=head2 _sort1()

 Name:      _sort1()
 Purpose:   run sortProspect on threading file
 Arguments: prospect xml file
 Returns:   filename of sortProspect results

=cut

sub _sort1($$) {
  my ($self,$xfn) = @_;
  my $sfn = "$xfn.sort";
  my $cmd = "sortProspect $xfn 2>/dev/null 1>$sfn";
  print(STDERR "about to $cmd\n") if $ENV{DEBUG};
  if ( eval { system("$cmd") } )
  {
  my $s = $?;
  if ($s & 127)
    {
    $s &= 127;
    my $sn = Prospect::utilities::signame($s);
    throw Prospect::RuntimeError
    ( 'failed to execute Prospect',
      "received signal $s ($sn)" );
    }
  $s >>= 8;
  throw Prospect::RuntimeError
    ( 'failed to execute Prospect',
    "system($cmd) exited with status $s",
    'check your prospect installation manually' );
  }
  # sanity checks on the sort output??
  return $sfn;
}


sub _setenv {
  if (not -d $Prospect::Init::PROSPECT_PATH ) {
    throw Prospect::Exception
      ( "PROSPECT_PATH is not set correctly",
      "PROSPECT_PATH ($Prospect::Init::PROSPECT_PATH}) is not a valid directory",
      "Check your prospect installation and set PROSPECT_PATH in Prospect::Init or as an environment variable" );
  } else {
    $ENV{'PROSPECT_PATH'} =  $Prospect::Init::PROSPECT_PATH;
  }
  if (not -d $Prospect::Init::PDB_PATH) {
    throw Prospect::Exception
      ( "PDB_PATH is not set correctly",
      "PDB_PATH ($Prospect::Init::PDB_PATH) is not a valid directory",
      "Check your prospect installation and set PDB_PATH in Prospect::Init or as an environment variable" );
  } else {
    $ENV{'PDB_PATH'} =  $Prospect::Init::PDB_PATH;
  }
}


sub _prepare_options($$) {
  my $self = shift;
  my $opts = $self->{options};

  (ref $opts eq 'Prospect::Options')
  || throw Prospect::BadUsage('Prospect::Options argument is missing');

  my @cl = ( "$Prospect::Init::PROSPECT_PATH/bin/prospect" );

  if (exists $opts->{phd}) {
  throw Exception::NotYetSupported
    ( "phd threading isn't implemented" );
  } elsif (exists $opts->{ssp}) {
  throw Exception::NotYetSupported
    ( "ssp threading isn't implemented" ); 
  } elsif (exists $opts->{seq}) {
  push( @cl, '-seqfile %s' );
  } else {
  throw Prospect::BadUsage("Prospect::Options doesn't specify input type");
  }

  push(@cl, '-o %s');
  push(@cl, '-ncpus '.($opts->{ncpus}||2) );
  push(@cl, '-freqfile',$opts->{freqfile} ) if ( exists $opts->{freqfile} );
  push(@cl, '-reliab') if $opts->{zscore};
  push(@cl, $opts->{global_local} ? '-global_local' : '-global');

  # template set selection
  # ONE of -scop, -tfile, -templates (array), or -fssp (default)
  if ($opts->{scop}) {
  push(@cl, '-scop') 
  } elsif (exists $opts->{tfile}) {
  push(@cl, '-tfile', $opts->{tfile}) 
  } elsif (exists $opts->{templates}) {
  my ($fh,$fn) = $self->_tempfile('lst');
  $fh->print(join("\n",@{$opts->{templates}}),"\n");
  $fh->close();
  push(@cl, '-tfile', $fn);
  } else {
  push(@cl, '-fssp');
  }

  push(@cl, '2> /dev/null' ) unless (defined $ENV{DEBUG} and $ENV{DEBUG}>5);
  push(@cl, '1>&2');

  @{$self->{commandline}} = @cl;
  return @cl;
=pod

=over

=item B<::_prepare_options()>

Prepares temporary files based on options (e.g., writes a temporary
`tfile') and generates an array of command line options in
@{$self->{commandline}}.  Args 1 and 2 are input and output respectively
and MUST be sprintf'd before use.  See thread_1_file().

=back

=cut
  }

sub _write_seqfile($$)
  {
  my ($self,$seq) = @_;
  throw Exception ('seq undefined') unless defined $seq;
  my ($fh,$fn) = $self->_tempfile('fa');
  $seq =~ s/\s//g;
  my $len = length($seq);
  $seq =~ s/.{60}/$&\n/g;          # wrap at 60 cols
  $fh->print( ">LocalClient /len=$len\n$seq\n");
  $fh->close();
  return $fn;
  }




=pod

=head1 SEE ALSO

B<Prospect::Options>, B<Prospect::File>,
B<Prospect::Client>, B<Prospect::SoapClient>,
B<Prospect::Thread>, B<Prospect::ThreadSummary>

http://www.bioinformaticssolutions.com/

=cut


1;
