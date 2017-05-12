package Package::Install;
use strict;
use base qw(Package::Base);
use Data::Dumper;
use ExtUtils::MakeMaker;
use Package::Configure;
use Term::ANSIColor;

sub init {
  my($self,%arg) = @_;

  $self->SUPER::init(%arg);

  $self->configure(Package::Configure->new(%arg)) unless $self->configure();
}

=head2 compile_manifest()

 Usage   : $obj->compile_manifest()
 Function: Called by L</write_makefile()>, this iterates over all .pm
           files in the distro MANIFEST and tries to compile them (perl -c)
           prints to STDERR a diagnostic message for each.
 Args    : none.


=cut

sub compile_manifest {
  my ($self) = @_;

  my $statusformat = "%-60s[%s]\n";
  my $fail         = colored('FAILED','red');
  my $pass         = colored('  OK  ','green');
  my $base         = 'lib/';

  if(! -e 'MANIFEST'){
    print STDERR colored("<FATAL> can't find MANIFEST ($!), skipping", 'red bold')."\n";
    return undef;
  }

  my @entries;
  open(M,"MANIFEST");
  while(my $file = <M>){
    chomp $file;
    next unless $file =~ /\.pm$/ and $file =~ /^$base/;

    my($pack) = $file =~ /^(.+)\.pm$/; #untaint
    $pack =~ s/^$base//;               #strip leading path
    $pack =~ s!/!::!g;                 #replace all / with ::

    push @entries, $pack;
  }
  close(M);

  print STDERR colored("compiling modules in MANIFEST", 'cyan')."\n";

  foreach my $pack (@entries){
    eval "use $pack";
    if($@ && $ENV{DEBUG}){ print "\n$@\n" }
    print STDERR sprintf($statusformat,"use $pack", ($@ ? $fail : $pass));
  }
}


=head2 write_makefile()

 Usage   : $obj->write_makefile(%arg)
 Function: calls ExtUtils::MakeMaker's WriteMakefile() with provided %arg,
           as well as PL_FILES and EXE_FILES as determined by
           Package::Configure (config file [PL_FILES] [EXE_FILES]
           sections).
 Returns :
 Args    : an anonymous hash of WriteMakefile() args.  See
           L<ExtUtils::MakeMaker> for details.

=cut

sub write_makefile {
  my ($self,%arg) = @_;
  $self->compile_manifest();
  my %pl_files;
  my @exe_files;
  if($self->configure->ini()){
    %pl_files = map {$_ => $self->configure->ini()->val('PL_FILES',$_)} $self->configure->ini()->Parameters('PL_FILES');

    #warn Dumper(\%pl_files);

    @exe_files = grep { $self->configure->ini()->val('EXE_FILES',$_) =~ /y1/i } $self->configure->ini()->Parameters('EXE_FILES');
  }

  if($arg{bootstrap}){
    $pl_files{'bin/pstub.PL'} = 'bin/pstub';
    push @exe_files, 'bin/pstub';
    delete($arg{bootstrap});
  }

  WriteMakefile(
                %arg,
                'PL_FILES'     => \%pl_files,
                'EXE_FILES'    => \@exe_files,
               );
}

=head2 configure()

 Usage   : $obj->configure($newval)
 Function: holds a Package::Configure instance
 Example : 
 Returns : value of configure (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub configure {
  my($self,$val) = @_;
  $self->{'configure'} = $val if defined($val);
  return $self->{'configure'};
}

=head1 METHODS FOR ExtUtils::MakeMaker

=cut

sub MY::clean {
  package MY;
  my $inherited = shift->SUPER::clean(@_);
  $inherited .= "\t\$(RM_F) pkg_config.cache\n";
  return $inherited;
}

1;
