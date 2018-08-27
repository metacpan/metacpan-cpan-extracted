package Tcl;

$Tcl::VERSION = '1.27';

=head1 NAME

Tcl - Tcl extension module for Perl

=head1 SYNOPSIS

    use Tcl;

    $interp = Tcl->new;
    $interp->Eval('puts "Hello world"');

=head1 DESCRIPTION

The Tcl extension module gives access to the Tcl library with
functionality and interface similar to the C functions of Tcl.
In other words, you can

=over

=item *

create Tcl interpreters

The Tcl interpreters so created are Perl objects whose destructors
delete the interpreters cleanly when appropriate.

=item *

execute Tcl code in an interpreter

The code can come from strings, files or Perl filehandles.

=item *

bind in new Tcl procedures

The new procedures can be either C code (with addresses presumably
obtained using I<dl_open> and I<dl_find_symbol>) or Perl subroutines
(by name, reference or as anonymous subs). The (optional) deleteProc
callback in the latter case is another perl subroutine which is called
when the command is explicitly deleted by name or else when the
destructor for the interpreter object is explicitly or implicitly called.

=item *

Manipulate the result field of a Tcl interpreter

=item *

Set and get values of variables in a Tcl interpreter

=item *

Tie perl variables to variables in a Tcl interpreter

The variables can be either scalars or hashes.

=back

=head2 Methods in class Tcl

To create a new Tcl interpreter, use

    $interp = Tcl->new;

The following methods and routines can then be used on the Perl object
returned (the object argument omitted in each case).

=over

=item $interp->Init ()

Invoke I<Tcl_Init> on the interpreter.

=item $interp->CreateSlave (NAME, SAFE)

Invoke I<Tcl_CreateSlave> on the interpreter.  Name is arbitrary.
The safe variable, if true, creates a safe sandbox interpreter.
 See: http://www.tcl.tk/software/plugin/safetcl.html
      http://www.tcl.tk/man/tcl8.4/TclCmd/safe.htm

This command returns a new interpreter.

=item $interp->Eval (STRING, FLAGS)

Evaluate script STRING in the interpreter. If the script returns
successfully (TCL_OK) then the Perl return value corresponds to Tcl
interpreter's result otherwise a I<die> exception is raised with the $@
variable corresponding to Tcl's interpreter result object. In each case,
I<corresponds> means that if the method is called in scalar context then
the string result is returned but if the method is called in list context
then the result is split as a Tcl list and returned as a Perl list.
The FLAGS field is optional and can be a bitwise OR of the constants
Tcl::EVAL_GLOBAL or Tcl::EVAL_DIRECT.

=item $interp->GlobalEval (STRING)

REMOVED.  Evalulate script STRING at global level.
Call I<Eval>(STRING, Tcl::EVAL_GLOBAL) instead.

=item $interp->EvalFile (FILENAME)

Evaluate the contents of the file with name FILENAME. Otherwise, the
same as I<Eval>() above.

=item $interp->EvalFileHandle (FILEHANDLE)

Evaluate the contents of the Perl filehandle FILEHANDLE. Otherwise, the
same as I<Eval>() above. Useful when using the filehandle DATA to tack
on a Tcl script following an __END__ token.

=item $interp->call (PROC, ARG, ...)

Looks up procedure PROC in the interpreter and invokes it using Tcl's eval
semantics that does command tracing and will use the ::unknown (AUTOLOAD)
mechanism.  The arguments (ARG, ...) are not passed through the Tcl parser.
For example, spaces embedded in any ARG will not cause it to be split into
two Tcl arguments before being passed to PROC.

Before invoking procedure PROC special processing is performed on ARG list:

1.  All subroutine references within ARG will be substituted with Tcl name
which is responsible to invoke this subroutine. This Tcl name will be
created using CreateCommand subroutine (see below).

2.  All references to scalars will be substituted with names of Tcl variables
transformed appropriately.

These first two items allow one to write and expect it to work properly such
code as:

  my $r = 'aaaa';
  button(".d", -textvariable => \$r, -command=>sub {$r++});

3. All references to hashes will be substituted with names of Tcl array
variables transformed appropriately.

4.  As a special case, there is a mechanism to deal with Tk's special event
variables (they are mentioned as '%x', '%y' and so on throughout Tcl).
When creating a subroutine reference that uses such variables, you must
declare the desired variables using Tcl::Ev as the first argument to the
subroutine.  Example:

  sub textPaste {
      my ($x,$y,$w) = @_;
      widget($w)->insert("\@$x,$y", $interp->Eval('selection get'));
  }
  $widget->bind('<2>', [\&textPaste, Tcl::Ev('%x', '%y'), $widget] );

=item $interp->return_ref (NAME)

returns a reference corresponding to NAME, which was associated during
previously called C<< $interpnt->call(...) >> preprocessing. As a typical
example this could be variable associated with a widget.

=item $interp->delete_ref (NAME)

deletes and returns a reference corresponding to NAME, which was associated
during previously called C<< $interpnt->call(...) >> preprocessing.
this follows _code_dispose about if NAME is a TClNAME or a DESCNAME.
if NAME is a VARNAME then it is just deleted and returned.

=item $interp->icall (PROC, ARG, ...)

Looks up procedure PROC in the interpreter and invokes it using Tcl's eval
semantics that does command tracing and will use the ::unknown (AUTOLOAD)
mechanism.  The arguments (ARG, ...) are not passed through the Tcl parser.
For example, spaces embedded in any ARG will not cause it to be split into
two Tcl arguments before being passed to PROC.

This is the lower-level procedure that the 'call' method uses.  Arguments
are converted efficiently from Perl SVs to Tcl_Objs.  A Perl AV array
becomes a Tcl_ListObj, an SvIV becomes a Tcl_IntObj, etc.  The reverse
conversion is done to the result.

=item $interp->invoke (PROC, ARG, ...)

