package SOM;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@SOMClassPtr::ISA = ('SOMObjectPtr');

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SOM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'types' => [ qw(
   tk_void
   tk_short
   tk_ushort
   tk_long
   tk_ulong
   tk_float
   tk_double
   tk_char
   tk_boolean
   tk_octet
   tk_enum
   tk_string
   tk_pointer
   tk_objref
) ], 'class' => [ qw(
   Find_Class RepositoryNew SOMClassMgr SOMClass SOMObject SOMClassMgrObject
   Init_WP_Classes
) ], 'dsom' => [ qw(
   IsSOMDDReady RestartSOMDD IsWPDServerReady RestartWPDServer Ensure_Servers
   PMERR_WPDSERVER_IS_ACTIVE PMERR_WPDSERVER_NOT_STARTED PMERR_SOMDD_IS_ACTIVE
   PMERR_SOMDD_NOT_STARTED
   Ensure_WPDServer_Up Ensure_SOMDD_Up
   Ensure_WPDServer_Down Ensure_SOMDD_Down Ensure_Servers_Down
) ], 'environment' => [ qw(
   SYSTEM_EXCEPTION USER_EXCEPTION NO_EXCEPTION CreateLocalEnvironment
) ] );

@EXPORT_OK = map @$_, values %EXPORT_TAGS;

@EXPORT = qw(

);

BEGIN {
  require DynaLoader;
  require Exporter;

  $VERSION = '0.0601';
  @ISA = qw(Exporter DynaLoader);

  bootstrap SOM $VERSION;
  SOM::bootstrap_DSOM($VERSION);
  SOM::bootstrap_SOMIr($VERSION);
  SOM::bootstrap_SOMObject($VERSION);
}

@ObjectMgrPtr::ISA = qw(SOMObjectPtr);
@SOMDObjectMgrPtr::ISA = qw(ObjectMgrPtr);
@SOMClassMgrPtr::ISA = qw(ObjectMgrPtr);
@SOMDServerPtr::ISA = qw(SOMObjectPtr);
@ContainerPtr::ISA = qw(SOMObjectPtr);
@ContainedPtr::ISA = qw(SOMObjectPtr);
@ContainedContainerPtr::ISA = qw(ContainedPtr ContainerPtr);
@ParameterDefPtr::ISA = qw(ContainedPtr);
@OperationDefPtr::ISA = qw(ContainedContainerPtr);

# Preloaded methods go here.

sub EnvironmentPtr::Check {
  my $ev = shift;
  my $major = $ev->major;
  my $err;
  if ($major != NO_EXCEPTION()) {
    my ($id, $minor, $completed) = ($ev->id, $ev->minor, $ev->completed);
    my $c = $completed ? 'YES' : (defined $completed ? 'NO' : 'MAYBE');

    $err = "MAJOR=$major ID='$id' MINOR=$minor COMPLETED=$c\n";
  }
  $ev->Clear;
  return $err;
}

my ($dsom_server, $wpd_server);

