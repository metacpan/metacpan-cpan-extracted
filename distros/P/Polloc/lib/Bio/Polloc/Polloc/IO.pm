=head1 NAME

Bio::Polloc::Polloc::IO - I/O interface for the Bio::Polloc::* packages

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Polloc::IO;
use base qw(Bio::Polloc::Polloc::Root);
use strict;
use File::Path;
use File::Spec;
use File::Temp;
use Symbol;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 GLOBALS

Global variables controling the behavior of the package

=cut

our($PATHSEP, $TEMPDIR, $ROOTDIR, $IOTRIALS);

=head2 PATHSEP

The system's path separator

=cut

unless (defined $PATHSEP){
   if($^O =~ m/mswin/i){
      $PATHSEP = "\\";
   }elsif($^O =~ m/macos/i){
      $PATHSEP = ":";
   }else{
     $PATHSEP = "/";
   }
}

=head2 TEMPDIR

The system's temporal directory

=cut

$TEMPDIR =File::Spec->tmpdir() unless defined $TEMPDIR;
sub TEMPDIR { shift if ref $_[0] || $_[0] =~ m/^Bio::Polloc::/ ; $TEMPDIR = shift }


=head2 ROOTDIR

The system's root directory

=cut

$ROOTDIR = File::Spec->rootdir() unless defined $ROOTDIR;


=head2 IOTRIALS

Number of trials before giving up (for network retrieve)

=cut

$IOTRIALS = 5 unless defined $IOTRIALS;



=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=head3 Arguments

All the parameters are optional:

=over

=item -input

The input resource

=item -file

The file to read/write

=item -fh

The GLOB file handle

=item -flush

Should I flush on every write

=item -url

The URL to read

=back

=head3 Returns

A L<Bio::Polloc::Polloc::IO> object

=cut