Looks up procedure PROC in the interpreter and invokes it directly with
arguments (ARG, ...) without passing through the Tcl parser. For example,
spaces embedded in any ARG will not cause it to be split into two Tcl
arguments before being passed to PROC.  This differs from icall/call in
that it directly invokes the command name without allowing for command
tracing or making use of Tcl's unknown (AUTOLOAD) mechanism.  If the
command does not already exist in the interpreter, and error will be
thrown.

Arguments are converted efficiently from Perl SVs to Tcl_Objs.  A Perl AV
array becomes a Tcl_ListObj, an SvIV becomes a Tcl_IntObj, etc.  The
reverse conversion is done to the result.

=item Tcl::Ev (FIELD, ...)

Used to declare %-substitution variables of interest to a subroutine
callback.  FIELD is expected to be of the form "%#" where # is a single
character, and multiple fields may be specified.  Returns a blessed object
that the 'call' method will recognize when it is passed as the first
argument to a subroutine in a callback.  See description of 'call' method
for details.

=item $interp->result ()

Returns the current Tcl interpreter result. List v. scalar context is
handled as in I<Eval>() above.

=item $interp->CreateCommand (CMDNAME, CMDPROC, CLIENTDATA, DELETEPROC, FLAGS)

Binds a new procedure named CMDNAME into the interpreter. The
CLIENTDATA and DELETEPROC arguments are optional. There are two cases:

(1) CMDPROC is the address of a C function

(presumably obtained using I<dl_open> and I<dl_find_symbol>. In this case
CLIENTDATA and DELETEPROC are taken to be raw data of the ClientData and
deleteProc field presumably obtained in a similar way.

(2) CMDPROC is a Perl subroutine

(either a sub name, a sub reference or an anonymous sub). In this case
CLIENTDATA can be any perl scalar (e.g. a ref to some other data) and
DELETEPROC must be a perl sub too. When CMDNAME is invoked in the Tcl
interpreter, the arguments passed to the Perl sub CMDPROC are

    (CLIENTDATA, INTERP, LIST)

where INTERP is a Perl object for the Tcl interpreter which called out
and LIST is a Perl list of the arguments CMDNAME was called with.
If the 1-bit of FLAGS is set then the 3 first arguments on the call
to CMDPROC are suppressed.
As usual in Tcl, the first element of the list is CMDNAME itself.
When CMDNAME is deleted from the interpreter (either explicitly with
I<DeleteCommand> or because the destructor for the interpreter object
is called), it is passed the single argument CLIENTDATA.

=item $interp->DeleteCommand (CMDNAME)

Deletes command CMDNAME from the interpreter. If the command was created
with a DELETEPROC (see I<CreateCommand> above), then it is invoked at
this point. When a Tcl interpreter object is destroyed either explicitly
or implicitly, an implicit I<DeleteCommand> happens on all its currently
registered commands.


=item (TCLNAME,GENCODE) = $interp->create_tcl_sub(CODEREF, EVENTS, TCLNAME, DESCRNAME)

Creates a COMMAND called TCLNAME calling CODEREF in the interpreter $interp,
and adds it to the internal tracking structure.
DESCRNAME and TCLNAME should not begin
with =
or @
or ::perl::
to avoid colisions
If TCLNAME IS blank or undef, it is constructed from the CODEREF address.
GENCODE starts as TCLNAME but gets @$EVENTS which can contain %vars joined to it.

TCLNAME and DESCRNAME get stored in an internal structure,
and can be used to purge things fRom the command table via code_destroy or $interp->delete_ref;

Returns (TCLNAME,GENCODE).
if you are creating code refs with this you can continue to use the same coderef and it will be converted on each call.
but if you save GENCODE, you can replace the anon-coderef call in the tcl command with GENCODE.

for instance

  $interp->call('FILEEVENT',$fileref,WRITABLE=>sub {...});

can be replaced by

  my ($tclcode,$gencode)=$interp->create_tcl_sub(sub{...}, EVENTS, TCLNAME, DESCRNAME);
  $interp->call('FILEEVENT',$gencode,WRITABLE=>$gencode);

or

  my $sub=sub{....};
  $interp->call('FILEEVENT',$fileref,WRITABLE=>$sub);

can be replaced by

  my ($tclcode,$gencode)=$interp->create_tcl_sub($sub, EVENTS, TCLNAME, DESCRNAME);
  $interp->call('FILEEVENT',$gencode,WRITABLE=>$gencode);

although

  $interp->call('FILEEVENT',$fileref,WRITABLE=>$sub);

will stil work fine too.

Then you later call

  $interp->delete_ref($tclname);

when you are finished with that sub to clean it from the internal tracking and command table.
This means no automatic cleanup will occur on the sub{...} or $sub


And after the destroy inside Tcl any triggering writable on $fileref will fail as well.
so it should be replaced first via
  $interp->call('FILEEVENT',$fileref,WRITABLE=>'');

=item (CODEREF) = Tcl::_code_dispose(NAME)
	
Purges the internal table of a NAME
and may initiate destruction of something created thru call or create_tcl_sub

TCLNAME and DESCRNAME get stored in an internal structure,
and can be used to purge things form the command table.
calling _code_dispose on a TCLNAME retruned from create_tcl_sub removes all use instances and purges the command table.
calling _code_dispose on a DESCRNAME passed to create_tcl_sub removes only that instace
Code used in a DESCRNAME may be used in other places as well,
only when the last usage is purged does the entry get purged from the command table

While the internal tracking structure saves the INTERP the code was added to,
it itself does not keep things separated by INTERP,
A TCLNAME or DESCRNAMe can only exist in one INTERP at a time,
using a new INTERP just causes the one in the last INTERP to disappear,
and probably end up with the Tcl code getting deleted

Returns (CODEREF), this is the original coderef

=item $interp->SetResult (STRING)

Sets Tcl interpreter result to STRING.

=item $interp->AppendResult (LIST)

Appends each element of LIST to Tcl's interpreter result object.

=item $interp->AppendElement (STRING)

Appends STRING to Tcl interpreter result object as an extra Tcl list element.

=item $interp->ResetResult ()

Resets Tcl interpreter result.

=item $interp->SplitList (STRING)

Splits STRING as a Tcl list. Returns a Perl list or the empty list if
there was an error (i.e. STRING was not a properly formed Tcl list).
In the latter case, the error message is left in Tcl's interpreter
result object.

=item $interp->SetVar (VARNAME, VALUE, FLAGS)

The FLAGS field is optional. Sets Tcl variable VARNAME in the
interpreter to VALUE. The FLAGS argument is the usual Tcl one and
can be a bitwise OR of the constants Tcl::GLOBAL_ONLY,
Tcl::LEAVE_ERR_MSG, Tcl::APPEND_VALUE, Tcl::LIST_ELEMENT.

=item $interp->SetVar2 (VARNAME1, VARNAME2, VALUE, FLAGS)

Sets the element VARNAME1(VARNAME2) of a Tcl array to VALUE. The optional
argument FLAGS behaves as in I<SetVar> above.

=item $interp->GetVar (VARNAME, FLAGS)

Returns the value of Tcl variable VARNAME. The optional argument FLAGS
behaves as in I<SetVar> above.

=item $interp->GetVar2 (VARNAME1, VARNAME2, FLAGS)

Returns the value of the element VARNAME1(VARNAME2) of a Tcl array.
The optional argument FLAGS behaves as in I<SetVar> above.

=item $interp->UnsetVar (VARNAME, FLAGS)

Unsets Tcl variable VARNAME. The optional argument FLAGS
behaves as in I<SetVar> above.

=item $interp->UnsetVar2 (VARNAME1, VARNAME2, FLAGS)

Unsets the element VARNAME1(VARNAME2) of a Tcl array.
The optional argument FLAGS behaves as in I<SetVar> above.

=back

=head2 Command table cleanup

In V1.03 command table cleanup was intoduced.
This tries to keep the internal structure and command table clean.
In V1.02 and prior heavy use of sub { .. } in Tcl commands could pollute these tables
as they were never cleared. Command table cleanup tries to alieviate this.

if you call create_tcl_sub the internal reference exists until
you delete_ref or _code_dispose it, or you call create_tcl_sub with the same DESCRNAME.

if the internal reference was created internaly by call(...) there are two rules

=over

=item 1)