sub Ensure_AServer_Up {		# Args: isSOMDD, delay_wait, remember, verbose
  my ($do_DD, $wait) = (shift, shift);

  # First: start SOMDD
  Ensure_SOMDD_Up((($wait and $wait > 100) ? $wait : 100), @_) unless $do_DD;

  my $up = ($do_DD ? IsSOMDDReady() : IsWPDServerReady());
  ($do_DD ? $dsom_server : $wpd_server) = $up
    if shift and not defined ($do_DD ? $dsom_server : $wpd_server);
  
  my $server = ($do_DD ? 'SOMDD' : 'WPDServer');
  my $verbose = shift;
  print STDERR "# $server running = '$up'.\n" if $verbose;
  return if $up;

  print STDERR "# Starting $server...\n" if $verbose;
  $up = ($do_DD ? RestartSOMDD(1) : RestartWPDServer(1));
  print STDERR "# Startup reported OK...\n" if $verbose and $up;
  if (!$up) {
     # ???  Such a $^E may be set due to race conditions...
     $up = 1
       if $^E == ($do_DD ? PMERR_SOMDD_IS_ACTIVE : PMERR_WPDSERVER_IS_ACTIVE);
     print STDERR "# $server running unexpectedly, race condition?"
       if $verbose and $up;
  }
  die "Unable to start SOMDD: $^E" unless $up;

  # Now the server will start, but there may be delays
  return unless $wait;
  my ($t, $until) = (0.1);
  until ($do_DD ? IsSOMDDReady() : IsWPDServerReady()) {
    print STDERR "# $server still not running, waiting...\n" if $verbose;
    my $t1 = times();
    $until = $t1 + $wait unless defined $until;
    if ($t1 >= $until) {
      die "Wait for $server start unsuccessful" if $wait != 0;
    }
    select(undef,undef,undef,$t);	# ms-sleep
    $t *= 1.2;
  }
  print STDERR "# $server reports itself started.\n" if $verbose;
}

sub Ensure_SOMDD_Up {
  Ensure_AServer_Up(1, @_);
}

sub Ensure_WPDServer_Up {
  Ensure_AServer_Up(0, @_);
}

sub Ensure_AServer_Down {		# Args: isSOMDD, delay_wait, verbose
  my ($do_DD, $wait) = (shift, shift);

  # First: shutdown WPDServer
  Ensure_WPDServer_Down((($wait and $wait > 100) ? $_[1] : 100),@_) if $do_DD;
  my $up = ($do_DD ? IsSOMDDReady() : IsWPDServerReady());

  my $server = ($do_DD ? 'SOMDD' : 'WPDServer');
  my $verbose = shift;
  print STDERR "# $server running = '$up'.\n" if $verbose;
  return unless $up;

  print STDERR "# Shutting down $server...\n" if $verbose;
  $up = not ( $do_DD ? RestartSOMDD(0) : RestartWPDServer(0) );
  print STDERR "# Shutdown reported OK...\n" if $verbose and not $up;
  if ($up) {
     # ???  Such a $^E may be set due to race conditions...
     $up = 0 if $^E == ($do_DD ? PMERR_SOMDD_NOT_STARTED
			       : PMERR_WPDSERVER_NOT_STARTED);
     print STDERR "# $server stopped unexpectedly, race condition?"
       if $verbose and not $up;

  }
  die "Unable to shutdown WPDServer: $^E" if $up;

  # Now the server will shutdown, but there may be delays
  return unless $wait;
  my ($t, $until) = (0.1);
  while ($do_DD ? IsSOMDDReady() : IsWPDServerReady()) {
    print STDERR "# $server still running, waiting...\n" if $verbose;
    my $t1 = times();
    $until = $t1 + $wait unless defined $until;
    if ($t1 >= $until) {
      my $server = ($do_DD ? 'SOMDD' : 'WPDServer');
      die "Wait for $server shutdown unsuccessful" if $wait != 0;
    }
    select(undef,undef,undef,$t);	# ms-sleep
    $t *= 1.2;
  }
  print STDERR "# $server reports itself terminated.\n" if $verbose;
}

sub Ensure_WPDServer_Down {		# Arguments: delay_wait
  Ensure_AServer_Down(0, @_);
}

sub Ensure_SOMDD_Down {
  Ensure_AServer_Down(1, @_);
}

sub Ensure_Servers {
  Ensure_WPDServer_Up(100,1);		# Memorize the state
}

sub Ensure_Servers_Down {
  Ensure_SOMDD_Down(100);
}

my $ptrsize = ptrsize();
my $ptr_letter;

for my $type (qw(i I s S l L)) {
  $ptr_letter = $type, last if $ptrsize == length pack $type, 0;
}

