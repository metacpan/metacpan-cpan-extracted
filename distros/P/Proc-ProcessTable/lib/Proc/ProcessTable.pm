package Proc::ProcessTable;

use 5.006;

use strict;
use warnings;
use Carp;
use Config;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    
);
$VERSION = '0.59';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
    if ($! =~ /Invalid/) {
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD;
    }
    else {
        croak "Your vendor has not defined Proc::ProcessTable macro $constname";
    }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Proc::ProcessTable $VERSION;

# Preloaded methods go here.
use Proc::ProcessTable::Process;
use File::Find;

my %TTYDEVS;

our $TTYDEVSFILE = "/tmp/TTYDEVS_" . $Config{byteorder}; # Where we store the TTYDEVS hash

sub new 
{
  my ($this, %args) = @_;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  mutex_new(1);
  if ( exists $args{cache_ttys} && $args{cache_ttys} == 1 )
  { 
    $self->{cache_ttys} = 1 
  }

  if ( exists $args{enable_ttys} && (! $args{enable_ttys}))
  {
    $self->{enable_ttys} = 0;
    if ($self->{'cache_ttys'}) {
      carp("cache_ttys specified with enable_ttys, cache_ttys a no-op");
    }
  }
  else
  {
    $self->{enable_ttys} = 1;
  }

  my $status = $self->initialize;
  mutex_new(0);
  if($status)
  {
    return $self; 
  }
  else
  {
    return undef;
  }
}

sub initialize 
{
  my ($self) = @_;

  if ($self->{enable_ttys})
  {

    # Get the mapping of TTYs to device nums
    # reading/writing the cache if we are caching
    if( $self->{cache_ttys} )
    {

      require Storable;

      if( -r $TTYDEVSFILE )
      {
        $_ = Storable::retrieve($TTYDEVSFILE);
        %Proc::ProcessTable::TTYDEVS = %$_;
      }
      else
      {
        $self->_get_tty_list;

        require File::Temp;
        require File::Basename;

        my($ttydevs_fh, $ttydevs_tmpfile) = File::Temp::tempfile('ProcessTable_XXXXXXXX', DIR => File::Basename::dirname($TTYDEVSFILE));
        chmod 0644, $ttydevs_tmpfile;
        Storable::store_fd( \%Proc::ProcessTable::TTYDEVS, $ttydevs_fh );
        close $ttydevs_fh;

        if( !rename $ttydevs_tmpfile, $TTYDEVSFILE )
        {
          my $err = $!;
          unlink $ttydevs_tmpfile;
          if( !-r $TTYDEVSFILE)
          {
            die "Renaming $ttydevs_tmpfile to $TTYDEVSFILE failed: $err";
          }
          # else somebody else obviously created the file in the meantime
        }
      }
    }
    else
    {
      $self->_get_tty_list;
    }
  }

  # Call the os-specific initialization
  $self->_initialize_os;

  return 1; 
}

###############################################
# Generate a hash mapping TTY numbers to paths.
# This might be faster in Table.xs,
# but it's a lot more portable here
###############################################
sub _get_tty_list 
{
  my ($self) = @_;
  undef %Proc::ProcessTable::TTYDEVS;
  find({ wanted => 
       sub{
     $File::Find::prune = 1 if -d $_ && ! -x $_;
     my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
     $Proc::ProcessTable::TTYDEVS{$rdev} = $File::Find::name
       if(-c $File::Find::name);
       }, no_chdir => 1},
       "/dev" 
      );
}

# Apparently needed for mod_perl
sub DESTROY {}

1;
__END__

=head1 NAME

Proc::ProcessTable - Perl extension to access the unix process table

=head1 SYNOPSIS

  use Proc::ProcessTable;

  my $p = Proc::ProcessTable->new( 'cache_ttys' => 1 ); 
  my @fields = $p->fields;
  my $ref = $p->table;

=head1 DESCRIPTION

Perl interface to the unix process table.

=head1 METHODS

=over 4

=item new

Creates a new ProcessTable object. The constructor can take the following
flags:

enable_ttys -- causes the constructor to use the tty determination code,
which is the default behavior.  Setting this to 0 disables this code,
thus preventing the module from traversing the device tree, which on some
systems, can be quite large and/or contain invalid device paths (for example,
Solaris does not clean up invalid device entries when disks are swapped).  If
this is specified with cache_ttys, a warning is generated and the cache_ttys
is overridden to be false.

cache_ttys -- causes the constructor to look for and use a file that
caches a mapping of tty names to device numbers, and to create the
file if it doesn't exist. This feature requires the Storable module.
By default, the cache file name consists of a prefix F</tmp/TTYDEVS_> and a
byte order tag. The file name can be accessed (and changed) via
C<$Proc::ProcessTable::TTYDEVSFILE>.

=item fields

Returns a list of the field names supported by the module on the
current architecture.

=item table

Reads the process table and returns a reference to an array of
Proc::ProcessTable::Process objects. Attributes of a process object
are returned by accessors named for the attribute; for example, to get
the uid of a process just do:

$process->uid

The priority and pgrp methods also allow values to be set, since these
are supported directly by internal perl functions.

=back

=head1 EXAMPLES

 # A cheap and sleazy version of ps
 use Proc::ProcessTable;

 my $FORMAT = "%-6s %-10s %-8s %-24s %s\n";
 my $t = Proc::ProcessTable->new;
 printf($FORMAT, "PID", "TTY", "STAT", "START", "COMMAND"); 
 foreach my $p ( @{$t->table} ){
   printf($FORMAT, 
          $p->pid, 
          $p->ttydev, 
          $p->state, 
          scalar(localtime($p->start)), 
          $p->cmndline);
 }


 # Dump all the information in the current process table
 use Proc::ProcessTable;

 my $t = Proc::ProcessTable->new;

 foreach my $p (@{$t->table}) {
  print "--------------------------------\n";
  foreach my $f ($t->fields){
    print $f, ":  ", $p->{$f}, "\n";
  }
 }              

=head1 CAVEATS

Please see the file README in the distribution for a list of supported
operating systems. Please see the file PORTING for information on how
to help make this work on your OS.

=head1 AUTHOR

D. Urist, durist@frii.com

=head1 SEE ALSO

L<Proc::ProcessTable::Process>, L<perl(1)>.

=cut