If the command is an "after" the internal references is keept at least until 1 second after the delay.
If there are still other "users" of the TCLNAME then it is not deleted until the last one goes away.
If another call with the same CODEREF happens before this,
then it will get registered as a "user" without any need to delete/recreate the tcl command first.

=item 2)

otherwise a DESCRNAME is created with the text sections of the command, prefaced by "=".
Like
"=after 1000"
or "=:.m.m add command -command -label Exit"
or "=::button .f3.b8 -text conn -command"
or "=gets sock9ac2b50"
or "=fileevent sock9827430 writable"


the TCLCODES created for that command will be kept at least until a command with
the same DESCRNAME and containing a subroutine reference is run again.
Since many DESCRNAMES can reference the same TCLNAME only when
the last DESCRNAME referencing a TCLNAME is released is the TCLNAME purged.

NOTE:
Since
  $interp->call('fileevent','sock9827430','writable');
does not contain a subroutine reference, it will not release/free the TCLNAME/DESCRNAME created by
  $interp->call('fileevent','sock9827430','writable',sub{...});
even though that is the way you deactivate a writable/readable callback in Tcl.

=back

Prior to V1.06 there was also a problem with the coderef never getting cleared from sas,
a refcount was kept at the PVCV that prevented it from getting garbage collected,
but that SV itself got "lost" and could never be garbage collected,
thereby also keeping anything in that codes PAD.

To assist in tracking chages to the internal table and the commands table 3 trace subs were added,
set them to non-blank or non-zero to add the tracking output to SYSOUT, like this in your code:

    sub Tcl::TRACE_SHOWCODE(){1}

=over

=item Tcl::TRACE_SHOWCODE

Display all generated Tcl code by call().
Be aware: Tkx::MainLoop runs by issuing a lot of "winfo exists ." calls, a LOT.
But this is a nice way to tell what your programs are doing to Tcl.


=item Tcl::TRACE_CREATECOMMAND

Display Tcl subroutine creation by call/create_tcl_sub

=item Tcl::TRACE_DELETECOMMAND

Display Tcl subroutine deletion by cleanup/delete_ref/_code_dispose

=back

=head2 Linking Perl and Tcl variables

You can I<tie> a Perl variable (scalar or hash) into class Tcl::Var
so that changes to a Tcl variable automatically "change" the value
of the Perl variable. In fact, as usual with Perl tied variables,
its current value is just fetched from the Tcl variable when needed
and setting the Perl variable triggers the setting of the Tcl variable.

To tie a Perl scalar I<$scalar> to the Tcl variable I<tclscalar> in
interpreter I<$interp> with optional flags I<$flags> (see I<SetVar>
above), use

	tie $scalar, "Tcl::Var", $interp, "tclscalar", $flags;

Omit the I<$flags> argument if not wanted.

To tie a Perl hash I<%hash> to the Tcl array variable I<array> in
interpreter I<$interp> with optional flags I<$flags>
(see I<SetVar> above), use

	tie %hash, "Tcl::Var", $interp, "array", $flags;

Omit the I<$flags> argument if not wanted. Any alteration to Perl
variable I<$hash{"key"}> affects the Tcl variable I<array(key)>
and I<vice versa>.

=head2 Accessing Perl from within Tcl

After creation of Tcl interpreter, in addition to evaluation of Tcl/Tk
commands within Perl, other way round also instantiated. Within a special
namespace C< ::perl > following objects are created:

   ::perl::Eval

So it is possible to use Perl objects from within Tcl.

