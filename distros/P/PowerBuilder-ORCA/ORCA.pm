#*OEM*
package PowerBuilder::ORCA;

use strict;
use Carp;

require Exporter;
require DynaLoader;
require AutoLoader;

our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our %EXPORT_TAGS = ( 'const' => [ qw(
	PBORCA_APPLICATION
	PBORCA_DATAWINDOW
	PBORCA_FUNCTION
	PBORCA_MENU
	PBORCA_PIPELINE
	PBORCA_PROJECT
	PBORCA_PROXYOBJECT
	PBORCA_QUERY
	PBORCA_STRUCTURE
	PBORCA_USEROBJECT
	PBORCA_WINDOW

    PBORCA_P_CODE
    PBORCA_MACHINE_CODE
    PBORCA_MACHINE_CODE_NATIVE
    PBORCA_MACHINE_CODE_16
    PBORCA_P_CODE_16
    PBORCA_OPEN_SERVER
    PBORCA_TRACE_INFO
    PBORCA_ERROR_CONTEXT
    PBORCA_MACHINE_CODE_OPT
    PBORCA_MACHINE_CODE_OPT_SPEED
    PBORCA_MACHINE_CODE_OPT_SPACE
    PBORCA_MACHINE_CODE_OPT_NONE

	PBORCA_FULL_REBUILD
	PBORCA_INCREMENTAL_REBUILD
	PBORCA_MIGRATE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'const'} } );

our @EXPORT = qw(

);
our $VERSION = '0.05';

our $AUTOLOAD;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined PowerBuilder::ORCA macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap PowerBuilder::ORCA $VERSION;

# Preloaded methods go here.

sub new {
    shift;
    my ($lib_list,$app_lib,$app_name)=@_;
	my $self={};
	bless $self;
    $self->{SID}=SesOpen() or croak("Can't open ORCA sesion");
    my ($rc,$err);
    if ($lib_list) {
        $rc=$self->SetLibList((@$lib_list));
        if ( $rc ) {
            $err=$self->GetError();
            $self->Close();
            croak($err."(ORCA RC=$rc)");
            return undef;
        }
	}
	if ($app_lib && $app_name) {
        $rc=$self->SetAppl($app_lib,$app_name);
        if ( $rc ) {
            $err=$self->GetError();
            $self->Close();
            croak($err."(ORCA RC=$rc)");
            return undef;
        }
    }
    return $self;
}

sub LibDirList {
    my ($self,$pbl,$type)=@_;

    my $res=[];
    my @tmp;
    my $rc=$self->LibDir($pbl,\@tmp);
    croak($self->GetError) if $rc;
    if ( defined($type) ) {
       for my $e ( @tmp ) {
            push @$res,$e->{Name} if $e->{Type}==$type;
       }
    } else {
       for my $e ( @tmp ) {
          push @$res,$e->{Name};
       }
    }
    @$res;
}