sub unwrap_sequence ($$) {
  my ($seq, $type) = @_;
  my $l = length($seq)/$ptrsize;
  length($seq) % $ptrsize and die "sequence of fractional length";
  die "Could not find a proper unpack letter" unless $ptr_letter;
  map bless(\$_, "$ {type}Ptr"), unpack "$ptr_letter*", $seq;
}

for my $p (qw( ContainedPtr::within.ContainedContainer
	       ContainerPtr::lookup_name.ContainedContainer
	       ContainerPtr::contents.ContainedContainer	     )) {
  my ($sub, $type) = split /\./, $p;
  my ($sub_, $s);
  {
    no strict 'refs';
    $sub_ = \&{"$ {sub}_"};
  }
  $s = sub { unwrap_sequence( &$sub_, $type ) };
  {
    no strict 'refs';
    *$sub = $s
  }
}

@RepositoryPtr::ISA = 'ContainerPtr';

# Shutdown:
END {
  Ensure_WPDServer_Down(100) if $wpd_server;
  Ensure_SOMDD_Down(100) if $dsom_server;
}

1;
__END__

=head1 NAME

SOM - Perl extension for access to SOM and DSOM objects.

=head1 SYNOPSIS

  use SOM;
  blah blah blah

=head1 DESCRIPTION

=head2 Supported types

(exported with the tag C<:types>):

   tk_short
   tk_ushort
   tk_long
   tk_ulong
   tk_float
   tk_double
   tk_char
   tk_boolean
   tk_octet
   tk_enum
   tk_string
   tk_objref
   tk_pointer		# Not yet?
   tk_void		# Output only

=head2 Supported services

  $class = Find_Class($classname, $major, $minor)

Returns SOM Class object.  Use C<$major = $minor = 0> if you do not need
a version check.

  $obj = $class->NewObject()

Creates a new instance of an object of the given class.

  $repo = RepositoryNew()

Returns an object for access to Repository.

  SOMClass()

Returns the SOM (meta)class C<SOMClass>.

  SOMObject()

Returns the SOM class C<SOMObject>.

  SOMClassMgr()

Returns the SOM class C<SOMClassMgr>.

  SOMClassMgrObject()

Returns the standard C<SOMClassMgrObject> object.

  $obj->Dispatch0($method_name)

Dispatches a method with void return and no arguments (not supported,
fatal error if $method_name cannot be resolved).

  $obj->Dispatch_templ($method_name, $template, ...)

Dispatches a method with return type and arguments described by a $template.
See F<t/animal.t> how to build a template.

  $obj->GetClass()

Return the class of the object (as a SOM object).

=head1 Primitive classes

Some SOM methods are hardwired into the module, they operate on Perl
objects with names ending on C<Ptr>.  (Other SOM methods are currently
supported with Dispatch_templ() method only.)

Note that support of Repository classes is much more complete than for
other classes, since support on auto-import of methods is impossible
without this.

DSOM-related primitive classes are listed in L<Working with DSOM>.

=head2 SOMObjectPtr

=over 10

=item C<GetClass>

Returns the class object.

=item C<GetClassName>

Returns the class name.

=back

Additionally, two non-SOM methods are made available: Dispatch0() and
Dispatch_templ().

=head2 SOMClassPtr

=over 10

=item C<NewObject>

Returns a new object of the given class.

=back

=head2 ContainedPtr

All the methods take environment as an argument:

  $name = $obj->name($env)

=over 10

=item C<name>

String name of the element (unique inside the immediate parent).

=item C<id>

String id of the element (unique in the repository).

=item C<defined_in>

String id of the immediate parent.

=item C<within>

Returns a list of containers with definitions of this object.

=item C<describe>

Returns information defined in the IDL specification of this object.
B<Memory management for this???>.  Return type is C<AttributeDescriptionPtr>.

=back

=head2 ContainerPtr

=over 10

=item C<lookup_name>

Returns a list of objects with the given name within a specified
Container object, or within objects contained in the Container object.

  $obj->lookup_name($env, $name, $levels, $type, $noinherited)