=head2 Moving Tcl/Tk around with Tcl.pm

NOTE: explanations below is for developers managing Tcl/Tk installations
itself, users should skip this section.

In order to create Tcl/Tk application with this module, you need to make
sure that Tcl/Tk is available within visibility of this module. There are
many ways to achieve this, varying on ease of starting things up and
providing flexible moveable archived files.

Following list enumerates them, in order of increased possibility to change
location.

=over

=item *

First method

Install Tcl/Tk first, then install Perl module Tcl, so installed Tcl/Tk will
be used. This is most normal approach, and no care of Tcl/Tk distribution is
taken on Perl side (this is done on Tcl/Tk side)

=item *

Second method

Copy installed Tcl/Tk binaries to some location, then install Perl module Tcl
with a special action to make Tcl.pm know of this location. This approach
makes sure that only chosen Tcl installation is used.

=item *

Third method

During compiling Tcl Perl module, Tcl/Tk could be statically linked into
module's shared library and all other files zipped into a single archive, so
each file extracted when needed.

To link Tcl/Tk binaries, prepare their libraries and then instruct Makefile.PL
to use these libraries in a link stage.
(TODO provide better detailed description)

=back

=cut

use strict;

sub TRACE_SHOWCODE(){0}      # display generated code in call();
sub TRACE_CREATECOMMAND(){0} # display sub creates;
sub TRACE_DELETECOMMAND(){0} # display sub deletes;

sub SAVEALLCODES () {1}    # simulate the v1.05 way of saving only last call
sub SAVENOCODE() {1}       # simulate the v1.05 way of leaving any existing
                           #  $anon_refs{$descrname} alone if new line has no coderefs

our $DL_PATH;
unless (defined $DL_PATH) {
    $DL_PATH = $ENV{PERL_TCL_DL_PATH} || $ENV{PERL_TCL_DLL} || "";
}

=for ignore
sub Tcl::seek_tkkit {
    # print STDERR "wohaaa!\n";
    unless ($DL_PATH) {
        require Config;
        for my $inc (@INC) {
            my $tkkit = "$inc/auto/Tcl/tkkit.$Config::Config{so}";
            if (-f $tkkit) {
                $DL_PATH = $tkkit;
                last;
            }
        }
    }
}
=cut
seek_tkkit() if defined &seek_tkkit;


my $path;
if ($^O eq 'darwin') {
 # Darwin 7.9 (OS X 10.3) requires the path of the executable be prepended
 # for #! scripts to operate properly (avoids RegisterProcess error).
 require Config;
 unless (grep { $_ eq $Config::Config{binexp} } split $Config::Config{path_sep}, $ENV{PATH}) {
   $path = join $Config::Config{path_sep}, $Config::Config{binexp}, $ENV{PATH};
 }
}

require XSLoader;

{
    local $ENV{PATH} = $path if $path;
    XSLoader::load('Tcl', $Tcl::VERSION);
}

sub new {
    my $int = _new(@_);
    return $int;
}

my $pid = $$; # see rt ticket 77522
END {
    Tcl::_Finalize()
        if $$ == $pid;
}

# %anon_refs keeps track of anonymous subroutines and scalar/array/hash
# references which are created on the fly for tcl/tk interchange
# at a step when 'call' interpreter method prepares its arguments for
# tcl/tk call, which is invoked by 'icall' interpreter method
# (this argument transformation is done with "CreateCommand" method for
# subs and with 'tie' for other)

my %anon_refs;
sub _anon_refs_cheat { return \%anon_refs;}

# Coderef tracking creates 3 types of entries in %anon_refs
# 1) Tcl::Code
#   this is added to %anon_refs when a coderef is found in a tcl call
#           [\$sub, $interp, $tclname,$descrname]
#     It is an array with four elements stored at the key $descrname
#       where [0] $sub is the perlcoderef,
#             [1] $interp is the tcl interpreter it is in,
#             [2] $tclname is the name for the coderef in tcl
#                 and serves as a pointer to the Tcl::Cmdbase entry
#             [3] $descrname is the name passed from call() or the app
# 2) Tcl::Cmdbase
#   this is added to %anon_refs when a new code reference is added to the tcl internal tables.
#     It is an array with two elements stored at the key $tclname
#     The first element[0] is an array [\$sub, $interp, $tclname,0]
#       where [0] $sub is the perlcoderef,
#             [1] $interp is the tcl interpreter it is in,
#             [2] $tclname is the name for the coderef in tcl
#             [3] is the number of Tcl::Code elemets that reference it.
#     The second element [1] is a hash
#      for each Tcl::Code $descrname there is a $descrname key here,
#        the value at the key is the number of Tcl::Code of that $descrname pointing to this Tcl::Cmdbase
#         when this is >1 it is because there are Tcl::Code elements in $lastcodes that will be destroyed soon
#          and we want to be able to retain the $descrname backlink after they are destroyed
# 3) an array of Tcl::Code elements stored at the key $descrname

# (TODO -- find out how to check for refcounting and proper releasing of
# resources)