sub LoadDll {
    my $dll=shift;

    if ( ! defined($dll) ) {
        if ( exists($ENV{ORCA_DLL}) ) {
            ORCA_Init($ENV{ORCA_DLL});
            $PowerBuilder::ORCA::ORCA_Dll=$ENV{ORCA_DLL};
            return;
        } else {
            my @dlls=qw( pborc90.dll pborc80.dll pborc70.dll pborc60.dll pborc050.dll );
            for my $d ( split(/;/,$ENV{PATH}) ) {
                for my $dll ( @dlls  ) {
                    if ( -f  "$d\\$dll" ) {
                        ORCA_Init("$d\\$dll");
                        $PowerBuilder::ORCA::ORCA_Dll="$d\\$dll";
                        return;
                    }
                }
            }
            croak("The ORCA dll ".join(",",@dlls)." not found in PATH: ");
        }
    } else {
        if ( -f $dll ) {
            ORCA_Init($dll);
            $PowerBuilder::ORCA::ORCA_Dll=$dll;
            return;
        } elsif ( $dll !~ /[\\\/]/ ) {
            for my $d ( split(/;/,$ENV{PATH}) ) {
                if ( -f "$d\\$dll" ) {
                    ORCA_Init("$d\\$dll");
                    $PowerBuilder::ORCA::ORCA_Dll="$d\\$dll";
                    return;
                }
            }
            croak("The ORCA dll $dll not found in PATH");
        } else {
            croak("The ORCA dll does not exist: $dll");
        }
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

PowerBuilder:: ORCA - Perl interface to PowerBuilder ORCA API

=head1 SYNOPSIS

    use PowerBuilder::ORCA qw/:const/;

    #open new ORCA session
    my $ses=new PowerBuilder::ORCA(['d:\WORK\C\xs\PowerBuilder\ORCA\pbtest.pbl'],
        'd:\WORK\C\xs\PowerBuilder\ORCA\pbtest.pbl',
        'pbtest');

    #now, it is possible to carry out manipulations with objects
    my $rc=$ses->Export("pbtest.pbl","f_is_dir",PBORCA_FUNCTION,$buf);

    my %h;
    $ses->EntryInfo("pbtest.pbl","f_db_connect",PBORCA_FUNCTION,\%h);

    #close session
    $ses->Close();

=head1 DESCRIPTION

This module enables to use Powersoft Open Library API (ORCA) from Perl. ORCA
is software for accessing the PowerBuilder Library Manager functions that
PowerBuilder uses in the Library painter. A perl script
can use ORCA to do the same kinds of object and library management
that the Library painter interface provides.

ORCA was created for CASE tool vendors as part of the Powersoft CODE
(Client/Server Open Development Environment) program. CASE tools needed
programmatic access to PowerBuilder libraries to create and modify
PowerBuilder objects based on an application design.

To execute programs using ORCA API it is necessary to have pborcNN.dll, which
is part professional and enterprise versions of PB, where NN - number of PB version.
For example, PowerBuilder version 6 - pborc60.dll.

The detailed description of ideology and functions of ORCA can be found in the documentation on PB
( http://sybooks.sybase.com/onlinebooks/group-pb/adt0650e/orca/ ). It is B<recommended> to read
this documentation.

Conformity of ORCA API functions and methods given ORCA.pm:

    ORCA API                        ORCA.pm
    ------------------------------  ------------------
    PBORCA_SessionClose             Close
    PBORCA_SessionGetError          GetError
    PBORCA_SessionOpen              new
    PBORCA_SessionSetCurrentAppl    SetAppl
    PBORCA_SessionSetLibraryList    SetLibList
    PBORCA_LibraryCommentModify     LibCommentModify
    PBORCA_LibraryCreate            LibCreate
    PBORCA_LibraryDelete            LibDel
    PBORCA_LibraryDirectory         LibInfo,LibDir,LibDirList
    PBORCA_LibraryEntryCopy         Copy
    PBORCA_LibraryEntryDelete       Del
    PBORCA_LibraryEntryExport       Export
    PBORCA_LibraryEntryInformation  EntryInfo
    PBORCA_LibraryEntryMove         Move
    PBORCA_CheckOutEntry            CheckOut
    PBORCA_CheckInEntry             CheckIn
    PBORCA_ListCheckOutEntries      ListCheckOutEntries
    PBORCA_CompileEntryImport       Import
    PBORCA_CompileEntryImportList   ImportList
    PBORCA_CompileEntryRegenerate   Regenerate
    PBORCA_ExecutableCreate         ExeCreate
    PBORCA_DynamicLibraryCreate     DllCreate
    PBORCA_ObjectQueryHierarchy     ObjectQueryHierarchy
    PBORCA_ObjectQueryReference     ObjectQueryReference

=head1 METHODS

=head2 Error handling

The majority of functions return a nonzero error code in a case
unsuccessful completion. The error message can be obtained trought
GetError function.

Error codes:

   Code  Description
   ----  -----------------------------------
      0  Operation successful
     -1  Invalid parameter list
     -2  Duplicate operation
     -3  Object not found
     -4  Bad library name
     -5  Library list not set
     -6  Library not in library list
     -7  Library I/O error
     -8  Object exists
     -9  Invalid name
    -10  Buffer size is too small
    -11  Compile error
    -12  Link error
    -13  Current application not set
    -14  Object has no ancestors
    -15  Object has no references
    -16  Invalid # of PBDs
    -17  PBD create error
    -18  Source Management error

=head2 Initialization

=over 4

Before the beginning of work it is necessary to specify name of ORCA dll file. Name of dll
depends on PB version.

=item PowerBuilder::ORCA::LoadDll($dll_file);

=item PowerBuilder::ORCA::LoadDll();

Loads specified dll. If file name specified without path - searches for
dll in PATH. If no file specified, function checks environment variable ORCA_DLL.
If it exists, loads specified dll. If the variable not exists, searches in PATH
for dll of version 9,8,7,6 or 5 and loads the first found. If nothing has helped - dies.

The name of loaded dll is kept in a variable $PowerBuilder::ORCA::ORCA_Dll.

=back

=head2 Session management

=over 4

=item $ses=new PowerBuilder::ORCA;

=item $ses=new PowerBuilder::ORCA(\@lib_list);

=item $ses=new PowerBuilder::ORCA(\@lib_list, $app_pbl, $app_name);

Creates new session object, establishes an ORCA session and returns a handle
that you use for subsequent ORCA calls.
The second variant of a call also establishes the list of libraries for an
ORCA session (see SetLibList).
The last variant also establishes the current application object for an ORCA session
(see SetAppl).

=item $rc=$ses->SetLibList($pbl1,$pbl2,...)

You must call SetLibList and SetAppl before calling any ORCA function that compiles
or queries objects. Library names should be fully qualified wherever possible.

You can set the current application and library list only once in a session.
If you need to change either the library list or current application after
it has been set, close the session and open a new session.

ORCA uses the search path to find referenced objects when you regenerate or
query objects during an ORCA session. Just like PowerBuilder, ORCA looks through
the libraries in the order in which they are specified in the library search path
until it finds a referenced object.

You can call the following library management functions and source control functions
without setting the library list:

    CommentModify
    LibCreate
    LibDel
    LibInfo, LibDir, LibDirList
    Copy
    Del
    Export
    EntryInfo
    Move
    CheckOut
    CheckIn


=item $rc=$ses->SetAppl($pbl,$obj)

You must set the library list before setting the current application.

You must call SetLibList and then SetAppl before calling any ORCA function
that compiles or queries objects. The library name should include the full
path for the file wherever possible.

You can set the library list and current application only once in a session.
If you need to change the current application after it has been set, close
the session and open a new session.

The name of pbl should be specified B<in accuracy> as in SetLibList call.

=item $ses->Close()

Terminates an ORCA session, releases resources.

=item $errmsg=$ses->GetError()

You can call GetError anytime another ORCA function call results in an error.
When an error occurs, functions always return complete error message.
If there is no current error, the function will return an empty string.

=back

=head2 Manipulations with objects

=over 4

=item $rc=$ses->EntryInfo($pbl,$obj,$type,\%hbuf)

Returns the information on object $obj of type $type from library $pbl. The information
Includes the comment, the size of the source text, the size of object and
date and time of last modification. The information returned in hash %hbuf. Keys of hbuf
correspond to the fields of structure PBORCA_ENTRYINFO:

    Key         PBORCA_ENTRYINFO field
    ----------- ---------------------------
    Comments    lpszComments
    CreateTime  lpszCreateDate, lpszCreateTime
    ObjectSize  dwObjectSize
    SourceSize  dwSourceSize

Note: SourceSize ORCA returns incorrectly.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->Export($pbl,$obj,$type,$buf)

Exports the source code for a PowerBuilder library entry to a buffer $buf.

The comparable function in the Library painter saves the exported source in a text file.

The Library painter includes two header lines in the file. ORCA does not add
header lines in its export buffer.

In the buffer, the exported source code includes carriage return (hex 0D)
and newline (hex 0A) characters at the end of each display line.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->Import($pbl,$obj,$type,$comment,$syntax,\$errbuf)

=item $rc=$ses->Import($pbl,$obj,$type,$comment,$syntax,\@errbuf)

Imports the source code for a PowerBuilder object into a library and compiles it.
If there are compilation errors $rc ==-11 and error messages placed to $errbuf.

You must set the library list and current Application object before calling this function.

When errors occur during importing, the object is brought into the library
but may need editing. An object with minor errors can be opened in its
painter for editing. If the errors are severe enough, the object can fail
to open in the painter and you will have to export the object, fix the
source code, and import it again.

=item $rc=$ses->ImportList(\$errbuf,

        {
            Library=>'lib1.pbl',
            Name=>'f_func1',
            Type=>PBORCA_FUNCTION,
            Comment=>'comment 1',
            Syntax=>'source_code_of_f_func1'
        },
        {
            Library=>'lib2.pbl',
            Name=>'another_object_name',
            Type=>PBORCA_type_of_object,
            Comment=>'comment 2',
            Syntax=>'source_code_for_object'
        } ...
        );

=item $rc=$ses->ImportList(\@errbuf,
		...

Imports the source code for a list of PowerBuilder objects into libraries
and compiles them.

If there are compilation errors $rc ==-11 and error messages placed to $errbuf.

You must set the library list and current Application object before calling this function.

ImportList is useful for importing several interrelated objects--for example,
a window, its menu, and perhaps a user object that it uses.


=item $rc=$ses->Regenerate($pbl,$obj,$type,\$errbuf)

=item $rc=$ses->Regenerate($pbl,$obj,$type,\@errbuf)

Compiles an object in a PowerBuilder library.

If there are compilation errors $rc ==-11 and error messages placed to $errbuf.
$errbuf can be the reference to a scalar or the reference to an array.
In the first case the scalar contains all error messages incorporated into a line.
In the second case function return errors as array of hashes, each hash has keys:

    Level
    MessageNumber
    MessageText
    ColumnNumber
    LineNumber

You must set the library list and current Application object before calling this function.

=item $rc=$ses->ApplicationRebuild($type,\$errbuf)

=item $rc=$ses->ApplicationRebuild($type,\@errbuf)

Compiles all the objects in the libraries included on the library list. If
necessary, the compilation is done in multiple passes to resolve circular
dependencies.

You must set the library list and current application before calling this function.

If you use the compile functions, errors can occur because of the order the
objects are compiled. If two objects both refer to each other, then simple
compilation will fail. Use PBORCA_ApplicationRebuild to resolve errors due
to object dependencies. PBORCA_ApplicationRebuild resolves circular
dependencies with multiple passes through the compilation process.

If there are compilation errors $rc ==-11 and error messages placed to $errbuf.
$errbuf can be the reference to a scalar or the reference to an array.
In the first case the scalar contains all error messages incorporated into a line.
In the second case function return errors as array of hashes, each hash has keys:

    Level
    MessageNumber
    MessageText
    ColumnNumber
    LineNumber

=item $rc=$ses->Copy($src_pbl,$dst_pbl,$obj,$type)

Copies a PowerBuilder library entry from one library to another.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->Move($src_pbl,$dst_pbl,$obj,$type)

Moves a PowerBuilder library entry from one library to another.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->Del($pbl,$obj,$type)

Deletes a PowerBuilder library file from disk.

You don't need to set the library list or current application before calling this function.

=back

=head2 Manipulations with libraries

=over 4

=item $rc=$ses->LibInfo($pbl,$comment,$n_obj)

Returns the information on library $pbl. $comment - the comment, $n_obj - number
Objects in library.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->LibDir($pbl,\@objects);

The array @objects is filled by the information on objects in library $pbl.
Each element of @objects - the reference to a hash with the following keys:

    Name        a name of object
    Type        type of object
    Size        the size of object
    CreateTime  time of creation of object
    Comment     the comment

You don't need to set the library list or current application before calling this function.

=item $list_ref=$ses->LibDirList($pbl[,$type])

Returns the reference to a array with names of objects of the given type in library
$pbl. If the type is not given - returns names of all objects. It is possible
to use LibDirList in for loop:

    for my $obj_name ( LibDirList('lib1.pbl') ) {
        ...
    }

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->LibCreate($pbl,$comment)

Creates library with a name $pbl.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->LibDel($pbl)

Deletes library with a name $pbl.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->LibCommentModify($pbl,$new_comment);

Sets the comment for library $pbl.

You don't need to set the library list or current application before calling this function.

=back

=head2 VCS interface

=over 4

=item $rc=$ses->CheckOut($obj,$type,$master_pbl,$work_pbl,$user_id,$copy)

Checks out a library entry from a master library (the source) to a work library (the destination).
$copy - an integer whose value indicates whether to simply change the check-out
flags in the libraries or to copy the object to the work library, too. Values are:

0 -- Mark the object as checked out in the master and work libraries,
but leave the copy of the object in the work library as is.
Do not overwrite it with the copy in the master library

1 -- Mark the object as checked out in the master and work libraries and copy
the object from the master library to the work library

$user_id - the version control user ID.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->CheckIn($obj,$type,$master_pbl,$work_pbl,$user_id,$move)

Checks in a library entry from a work library (the destination) to a master
library (the source). $move - an integer whose value indicates whether to
simply change the check-out flags in the libraries or to move the object
from the work library to the master library, deleting it from the work
library. Values are:

0 -- Clear the check-out status of the object in the master and work
libraries, but leave the copy of the object in the master library as is. Do
not overwrite it with the copy in the work library and do not delete it
from the work library

1 -- Clear the check-out status of the object in the master and work
libraries and move the copy in the work library to the master library,
deleting it from the work library

$user_id - the version control user ID. The ID must be the same one used
to check out the object.

You don't need to set the library list or current application before calling this function.

=item $rc=$ses->ListCheckOutEntries($pbl,\@storage);

Returns check-out information for objects in a PowerBuilder library.

Each element of array is a hash with the following keys:

    LibName     a name of library
    Name        a name of object
    UserID      a name of the user
    Mode        the status (s - source, r - registered, d - distanation)

Hash corresponds to structure PBORCA_CHECKOUT.

You don't need to set the library list or current application before calling this function.

=back

=head2 References and inheritance

=over 4

=item $rc=$ses->ObjectQueryHierarchy($pbl,$obj,$type,\@storage);

Queries a PowerBuilder object to get a list of the objects in its ancestor
hierarchy. Places the result to array @storage. Only windows, menus, and
user objects have an ancestor hierarchy that can be queried.

You must set the library list and current Application object before calling this function.

=item $rc=$ses->ObjectQueryReference($pbl,$obj,$type,\@storage);

Queries a PowerBuilder object to get a list of its references to other
objects. Places the result to array @storage. Each element of @storage is
a hash with following keys:

    LibName library name
    Name    object name
    Type    object type
    RefType reference type (o - open, s - simple)

Hash corresponds to structure PBORCA_REFERENCE.

You must set the library list and current Application object before calling this function.

=back

=head2 Compilation

=over 4

=item $rc=$ses->DllCreate($pbl,$pbr,$options);

Creates a PowerBuilder dynamic library (PBD) or PowerBuilder DLL.

Before calling this function, you must have previously set the library list
and current application.

If you plan to build an executable in which some of the libraries are
dynamic libraries, you must build those dynamic libraries before building
the executable.

$options - a long value that indicates which code generation options to
apply when building the library (combination of constants described in
L<Code generation parameters>.

=item $rc=$ses->SetExeInfo({

		CompanyName => 'CompanyName',
		ProductName => 'ProductName',
		Description => 'Description',
		Copyright => 'Copyright',
		FileVersion => '9,9,9,9',
		FileVersionNum => '8,8,8,8',
		ProductVersion => 'ProductVersion',
		ProductVersionNum => '7,7,7,7',
	};

Sets the version information, used at creation of the .exe.

=item $rc=$ses->ExeCreate($exe,$ico,$pbr,\@pbd_flags,$options,\$errors);

You must set the library list and current Application object before calling this function.

Creates a PowerBuilder executable with Pcode or machine code. For a machine
code executable, you can request several debugging and optimization
options. If you are creating a server for a distributed application, you
can specify that it be an Open Server executable.

The ORCA library list is used to create the application. You can specify
which of the libraries have already been built as PBDs or DLLs and which
will be built into the executable file.

Parameters:

    $exe - a name of an executed file (should not exists)
    $ico - an icon file
    $pbr - a resources (.pbr) file
    @pbd_flags - for every pbl in library list:
        0 - to include objects in .exe a file;
        1 - to use already constructed pbd/dll
        The number of elements in a file should correspond to number of
        Libraries in library list
    $options - parameters of generation of a code (see L<Code generation parameters>)
    $errors - the buffer for errors.

=back

=head1 Exported constants

Constans are exported, if tag const specified:

    use use PowerBuilder:: ORCA qw/:const/;

=head2 Types of objects

    PBORCA_APPLICATION
    PBORCA_DATAWINDOW
    PBORCA_FUNCTION
    PBORCA_MENU
    PBORCA_PIPELINE
    PBORCA_PROJECT
    PBORCA_PROXYOBJECT
    PBORCA_QUERY
    PBORCA_STRUCTURE
    PBORCA_USEROBJECT
    PBORCA_WINDOW

=head2 Code generation parameters

    PBORCA_P_CODE
    PBORCA_MACHINE_CODE
    PBORCA_MACHINE_CODE_NATIVE
    PBORCA_MACHINE_CODE_16
    PBORCA_P_CODE_16
    PBORCA_OPEN_SERVER
    PBORCA_TRACE_INFO
    PBORCA_ERROR_CONTEXT
    PBORCA_MACHINE_CODE_OPT
    PBORCA_MACHINE_CODE_OPT_SPEED
    PBORCA_MACHINE_CODE_OPT_SPACE
    PBORCA_MACHINE_CODE_OPT_NONE

=head2 Rebuild type

    PBORCA_FULL_REBUILD
    PBORCA_INCREMENTAL_REBUILD
    PBORCA_MIGRATE

=head1 AUTHOR

Ilya Chelpanov, ilya@macro.ru, chelpanov@mail.ru
http://i72.by.ru/eng/, http://i72.narod.ru/eng/

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

PowerBuilder online books, "ORCA Guide"
http://sybooks.sybase.com/onlinebooks/group-pb/adt0650e/orca/

Demo applications pbexe and reslst on my home page http://i72.by.ru/eng/.

=cut