$levels should be -1 to search all the kids-containers as well, otherwise should be 1. $type should be one of

  AttributeDef ConstantDef ExceptionDef InterfaceDef
  ModuleDef ParameterDef OperationDef TypeDef all

If $noinherited, any inherited objects will not be returned.

=item C<contents>

Returns the list of contained elements.

  $obj->contents($env, $type, $noinherited)

Parameters have the same sense as for the C<lookup_name> method.

=back

=head2 AttributeDescriptionPtr

B<Should be scraped: AttributeDescriptionPtr should be substituted by
proper subclass of Contained!>

The methods do not take environment as an argument:

  $typecode = $attr->type()

In addition to methods name(), id(), defined_in() similar to ones in C<Contained>, has two additional methods:

=over 10

=item type

C<TypeCodePtr> object which describes the type of the attribute.

=item readonly

whether the attribute is readonly.

=back

Currently there is no value() method.

=head2 OperationPtr

All the methods take environment as an argument:

  $name = $op->result($env)

=over 10

=item C<result>

C<TypeCode> of the return value.

=back

=head2 ParameterPtr

All the methods take environment as an argument:

  $name = $argN->type($env)

=over 10

=item C<type>

C<TypeCode> of this argument.

=item C<mode>

One of the strings C<INOUT>, C<OUT>, C<IN>.

=back

=head2 TypeCode

All the methods take environment as an argument:

  $kind = $tc->kind($env)

=over 10

=item C<kind>

Returns the type of the TypeCode.  Types are the same as L<Supported types>.

=item C<param_count>

Returns the number of parameters encoded in the TypeCode.

=item C<parameter>

Returns the I<n>th parameter encoded in the TypeCode as C<any>.  I<n> changes
from 0 to I<param_count>C< - 1>.

  $p = $tc->parameter($env, 2);

=back

=head2 any

All the methods take environment as an argument:

  $type = $any->type($env)

=over 10

=item C<type>

Returns the C<TypeCode> of the value stored in the C<any>.

=item C<value>

Returns the value stored in the C<any>.  Only elementary types are supported now.

=back

=head1 Repository

Since C<Container>/C<Contained> are completely supported by primitive
classes, one can walk the Repository tree any way one is pleased.  We
use only the following subtree of the Repository: inside toplevel we
find C<InterfaceDef> elements (which carry information about SOM
classes), inside an C<InterfaceDef> we look for C<OperationDef>
elements (which correspond to methods in the class), and inside an
C<OperationDef> we look for C<ParameterDef> elements (which correspond
to arguments of a method).

=head2 BUGS

We consider C<ContainedContainerPtr> as being both a C<ContainerPtr>
and C<ContainedPtr>.  But not all of them are.  This is bad, since
calling C SOM bindings on an object of unappropriate type is not catchable.

=head1 Working with DSOM

After any call which includes $ev, one should C<$ev->Clear> to avoid
memory leaks.  Before this call $ev can be expected for error info.
Package SOM contains following I<major codes> of exceptions:
SYSTEM_EXCEPTION, USER_EXCEPTION, NO_EXCEPTION (exportable with tag
C<:environment>).

This API is very experimental.  Read DSOM reference to know what these
calls are doing.

=head2 Starting/stopping servers

DSOM to WPS requires two servers: one is a SOMD server (a separate
process), another is WPSD server (extra thread(s) in WPS shell
process). To check existence: SOM::IsSOMDDReady(), SOM::IsWPDServerReady().
Possible error codes in $^E: PMERR_WPDSERVER_IS_ACTIVE(),
PMERR_WPDSERVER_NOT_STARTED(), PMERR_SOMDD_IS_ACTIVE(), 
PMERR_SOMDD_NOT_STARTED() (all in package SOM, exportable on C<:dsom>).

To create: C<SOM::RestartSOMDD(1)>, C<SOM::RestartWPDServer(1)>.

To stop: C<SOM::RestartSOMDD(0)>, C<SOM::RestartWPDServer(0)>.