sub new {
   my($caller, @args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize_io(@args);
   return $self;
}

=head2 file

=cut

sub file {
   my($self,$value) = @_;
   $self->{'_file'} = $value if defined $value;
   return $self->{'_file'};
}

=head2 resource

=cut

sub resource {
   my ($self,@args) = @_;
   return $self->file if $self->file;
   return $self->_fh if $self->_fh;
   return "";
}

=head2 mode

=cut

sub mode {
   my($self,@args) = @_;
   return $self->{'_mode'} if defined $self->{'_mode'};
   my $fh = $self->_fh or return '?';
   
   no warnings "io";
   my $line = <$fh>;
   if ( defined $line ){
      $self->_pushback($line);
      $self->{'_mode'} = 'r';
   }else{
      $self->{'_mode'} = 'w';
   }
   return $self->{'_mode'};
}

=head2 close

=cut

sub close {
   my $self = shift;
   if(defined $self->{'_filehandle'}){
      $self->flush;
      return if \*STDOUT == $self->_fh ||
      		\*STDIN  == $self->_fh ||
		\*STDERR == $self->_fh;
      if( ! ref($self->{'_filehandle'}) ||
          ! ! $self->{'_filehandle'}->isa('IO::String') ) {
	 close($self->{'_filehandle'});
      }
   }
   $self->{'_filehandle'} = undef;
   delete $self->{'_readbuffer'};
}

=head2 flush

=cut

sub flush {
   my $self = shift;
   $self->throw("Attempting to call flush but no filehandle active")
   	if !defined $self->{'_filehandle'};
   if(ref($self->{'_filehandle'}) =~ /GLOB/){
      my $oldh = select $self->{'_filehandle'};
      $| = 1;
      select $oldh;
   }else{
      $self->{'_filehandle'}->flush;
   }
}

=head2 exists_exe

=cut

sub exists_exe {
   my($self,$exe) = @_;
   $exe = $self if(!(ref($self) || $exe));
   $exe .= '.exe' if(($^O =~ /mswin/i) && ($exe !~ /\.(exe|com|bat|cmd)$/i));
   return $exe if(-e $exe);
   for my $dir ( File::Spec->path ){
      my $f = Bio::Polloc::Polloc::IO->catfile($dir, $exe);
      return $f if -e $f && -x $f;
   }
   return 0;
}

=head2 tempfile

=cut

sub tempfile {
   my($self,@args) = @_;
   my($tfh, $file);
   my($dir, $unlink, $template, $suffix) =
   	$self->_rearrange([qw(DIR UNLINK TEMPLATE SUFFIX)], @args);
   $dir = $TEMPDIR unless defined $dir;
   $unlink = 1 unless defined $unlink;
   
   my @targs = ();
   push (@targs, $template) if $template;
   push (@targs, "SUFFIX", $suffix) if defined $suffix;
   push (@targs, "DIR", $dir) if defined $dir;
   push (@targs, "UNLINK", $unlink) if defined $unlink;
   ($tfh, $file) = File::Temp::tempfile(@targs);

   push @{$self->{'_rootio_tempfiles'}}, $file if $unlink;
   return wantarray ? ($tfh, $file) : $tfh;
}

=head2 tempdir

=cut

sub tempdir {
   my($self, @args) = @_;
   return File::Temp::tempdir(@args);
}

=head2 catfile

=cut

sub catfile {
   my($self, @args) = @_;
   return File::Spec->catfile(@args);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _print

=cut

sub _print {
   my $self = shift;
   my $fh = $self->_fh || \*STDOUT;
   my $ret = print $fh @_;
   return $ret;
}

=head2 _readline

=cut

sub _readline {
   my $self = shift;
   my %param = @_;
   my $fh = $self->_fh or return;
   my $line="";

   $self->{'_readbuffer'} = [] unless defined $self->{'_readbuffer'};
   if( @{ $self->{'_readbuffer'} } ){
      $line = shift @{$self->{'_readbuffer'}};
   }else{
      $line = <$fh>;
   }

   if( defined $line ){
      $line =~ s/\015\012/\012/g;
      $line =~ tr/\015/\n/;
   }
   return $line;
}

=head2 _pushback

=cut

sub _pushback {
   my($self,$line) = @_;
   return unless $line;
   push @{$self->{'_readbuffer'}}, $line;
}

=head2 _io_cleanup

=cut

sub _io_cleanup {
   my $self = shift;
   $self->close;
   if( exists($self->{'_rootio_tempfiles'}) &&
   	ref($self->{'_rootio_tempfiles'}) =~ /array/i ) { 
      unlink @{$self->{'_rootio_tempfiles'}};
   }
}

=head2 _initialize_io

=cut

sub _initialize_io {
   my($self, @args) = @_;
   $self->_register_cleanup_method(\&_io_cleanup);
   my ($input, $file, $fh, $flush, $url, $createtemp) =
   	$self->_rearrange([qw(INPUT FILE FH FLUSH URL CREATETEMP)], @args);
   
   if($createtemp){
      ($fh, $file) = $self->tempfile();
      $self->file($file);
   }
   
   if($url){
      require LWP::Simple;

      my($handle,$tempfile) = $self->tempfile();
      CORE::close($handle);

      my $http_result;
      for my $try ( 1 .. $IOTRIALS ){
         $http_result = LWP::Simple::getstore($url, $tempfile);
	 last if $http_result == 200;
	 $self->warn("[$try/$IOTRIALS] Failed to fetch $url, ".
	 	"server threw $http_result.  Retrying...");
      }
      $self->throw("Failed to fetch $url, server threw $http_result")
      		if $http_result != 200;
      $input = $tempfile;
      $file = $tempfile;
   }
   delete $self->{'_readbuffer'};
   delete $self->{'_filehandle'};
   if($input){
      if(ref(\$input) eq 'SCALAR'){
         $self->throw("Input file given twice: $file and $input disagree")
	 	if $file && $file ne $input;
	 $file = $input;
      }elsif(ref($input) && ((ref($input) eq 'GLOB') || ($input->isa("IO::Handle")))){
         $fh = $input;
      }else{
         $self->throw("Unable to determine type of input", $input);
      }
   }
   $self->warn("Bad practice to provide both file and filehandle for reading, ignoring file")
   	if defined($file) and defined($fh) and not $createtemp;

   if((!defined $fh) && defined($file) && $file ne ''){
      $fh = Symbol::gensym();
      open($fh, $file) or $self->throw("Could not open $file: $!");
      $self->file($file);# unless $fh;
   }
   $self->_fh($fh) if $fh;
   $self->_flush_on_write(defined $flush ? $flush : 1);
   return 1;
}

=head2 _fh

=cut

sub _fh {
   my($self,$value) = @_;
   $self->{'_filehandle'} = $value if defined $value;
   return $self->{'_filehandle'};
}

=head2 _flush_on_write

=cut

sub _flush_on_write {
   my($self,$value) = @_;
   $self->{'_flush_on_write'} = $value if defined $value;
   return $self->{'_flush_on_write'};
}

1;
