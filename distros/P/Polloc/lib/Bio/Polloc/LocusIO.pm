=head1 NAME

Bio::Polloc::LocusIO - I/O interface of C<Bio::Polloc::Locus::*> objects

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=item *

L<Bio::Polloc::Polloc::IO>

=back

=head1 SYNOPSIS

Read & write loci:

    use strict;
    use Bio::Polloc::LocusIO;

    my $locusI = Bio::Polloc::LocusIO->new(-file=>"t/loci.gff3", -format=>"gff3");
    my $locusO = Bio::Polloc::LocusIO->new(-file=>">out.gff3", -format=>"gff3");

    while(my $locus = $locusI->next_locus){
       print "Got a ", $locus->type, " from ", $locus->from, " to ", $locus->to, "\n";
       # Filter per type
       if($locus->type eq "repeat"){
          $locusO->write_locus($locus);
       }
    }

=cut

package Bio::Polloc::LocusIO;
use strict;
use base qw(Bio::Polloc::Polloc::Root Bio::Polloc::Polloc::IO);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Bio::Polloc::LocusIO::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($format, $file) = $bme->_rearrange([qw(FORMAT FILE)], @args);

      ($format = $file) =~ s/^.*\.// if $file and not $format;
      if($format){
         $format = __PACKAGE__->_qualify_format($format);
         $class = "Bio::Polloc::LocusIO::" . $format if $format;
      }
   }

   if($class =~ m/Bio::Polloc::LocusIO::(\S+)/){
      my $load = 0;
      if(__PACKAGE__->_load_module($class)){
         $load = $class;
      }
      
      if($load){
         my $self = $load->SUPER::new(@args);
	 $self->debug("Got the LocusIO class $load");
         $self->_initialize(@args);
         return $self;
         
      }
      
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }
   my $bme = Bio::Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Bio::Polloc::LocusI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 format

Gets/sets the format of the file

=over

=item Arguments

Format (str), currently supported: gff3.

=item Return

Format (str or C<undef>).

=back

=cut

sub format {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_format($value);
      $self->throw("Attempting to set an invalid type of locus",$value) unless $v;
      $self->{'_format'} = $v;
   }
   return $self->{'_format'};
}

=head2 write_locus

Appends one locus to the output file.

=over

=item Arguments

=over

=item -locus I<Bio::Polloc::LocusI>, mandatory

The locus to append.

=item -force I<Bool (int)>

If true, forces re-parsing of the locus.  Otherwise,
tries to load cached parsing (if any).

=back

=back

=cut

sub write_locus {
   my($self, @args) = @_;
   my($locus) = $self->_rearrange([qw(LOCUS)], @args);
   $self->throw("You must provide the locus to append") unless defined $locus;
   $self->throw("The obtained locus is not an object", $locus)
   	unless UNIVERSAL::can($locus, 'isa');
   $self->_write_locus_impl(@args);
}

=head2 read_loci

Gets the loci stored in the input file.

=over

=item Arguments

=over

=item -genomes I<arrayref of Bio::Polloc::Genome objects>

An arrayref containing the L<Bio::Polloc::Genome> objects associated to
the collection of loci.  This is not mandatory, but C<seq> and
C<genome> properties will not be set on the newly created objects
if this parameter is not provided.

=back

=item Returns

A L<Bio::Polloc::LociGroup> object.

=back

=cut

sub read_loci { return shift->_read_loci_impl(@_) }

=head2 next_locus

Reads the next locus in the buffer.

=over

=item Arguments

Same of L<read_loci>

=item Returns

A L<Bio::Polloc::LocusI> object.

=back

=cut

sub next_locus { return shift->_next_locus_impl(@_) }

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _qualify_format

Uniformizes the distinct names that every format can receive

=over

=item Arguments

The requested format (str)

=item Returns

The qualified format (str or undef)

=back

=cut

sub _qualify_format {
   my($self,$value) = @_;
   return unless $value;
   $value = 'gff3' if $value =~ /^gff3?$/i;
   $value = lc $value;
   return $value;
}

=head2 _write_locus_impl

Format-specific implementation of C<write_locus>.

=cut

sub _write_locus_impl {
   $_[0]->throw("_write_locus_impl", $_[0], 'Bio::Polloc::Polloc::UnimplementedException');
}

=head2 _read_loci_impl

Format-specific implementation of C<next_locus>.

=cut

sub _read_loci_impl {
   my ($self,@args) = @_;
   my($genomes) = $self->_rearrange([qw(GENOMES)], @args);
   my $group = Bio::Polloc::LociGroup->new(-genomes=>$genomes);
   while(my $locus = $self->next_locus(@args)){
      $group->add_locus($locus);
   }
   return $group;
}

=head2 _next_locus_impl

=cut

sub _next_locus_impl {
   $_[0]->throw("_next_locus_impl", $_[0], 'Bio::Polloc::Polloc::UnimplementedException');
}

=head2 _save_locus

=cut

sub _save_locus {
   my($self, $locus) = @_;
   $self->{'_saved_loci'}||= [];
   push @{$self->{'_saved_loci'}}, $locus if defined $locus;
   return $locus;
}

=head2 _locus_by_id

=cut

sub _locus_by_id {
   my($self, $id) = @_;
   return unless defined $id;
   my @col = grep { $_->id eq $id } @{$self->{'_saved_loci'}};
   return $col[0];
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->_initialize_io(@_);
}

1;
