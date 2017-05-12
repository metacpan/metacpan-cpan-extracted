package Module::MetaInfo;
$VERSION = "0.03";
use warnings;
use strict;
use Carp;
use Cwd;
use Symbol;
use File::Find;

use Module::MetaInfo::AutoGuess;
use Module::MetaInfo::DirTree;
use Module::MetaInfo::ModList;

use vars qw($AUTOLOAD);

=head1 NAME

Module::MetaInfo - Report meta information from perl module distribution files

=head1 USAGE

  use Module::MetaInfo.pm;
  $mod=new Module::MetaInfo(perl-module-file.tar.gz);
  $desc=$mod->description();

=head1 DESCRIPTION

This module is designed to provide the primary interface to Perl meta
information for perl module distribution files (this, however, is a
prototype and hasn't yet been accepted by the "perl community", so
don't count on it yet).  The module is designed to allow perl modules
to be easily and accurately packaged by other package systems such as
RPM and DPKG.

The C<Module::MetaInfo> module isn't actually designed to get any meta
information from the perl module.  Instead it serves as an entry point
to other modules which have their own way of doing that.  Since there
isn't yet any agreed way to store meta-information in perl modules
this may not be very reliable.

Currently there are two ways of getting meta information: a) guessing
from the contents of the module and b) using a directory structure
which has not yet been accepted by the perl community.  The default way
this module works is to first try b) then try a) then to give up.

=head1 IMPLEMENTATION AND INHERITANCE..

This module doesn't inherit anything.  Instead it simply uses three
different classes C<Module::MetaInfo::BestGuess>
C<Module::MetaInfo::AutoGuess> and C<Module::MetaInfo::ModList>, first
trying functions from AutoGuess then from BestGuess and finally from
ModList.

=head1 FUNCTIONS

=head1 Module::MetaInfo::new(<dist_filename> [<modlist_filename>)

new creates the object and initialises it.  The argument is the path
of the perl module distribution file.

If you provide the perl modules list then meta information from the
modules list will be available.

=cut

my $scratch_dir="/tmp/perl-metainfo-temp."
  . ( $ENV{LOGNAME} ? $ENV{LOGNAME} : ( $ENV{USER} ? $ENV{USER} : "dumb" ) );

my $verbose=0;

sub new {
  my $s  = shift;
  my $distname  = shift;
  my $modlist = shift;
  my $class = ref($s) || $s;
  my $self={};

  my @metafinders =  ( Module::MetaInfo::DirTree->new($distname),
		       Module::MetaInfo::AutoGuess->new($distname) );
  push @metafinders, Module::MetaInfo::ModList->new($distname,$modlist)
    if $modlist;
  $self->{metafinders} = \@metafinders;

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
    foreach my $mod (@{$self->{metafinders}}) {
      if (  $mod->can('scratch_dir') ) {
	$mod->scratch_dir($val);
      }
    }
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
    foreach my $mod (@{$self->{metafinders}}) {
      if (  $mod->can('verbose') ) {
	$mod->verbose($val);
      }
    }
    return ${$self->{"_verbose"}};
  } else {
    return $verbose unless defined $val;
    $verbose = $val;	# whole class
    return $verbose;
  }
  die "not reached";
}


=head1 description / docs / etc...

These functions provide meta information.  They are provided by the
base classes.  In all cases the functions will return C<undef> if they
are unable to get meta information of that kind.  If there is no
function then MetaInfo will die (croak).  If you want to work with
different versions of MetaInfo that may implement different sets of
functions then use C<eval> to catch the C<die>.

For more information about the different functions available, see the
subsidiary packages such as C<Module::MetaInfo::AutoGuess> and
C<Module::MetaInfo::DirTree>.

N.B. we will throw an exception if you call a function which isn't
provided by any of the modules.  This is important since some
functions are only present if a modules list has been provided to new.
Either don't call those functions unless you have provided the modules
list or catch the exception.

=head1 RETURN CONVENTIONS

Meta information function either return a scalar (name / description)
or an array value.  If an array is returned, it will actually be
returned as a reference to an array if the function is used in a
scalar context.

In C<Module::MetaInfo.pm> the scalar return is always used so any
modules used by it must provide this mode.


=head1 FUTURE FUNCTIONS

There are a number of other things which should be implemented.  These
can be guessed from looking at the possible meta-information which can
be stored in the RPM or DPG formats, for example.  Examples include:

=over 4

=item *

copyright - GPL / as perl / redistributable / etc.

=item *

application area - Database / Internet / WWW / HTTP etc.

=item *

suggests - related applications

=back

In many cases this data is generated currently by package building
tools simply by using a fixed string.  The function should do better
than that in almost all cases or else it is't worth having...

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License, version 2 or (at your option) later or the Artistic License,
as specified in the Perl README.

=head1 BUGS 

Please see bugs in sub modules.  Especially warnings in
C<Module::MetaInfo::_Exctractor>.

=head1 AUTHOR

Michael De La Rue.

=head1 SEE ALSO

L<pm-metainfo>

=cut


sub AUTOLOAD {
  (my $sub = $AUTOLOAD) =~ s/.*:://;
  $sub =~ m/^DESTROY$/ && return;
  my $self=shift;
  croak "Function call into Module::MetaInfo wasn't a method call"
    unless ref $self;
  my $tried=0;
  my $return=undef;
 FINDER: foreach my $mod (@{$self->{metafinders}}) {
    print "try $sub in " . ref ($mod) . "\n" if ${$self->{'_verbose'}};
    if (  $mod->can($sub) ) {
      $tried++;
      #how should I cascade the effect of wantarray efficiently?
      my $return=$mod->$sub();
      if (defined $return) {
	my $ref=ref $return;
	if ($ref) {
	  die "meta info functions should only return array refs"
	    unless $ref=~m/^ARRAY/;
	  return wantarray ? @$return : $return;
	}
	return $return;
      }
    }
  }
  print STDERR "no metainfo module could provide $sub\n"
    if ${$self->{'_verbose'}};
  return undef if $tried;
  die "No function $sub defined for retrieving meta information";
}

42;