Keep in mind that servers are not refcounted, so it maybe not a very
good idea to shut them down even if did not run when you started
(since somebody else could have started to use them in between).

Additionally, stopping servers when they did not completely started
could lead to problems.

A convenience function C<SOM::Ensure_Servers($shutdown_dsom,
$shutdown_wpsd)> is provided.  If the arguments are given, servers
will be shutdown at end of run if they were not running when this
function was called.  (Exportable with C<:dsom>)

=head2 Class C<EnvironmentPtr>

To create:

  $ev = SOM::CreateLocalEnvironment();

(exportable with tag C<:environment>).

Methods:

  $major = $ev->major;
  $stringID = $ev->id;
  $minor = $ev->id;		# 0 if $ev->major != SYSTEM_EXCEPTION
  $state = $ev->completed;	# undef if $ev->major != SYSTEM_EXCEPTION
				# or state is not YES or NO, otherwise 0 or 1
  $ev->Clear;			# Free() data if $ev->major == SYSTEM_EXCEPTION

A simpleminded error reporter is made available as method C<Check>:

  $err = $ev->Check and warn "Got exception $err";

$err is formatted as C<MAJOR=2 ID='OPSYS' MINOR=343 COMPLETED=NO>.

=head2 Package C<SOM::SOMDeamon>

Functions:

  Init($ev);
  Uninit($ev);
  ClassMgrObject();		# Default SOMD class manager
  ObjectMgr();			# Default SOMD object manager
  WPClassManagerNew();		# One can Merge the result with ObjectMgr()

=head2 Class C<SOMClassManagerPtr>

Methods:

  $oldmgr->MergeInto($newmgr);

=head2 Class C<ObjectMgrPtr>

Methods:

  $mgr->ReleaseObject($ev, $servername);

=head2 Class C<SOMDObjectMgrPtr>

ISA C<ObjectMgrPtr>.

Methods:

  $server = $mgr->FindServerByName($ev, $servername);

=head2 Class C<SOMDServerPtr>

Methods:

  $server->GetClassObj($ev, $classname);

=head2 Example

Initialize:

  use SOM ':class', ':dsom', ':environment';
  Ensure_Servers();
  $ev = SOM::CreateLocalEnvironment();

  sub EnvironmentPtr::CheckAndWarn {
    my $err; $err = $ev->Check and warn "Got exception $err";
  }

Start class dispatchers:

  SOM::SOMDeamon::Init($ev);
  $ev->CheckAndWarn;
  $SOM_ClassMgr = SOM::SOMDeamon::ClassMgrObject or die;
  $WPS_ClassMgr = SOM::SOMDeamon::WPClassManagerNew or die;
  $SOM_ClassMgr->MergeInto($WPS_ClassMgr); # In fact MergeFrom

  Init_WP_Classes();	# Otherwise cannot GetClassObj('WPFolder')

  $server = SOM::SOMDeamon::ObjectMgr->FindServerByName($ev, "wpdServer")
    or die;
  $ev->CheckAndWarn;

Get a class object of requested type:

  $classFolder = $server->GetClassObj($ev, "WPFolder") or die;
  $ev->CheckAndWarn;
  ## ... Do some work with $folderClass

Shut down dispatchers:

  SOM::SOMDeamon::ObjectMgr->ReleaseObject($ev, $server);
  $ev->CheckAndWarn;
  SOM::SOMDeamon::Uninit($ev);
  $ev->CheckAndWarn;

=head1 EXPORT

None by default.  Tags C<:types>, C<:class>, C<:dsom>, C<:environment>.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 BUGS

Only primitive types of parameters and return value are supported.

Only in-parameters are supported.

No memory management is done at all.

Exception is not analysed.

SOM Objects have type SOMObjectPtr, SOM Classes have type SOMClassPtr etc.

Methods may be dispatched only when a signature is explicitely described.

=head1 SEE ALSO

perl(1).

=cut