# Subroutine "call" preprocess the arguments for special cases
# and then calls "icall" (implemented in Tcl.xs), which invokes
# the command in Tcl.
sub call {
    my $interp = shift;
    my @args = @_;
    # add = so  as not to interfere with user defined DESCRNAMEs
    my $descrname = '='.join ' ', grep {defined} grep {!ref} @args;
    my @codes;

    my $lastcodes = $anon_refs{$descrname}; # could be an array, want to hold all for now so they can be reused
    unless  (SAVENOCODE()) {
      unless  ($#args == 1 and $args[0] eq 'set') {
          # this was to clean up things like
          # Tkx::fileevent($remote, writable  => sub {...});
          # when this was run later
          # Tkx::fileevent($fh, writable  => '');
          # but "set foo" doesnt clear its setting, it returns its value
          # after busting the test in the Tkx tests for set foo
          #  i decided to disable this for now
          delete $anon_refs{$descrname};        # if old one had a call and new one doesnt make sure it goes away
          }
    }
    # Process arguments looking for special cases
    for (my $argcnt=0; $argcnt<=$#args; $argcnt++) {
	my $arg = $args[$argcnt];
	my $ref = ref($arg);
	next unless $ref;
	if ($ref eq 'CODE' || $ref eq 'Tcl::Code') {
	    # We have been passed something like \&subroutine
	    # Create a proc in Tcl that invokes this subroutine (no args)
	    $args[$argcnt] = $interp->create_tcl_sub($arg, undef, undef, $descrname);
	    push @codes, $anon_refs{$descrname}; # push CODE also only to keep it from early disposal
	}
	elsif ($ref eq 'SCALAR') {
	    # We have been passed something like \$scalar
	    # Create a tied variable between Tcl and Perl.

	    # stringify scalar ref, create in ::perl namespace on Tcl side
	    # This will be SCALAR(0xXXXXXX) - leave it to become part of a
	    # Tcl array.
	    my $nm = "::perl::$arg";
	    unless (exists $anon_refs{$nm}) {
		$anon_refs{$nm} = $arg;
		my $s = $$arg;
		tie $$arg, 'Tcl::Var', $interp, $nm;
		$s = '' unless defined $s;
		$$arg = $s;
	    }
	    $args[$argcnt] = $nm; # ... and substitute its name
	}
	elsif ($ref eq 'HASH') {
	    # We have been passed something like \%hash
	    # Create a tied variable between Tcl and Perl.

	    # stringify hash ref, create in ::perl namespace on Tcl side
	    # This will be HASH(0xXXXXXX) - leave it to become part of a
	    # Tcl array.
	    my $nm = $arg;
	    $nm =~ s/\W/_/g; # remove () from stringified name
	    $nm = "::perl::$nm";
	    unless (exists $anon_refs{$nm}) {
		$anon_refs{$nm} = $arg;
		my %s = %$arg;
		tie %$arg, 'Tcl::Var', $interp, $nm;
		%$arg = %s;
	    }
	    $args[$argcnt] = $nm; # ... and substitute its name
	}
	elsif ($ref eq 'ARRAY' && ref($arg->[0]) eq 'CODE') {
	    # We have been passed something like [\&subroutine, $arg1, ...]
	    # Create a proc in Tcl that invokes this subroutine with args
	    my $events;
	    # Look for Tcl::Ev objects as the first arg - these must be
	    # passed through for Tcl to evaluate.  Used primarily for %-subs
	    # This could check for any arg ref being Tcl::Ev obj, but it
	    # currently doesn't.
	    if ($#$arg >= 1 && ref($arg->[1]) eq 'Tcl::Ev') {
		$events = splice(@$arg, 1, 1);
	    }
	    $args[$argcnt] =
		$interp->create_tcl_sub(sub {
		    $arg->[0]->(@_, @$arg[1..$#$arg]);
		}, $events, undef, $descrname);
	    push @codes, $anon_refs{$descrname};
	}
	elsif ($ref eq 'REF' and ref($$arg) eq 'SCALAR') {
	    # this is a very special shortcut: if we see construct like \\"xy"
	    # then place proper Tcl::Ev(...) for easier access
	    my $events = [map {"%$_"} split '', $$$arg];
	    if (ref($args[$argcnt+1]) eq 'ARRAY' &&
		ref($args[$argcnt+1]->[0]) eq 'CODE') {
		$arg = $args[$argcnt+1];
		$args[$argcnt] =
		    $interp->create_tcl_sub(sub {
			$arg->[0]->(@_, @$arg[1..$#$arg]);
		    }, $events, undef, $descrname);
		push @codes, $anon_refs{$descrname};
	    }
	    elsif (ref($args[$argcnt+1]) eq 'CODE') {
		$args[$argcnt] = $interp->create_tcl_sub($args[$argcnt+1],$events, undef, $descrname);
		push @codes, $anon_refs{$descrname};
	    }
	    else {
		warn "not CODE/ARRAY expected after description of event fields";
	    }
	    splice @args, $argcnt+1, 1;
	}
    }

    $lastcodes = []; # now let any from last use be destroyed

    showcode(\@args) if TRACE_SHOWCODE();

    if ($#codes>-1 and $args[0] eq 'after') {
#	AFTERS can clog up the tables real quick, so plan to delete them via Tcl::Code::DESTROY
	my $delay='';
	if ($args[1] =~ /^\d+$/)   { $delay=$args[1]+1000; }
	elsif ($args[1] eq 'idle') { $delay='idle'; } # just hope they run in order
        if ($delay) {
	    my $id = $interp->icall(@args);
	    #print STDERR "rebind for $interp;$id\n";
	    # in 'after' methods, disposal of CODE REFs based on 'after' id
	    # i.e based on return value of tcl call
	    my $newname='@'.$interp.';'.$id;
	    $anon_refs{$newname} = \@codes;
	    for my $code (@codes) {
              my $ridptr=$anon_refs{$code->[2]}[1];
              $ridptr->{$newname}++ ;    # save under new name
              $ridptr->{$descrname}-- ;  # maybe take out this name
              unless ($ridptr->{$descrname}>0){
                delete $ridptr->{$descrname}; # clean up old
              }
            }
	    delete $anon_refs{$descrname};                                    # and now its clean
	    for my $code (@codes) { $code->[3]=$newname;                    } # save under new name
	    # this should trigger DESTROY unless a newer after or something else still holds a $tclname in the list
	    $interp->invoke('after',$delay, "perl::Eval {Tcl::_code_dispose('$newname')}");
	    showcode(      ['after',$delay, "perl::Eval {Tcl::_code_dispose('$newname')}"]   ) if TRACE_SHOWCODE();
	    return $id;
        }   # delay
	# if we're here - user does something wrong, but there is nothing we worry about
    } # codes and after


    # got to keep all of them alive , not just the last
    # incase there are lines that have more than one  like ===== fileevent readable=>$sub1 writable=>$sub2
    # although that isnt legal, but this is                ===== if 1 $sub1 $sub2
    #  the downside is that add/delete processing goes on for $sub1 every call if we only keep the last
    if (SAVEALLCODES()) {
        if (scalar(@codes)>1) {  # no reason to save an array of just 1
            delete $anon_refs{$descrname};
            $anon_refs{$descrname}=\@codes;
        }
    }

    # Done with special var processing.  The only processing that icall
    # will do with the args is efficient conversion of SV to Tcl_Obj.
    # A SvIV will become a Tcl_IntObj, ARRAY refs will become Tcl_ListObjs,
    # and so on.  The return result from icall will do the opposite,
    # converting a Tcl_Obj to an SV.

    # we need just this:
    #    return $interp->icall(@args);
    # a bit of complications only to allow stack trace, i.e. in case of errors
    # user will get error pointing to his program and not in this module.
    # and also 'after' tcl method makes bit harder

    if (wantarray) {
	my @res;
	eval { @res = $interp->icall(@args); };
	if ($@) {
	    my $errmsg = $@;     # 'require Carp' might destroy $@;
	    require Carp;
	    Carp::croak ("Tcl error '$errmsg' while invoking array result call:\n" .
		"\t\"@args\"");
	}
	return @res;
    } else {
	my $res;
	eval { $res = $interp->icall(@args); };
	if ($@) {
	    my $errmsg = $@;     # 'require Carp' might destroy $@;
	    require Carp;
	    Carp::croak ("Tcl error '$errmsg' while invoking scalar result call:\n" .
		"\t\"@args\"");
	}
	return $res;
    }
}

sub showcode{
  print 'TCL::TRACE_SHOWCODE:'.join(' ',@{$_[0]})."\n";
}

# create_tcl_sub will create TCL sub that will invoke perl CODE ref
# If $events variable is specified then special processing will be
# performed to provide needed '%' variables.
# If $tclname is specified then procedure will have namely that name,
# otherwise it will have machine-readable name.
# Returns tcl script suitable for using in tcl events.
sub create_tcl_sub {
    my ($interp,$sub,$events,$tclname, $descrname) = @_;
    # rnames and tclnames begining = or @ or ::perl:: are reserved for internal use
    unless ($tclname) {
	# stringify sub, becomes "CODE(0x######)" in ::perl namespace
	$tclname = "::perl::$sub";
    }

    #print STDERR "...=$descrname\n";

    # the following is a bit more tricky than it seems to.
    # because the whole intent of the Tcl:Cmdbase entries in %anon_refs hash is to have refcount
    # of (possibly) anonymous sub that is happen to be passed,
    # and, if passed for the same widget but arguments are same - then
    # previous instance will be overwriten, and sub will be destroyed due
    # to no reference count, and command table entry will also be destroyed during
    # Tcl::Cmdbase::DESTROY

    unless (exists $anon_refs{$tclname}) {
      $anon_refs{$tclname} = bless (
                                    [[\$sub, $interp, $tclname,0]
                                    ,{} # Tcl::Codes register here so they can get deleted
                                    ],'Tcl::Cmdbase');
      $interp->CreateCommand($tclname, $sub, undef, undef, 1);

      print "TCL::TRACE_CREATECOMMAND: $interp -> $descrname ( $tclname => $sub ,undef,udef,1 )\n" if TRACE_CREATECOMMAND();
      delete $anon_refs{$descrname};
    }
    my @newtcl=@{$anon_refs{$tclname}[0]};
    pop @newtcl;
    push @newtcl,$descrname;

    bless( \@newtcl, 'Tcl::Code');
    $anon_refs{$descrname} = \@newtcl;
    $anon_refs{$tclname}[0][3]++;          # push ref ct
    $anon_refs{$tclname}[1]{$descrname}++; #register as user

    my $gencode = $tclname;

    if ($events) {
	# Add any %-substitutions to callback
	$gencode = "$tclname " . join(' ', @{$events});
    }
    return $tclname , $gencode; # return both the base and code-call
}

sub _code_dispose {
    my $k = shift;
    return undef unless(exists $anon_refs{$k});
    my $ret = undef;
    my $ref = ref($anon_refs{$k});
    if    ($ref eq 'Tcl::Code') {
        $ret = $anon_refs{$k}[0];
        delete $anon_refs{$k};
    }
    elsif ($ref eq 'Tcl::Cmdbase') {
       ## mainly for calling from exterior program when it is one that calls ($tclname)=create_tcl_sub()..  too
       my $atcl = $anon_refs{$k};
       return undef unless ($atcl);
       $ret = $atcl->[0][0];
       my @keys=keys(%{$atcl->[1]});
       for my $key (@keys) {
         _code_dispose($key); # last one deletes me
       }
       delete $anon_refs{$k}; # but be sure
    }
    elsif ($ref eq 'ARRAY') {
      my $atclarray = $anon_refs{$k};
      $ret = $atclarray->[0][0];  # eh, return the first one, prob discarded anyway
      delete $anon_refs{$k}; # bunch of Tcl::Code
      }
    return $$ret;  # original delete_ref result, prob just discarded
}

sub delete_ref {
    my $interp = shift;
    my $name = shift;
    my $iam = $anon_refs{$name};
    my $ref = ref($iam);
    if    ($ref eq 'ARRAY')       { return _code_dispose ($name);}
    elsif ($ref eq 'Tcl::Code')   { return _code_dispose ($name);}
    elsif ($ref eq 'Tcl::Cmdbase'){ return _code_dispose ($name);}
    else { # these are the ties ??
      $interp->UnsetVar($name); #TODO: will this delete variable in Tcl?
      delete $anon_refs{$name};
      untie $$iam;
      return $iam;
      }
}

sub return_ref {
    my $interp = shift;
    my $name = shift;
    my $iam = $anon_refs{$name};
    my $ref = ref($iam);
    if    ($ref eq 'ARRAY')       { return ${$iam->[0][0]};}  # gotta pick one
    elsif ($ref eq 'Tcl::Code')   { return ${$iam->[0]};}
    elsif ($ref eq 'Tcl::Cmdbase'){ return ${$iam->[0][0]};}
    return $anon_refs{$name};
}

sub _code_clear {
  # for testing
  my $debug = shift;
  print "_code_clear ARRAY\n"          if ($debug);
  for my $kk (keys %anon_refs) {
    if (ref($anon_refs{$kk}) eq 'ARRAY'){ print "ARRAY $kk\n"        if ($debug); delete $anon_refs{$kk};}
    }

  print "_code_clear Tcl::Code list\n" if ($debug);
  for my $kk (keys %anon_refs) {
    if (ref($anon_refs{$kk}) eq 'Tcl::Code'){ print "Code $kk\n"     if ($debug); delete $anon_refs{$kk};}
    }

  print "_code_clear Tcl::Cmdbase\n"   if ($debug);
  for my $kk (keys %anon_refs) {
    if (ref($anon_refs{$kk}) eq 'Tcl::Cmdbase'){ print "Code $kk\n"  if ($debug); delete $anon_refs{$kk};}
    }
}


sub Ev {
    my @events = @_;
    return bless \@events, "Tcl::Ev";
}


package Tcl::Code;

# purpose is to track CODE REFs still "in use"
# (often these are anon subs)

# each has ptr to the Tcl::Cmdbase entry that tracks the command table
# so to bless it to this package and then catch deleting it, so
# to do cleaning up

sub DESTROY {
#    my $rsub    = $_[0]->[0]; # dont really need it here anymore,
#    my $interp  = $_[0]->[1];

    my $tclname     = $_[0]->[2];
    my $descrname   = $_[0]->[3];
    my $tclptr = $anon_refs{$tclname}->[0];

    return unless ($tclptr);                     # should exist but be safe
    $tclptr->[3]--;
    unless($tclptr->[3]>0) {
      delete $anon_refs{$tclname};               # kill the Cmdbase
    }
    else {
      $anon_refs{$tclname}->[1]{$descrname}--;
      unless ( $anon_refs{$tclname}->[1]{$descrname}>0) {
          delete $anon_refs{$tclname}->[1]{$descrname};  # unregister me
      }
    }
}

package Tcl::Cmdbase;

# only purpose is to track CODE REFs passed to 'call' method
# (often these are anon subs)
# so to bless it to this package and then catch deleting it, so
# to do cleaning up

sub DESTROY {
# $_[0] points to a [Tcl::code,{$descrname=>1,...}] set
    my $interp  = $_[0]->[0]->[1];
    my $tclname = $_[0]->[0]->[2];
    return unless ($tclname);
    if (defined $interp) {
      $interp->DeleteCommand($tclname);
      print "TCL::TRACE_DELETECOMMAND: $interp -> ( $tclname )\n" if TRACE_DELETECOMMAND();
    }
}

package Tcl::List;

use overload '""' => \&as_string,
             fallback => 1;

package Tcl::Var;

sub TIESCALAR {
    my $class = shift;
    my @objdata = @_;
    unless (@_ == 2 || @_ == 3) {
	require Carp;
	Carp::croak('Usage: tie $s, Tcl::Var, $interp, $varname [, $flags]');
    };
    bless \@objdata, $class;
}

sub TIEHASH {
    my $class = shift;
    my @objdata = @_;
    unless (@_ == 2 || @_ == 3) {
	require Carp;
	Carp::croak('Usage: tie %hash, Tcl::Var, $interp, $varname [, $flags]');
    }
    bless \@objdata, $class;
}

my %arraystates;
sub FIRSTKEY {
    my $obj = shift;
    die "STORE Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@_)"
	unless @{$obj} == 2 || @{$obj} == 3;
    my ($interp, $varname, $flags) = @$obj;
    $arraystates{$varname} = $interp->invoke("array","startsearch",$varname);
    my $r = $interp->invoke("array","nextelement",$varname,$arraystates{$varname});
    if ($r eq '') {
	delete $arraystates{$varname};
	return undef;
    }
    return $r;
}
sub NEXTKEY {
    my $obj = shift;
    die "STORE Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@_)"
	unless @{$obj} == 2 || @{$obj} == 3;
    my ($interp, $varname, $flags) = @$obj;
    my $r = $interp->invoke("array","nextelement",$varname,$arraystates{$varname});
    if ($r eq '') {
	delete $arraystates{$varname};
	return undef;
    }
    return $r;
}
sub CLEAR {
    my $obj = shift;
    die "STORE Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@_)"
	unless @{$obj} == 2 || @{$obj} == 3;
    my ($interp, $varname, $flags) = @$obj;
    $interp->invoke("array", "unset", "$varname");
    #$interp->invoke("array", "set", "$varname", "");
}
sub DELETE {
    my $obj = shift;
    unless (@{$obj} == 2 || @{$obj} == 3) {
	my @args = @_;
	require Carp;
	Carp::croak("STORE Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@args)");
    }
    my ($interp, $varname, $flags) = @{$obj};
    my ($str1) = @_;
    $interp->invoke("unset", "$varname($str1)"); # protect strings?
}

sub UNTIE {
    my $ref = shift;
    #print STDERR "UNTIE:$ref(@_)\n";
}
sub DESTROY {
    my $ref = shift;
    delete $anon_refs{$ref->[1]};
}

# This is the perl equiv to the C version, for reference
#
#sub STORE {
#    my $obj = shift;
#    croak "STORE Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@_)"
#	unless @{$obj} == 2 || @{$obj} == 3;
#    my ($interp, $varname, $flags) = @{$obj};
#    my ($str1, $str2) = @_;
#    if ($str2) {
#	$interp->SetVar2($varname, $str1, $str2, $flags);
#    } else {
#	$interp->SetVar($varname, $str1, $flags || 0);
#    }
#}
#
#sub FETCH {
#    my $obj = shift;
#    croak "FETCH Usage: objdata @{$obj} $#{$obj}, not 2 or 3 (@_)"
#	unless @{$obj} == 2 || @{$obj} == 3;
#    my ($interp, $varname, $flags) = @{$obj};
#    my $key = shift;
#    if ($key) {
#	return $interp->GetVar2($varname, $key, $flags || 0);
#    } else {
#	return $interp->GetVar($varname, $flags || 0);
#    }
#}

package Tcl;

=head1 Other Tcl interpreter methods

=over 2

=item export_to_tcl method

An interpreter method, export_to_tcl, is used to expose a number of perl
subroutines and variables all at once into tcl/tk.

B<export_to_tcl> takes a hash as arguments, which represents named parameters,
with following allowed values:

=over 4

=item B<namespace> => '...'

tcl namespace, where commands and variables are to
be created, defaults to 'perl'. If '' is specified - then global
namespace is used. A possible '::' at end is stripped.

=item B<subs> => { ... }

anonymous hash of subs to be created in Tcl, in the form /tcl name/ => /code ref/

=item B<vars> => { ... }

anonymous hash of vars to be created in Tcl, in the form /tcl name/ => /code ref/

=item B<subs_from> => '...'

a name of Perl namespace, from where all existing subroutines will be searched
and Tcl command will be created for each of them.

=item B<vars_from> => '...'

a name of Perl namespace, from where all existing variables will be searched,
and each such variable will be tied to Tcl.

=back

An example:

  use strict;
  use Tcl;

  my $int = Tcl->new;

  $tcl::foo = 'qwerty';
  $int->export_to_tcl(subs_from=>'tcl',vars_from=>'tcl');

  $int->Eval(<<'EOS');
  package require Tk

  button .b1 -text {a fluffy button} -command perl::fluffy_sub
  button .b2 -text {a foo button} -command perl::foo
  entry .e -textvariable perl::foo
  pack .b1 .b2 .e
  focus .b2

  tkwait window .
  EOS

  sub tcl::fluffy_sub {
      print "Hi, I am a fluffy sub\n";
  }
  sub tcl::foo {
      print "Hi, I am foo\n";
      $tcl::foo++;
  }

=cut

sub export_to_tcl {
    my $int = shift;
    my %args = @_;

    # name of Tcl package to hold tcl commands bound to perl subroutines
    my $tcl_namespace = (exists $args{namespace} ? $args{namespace} : 'perl::');
    $tcl_namespace=~s/(?:::)?$/::/;

    # a batch of perl subroutines which tcl counterparts should be created
    my $subs = $args{subs} || {};

    # a batch of perl variables which tcl counterparts should be created
    my $vars = $args{vars} || {};

    # TBD:
    # only => \@list_of_names
    # argument to be able to limit the names to export to Tcl.

    if (exists $args{subs_from}) {
	# name of Perl package, which subroutines would be bound to tcl commands
	my $subs_from = $args{subs_from};
	$subs_from =~ s/::$//;
	no strict 'refs';
	for my $name (keys %{"$subs_from\::"}) {
	    #print STDERR "$name;\n";
	    if (defined &{"$subs_from\::$name"}) {
		if (exists $subs->{$name}) {
		    next;
		}
		#print STDERR "binding sub '$name'\n";
		$int->CreateCommand("$tcl_namespace$name", \&{"$subs_from\::$name"}, undef, undef, 1);
	    }
	}
    }
    if (exists $args{vars_from}) {
	# name of Perl package, which subroutines would be bound to tcl commands
	my $vars_from = $args{vars_from};
	$vars_from =~ s/::$//;
	no strict 'refs';
	for my $name (keys %{"$vars_from\::"}) {
	    #print STDERR "$name;\n";
	    if (defined ${"$vars_from\::$name"}) {
		if (exists $vars->{$name}) {
		    next;
		}
		#print STDERR "binding var '$name' in '$tcl_namespace'\n";
		local $_ = ${"$vars_from\::$name"};
		tie ${"$vars_from\::$name"}, 'Tcl::Var', $int, "$tcl_namespace$name";
		${"$vars_from\::$name"} = $_;
	    }
	    if (0) {
		# array, hash - no need to do anything.
		# (or should we?)
	    }
	}
    }

    for my $subname (keys %$subs) {
	#print STDERR "binding2 sub '$subname'\n";
        $int->CreateCommand("$tcl_namespace$subname",$subs->{$subname}, undef, undef, 1);
    }

    for my $varname (keys %$vars) {
	#print STDERR "binding2 var '$varname'\n";
	unless (ref($vars->{$varname})) {
	    require 'Carp.pm';
	    Carp::croak("should pass var ref as variable bind parameter");
	}
	local $_ = ${$vars->{$varname}};
	tie ${$vars->{$varname}}, 'Tcl::Var', $int, "$tcl_namespace$varname";
	${$vars->{$varname}} = $_;
    }
}

=item B<export_tcl_namespace>

extra convenience sub, binds to tcl all subs and vars from perl B<tcl::> namespace

=back

=cut

sub export_tcl_namespace {
    my $int = shift;
    $int->export_to_tcl(subs_from=>'tcl', vars_from=>'tcl');
}

=head1 AUTHORS

 Malcolm Beattie, 23 Oct 1994
 Vadim Konovalov, 19 May 2003
 Jeff Hobbs, jeff (a) activestate . com, 22 Mar 2004
 Gisle Aas, gisle (a) activestate . com, 14 Apr 2004

Special thanks for contributions to Jan Dubois, Slaven Rezic, Paul Cochrane,
Huck Finn, Christopher Chavez, SJ Luo.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

#use Data::Dumper; print Dumper(\@codes)."codes \n ";

1;
