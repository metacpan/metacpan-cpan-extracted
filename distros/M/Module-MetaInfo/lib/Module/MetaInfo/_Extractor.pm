package Module::MetaInfo::_Extractor;
$VERSION = "0.01";
use warnings;
use strict;
use Carp;
use Cwd;
use Symbol;

=head1 NAME

Module::MetaInfo::_Extractor - Base class for perl modules to get metainfo 

=head1 USAGE

  use Module::MetaInfo::_Extractor;
  $mod=new Module::MetaInfo::_Extractor(perl-module-file.tar.gz);
  $desc=$mod->description();

=head1 DESCRIPTION

This module provides untility functions for C<Module::MetaInfo>
classes which need to extract the perl module in order to get their
meta information from it.

=head1 FUNCTIONS

=cut

my $scratch_dir="/tmp/perl-metainfo-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

my $verbose=0;

=head1 Module::MetaInfo::_Extractor::new(<distfilename>)

new creates the object and initialises it.  The argument is the path
of the perl module distribution file.

=cut

sub new {
  my $s  = shift;
  my $distname  = shift;
  my $class = ref($s) || $s;
  my $self={};

  my $distfile = $distname;
  $distfile =~ m,^/, || ( $distfile = cwd . '/' . $distfile );
  $distname =~ s,^.*/,,;
  my $package_name = $distname;
  $package_name =~ s,(.tar.gz)|(.tgz),,;
  $self->{distfile}=$distfile;
  $self->{distname}=$distname;
  $self->{package_name}=$package_name;
  $self->{_scratch_dir}=\$scratch_dir;
  $self->{_verbose}=\$verbose;
  return bless $self, $class;
}

=head1 $thing->::verbose() $thing->::scratch_dir()

These functions affect class settings (or if called for an object,
only the settings of the object: afterwards that object will ignore
changes to the class settings).

Currently implemented are verbose which prints debugging info and
scratch_dir which sets the directory to be used for unpacking perl
modules.

=cut

#N.B. $self->{scratch_dir} is a reference to the variable holding the
#location of he scratch directory.

sub scratch_dir {
  my $self = shift;
  my $val = shift;
  confess "usage: thing->scratch_dir(level)" if @_;
  if (ref($self)) {
    return ${$self->{"_scratch_dir"}} unless defined $val;
    $self->{"_scratch_dir"} = \$val;	# just myself
    return ${$self->{"_scratch_dir"}};
  } else {
    return $scratch_dir unless defined $val;
    $scratch_dir = $val;	# whole class
    return $scratch_dir;
  }
  die "not reached";
}

#N.B. $self->{verbose} is a reference to the variable holding the
#location of he scratch directory.
sub verbose {
  my $self = shift;
  my $val = shift;
  confess "usage: thing->verbose(level)" if @_;
  if (ref($self)) {
    return ${$self->{"_verbose"}} unless defined $val;
    $self->{"_verbose"} = \$val;	# just myself
    return ${$self->{"_verbose"}};
  } else {
    return $verbose unless defined $val;
    $verbose = $val;	# whole class
    return $verbose;
  }
  die "not reached";
}

=head2 $self->setup()

Setup prepares us for getting meta information.  In the current
implementation it does this by unpacking the distribution file.  In a
'future version this function may do nothing and issue a warning, but
it will continute to exist into the forseeable future.

The only reason to call this function now is to trap errors from it
separately or if you delete the setup directory and want it's contents
re-created.

=cut

sub setup {
  my $self=shift;
  my $old_dir=cwd;
  my $scratch=${$self->{_scratch_dir}};
  croak "scratch dir not defined " unless defined ${$self->{_scratch_dir}};
  -e $scratch && (! -d _ )
    && croak "scratch dir $scratch exists but is not a directory";
  -e _ or mkdir $scratch_dir
    or die "can't create scratch directory $scratch_dir" . $!;

  #FIXME: check for correct ownership of scratchdir??  probably just that
  #we have write access since we will work inside our own sub directories
  #inside it, however there could be a danger of race conditions if we use
  #someone elses directory then they rename something down the tree??

  my $unpack_dir=${$self->{_scratch_dir}} . '/' . $self->{distname};
  #FIXME: we should actually check that there is an unpacked module
  $self->{expand_dir}=
    ${$self->{_scratch_dir}} .'/'. $self->{distname}
      .'/'. $self->{package_name};
  $self->{setup}=1;
  -d $unpack_dir
    && do { warn "setup called but directory $unpack_dir exists"; return; };
  -e $unpack_dir
    && die "file exists where setup directory should be $unpack_dir";
  mkdir $unpack_dir;
  #FIXME: check exit status etc... think about all kinds of tar... use 
  #perl TAR module??
  system 'tar', 'xzCf', $unpack_dir, $self->{distfile};
  -d $unpack_dir
    || die "unpacking perl module didn't create the right name.";
}

=head2 name

returns the packages name, or at least an approximation

=cut

sub name {
  my $self=shift;
  return $self->{package_name};
}


=head1 COPYRIGHT

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified in the
Perl README.

=head1 BUGS

We trust the path to the scratch directory.  Make sure that nobody
that you don't trust can control any of the directories up to and
including the scratch directory.  There shoudld be an option to test
that the ownership and control is clear.

=head1 AUTHOR

Michael De La Rue.

=head1 SEE ALSO

L<Module::MetaInfo> L<pm-metainfo>

=cut

42;
