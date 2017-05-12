#
#   OS390::Stdio - z/OS, S/390 (MVS) extensions to Perl's stdio calls
#
#   Author:  Peter Prymmer  pvhp@pvhp.best.vwh.net 
#            adapted from Charles Bailey's VMS::Stdio V. 2.1
#   Revised:  O6-Oct-2002
#   Revised:  31-Aug-2002
#   Revised:  25-May-2001
#   Revised:  13-Apr-1999
#   Previous: 31-Aug-1998
#

package OS390::Stdio;

require 5.005;
use vars qw( $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA );
use Carp '&croak';
use DynaLoader ();
use Exporter ();
 
$VERSION = '0.008';
@ISA = qw( Exporter DynaLoader IO::File );

my @STDIO_CONSTANTS = 
           qw( 
              &KEY_FIRST &KEY_LAST &KEY_EQ &KEY_EQ_BWD &KEY_GE 
              &RBA_EQ &RBA_EQ_BWD
            );
my @FCNTL_CONSTANTS = 
           qw( 
              &O_APPEND &O_CREAT &O_EXCL  &O_NDELAY &O_NOWAIT
              &O_RDONLY &O_RDWR  &O_TRUNC &O_WRONLY 
            );
my @ALCUNIT_CONSTANTS =
           qw( 
              &ALCUNIT_CYL &ALCUNIT_TRK
            );
my @DISP_CONSTANTS =
           qw( 
              &DISP_OLD &DISP_MOD &DISP_NEW &DISP_SHR 
              &DISP_UNCATLG &DISP_CATLG &DISP_DELETE &DISP_KEEP
            );
my @DSORG_CONSTANTS =
           qw( 
              &DSORG_unknown &DSORG_VSAM &DSORG_GS &DSORG_PO
              &DSORG_POU &DSORG_DA &DSORG_DAU &DSORG_PS
              &DSORG_PSU &DSORG_IS &DSORG_ISU
            );
my @RECFM_CONSTANTS =
           qw( 
              &RECFM_M &RECFM_A &RECFM_S &RECFM_B
              &RECFM_D &RECFM_V &RECFM_F &RECFM_U
              &RECFM_FB &RECFM_VB &RECFM_FBS &RECFM_VBS
            );
my @MISCFL_CONSTANTS =
           qw( 
              &MISCFL_CLOSE &MISCFL_RELEASE &MISCFL_PERM &MISCFL_CONTIG
              &MISCFL_ROUND &MISCFL_TERM &MISCFL_DUMMY_DSN &MISCFL_HOLDQ
            );
my @VSAM_CONSTANTS =
           qw( 
              &VSAM_KS &VSAM_ES &VSAM_RR &VSAM_LS
            );
my @DSNT_CONSTANTS =
           qw( 
              &DSNT_HFS &DSNT_PIPE &DSNT_PDS &DSNT_LIBRARY
            );
my @PATH_CONSTANTS =
           qw( 
              &PATH_OCREAT &PATH_OEXCL &PATH_ONOCTTY &PATH_OTRUNC
              &PATH_OAPPEND &PATH_ONONBLOCK &PATH_ORDWR &PATH_ORDONLY
              &PATH_OWRONLY &PATH_SISUID &PATH_SISGID &PATH_SIRUSR
              &PATH_SIWUSR &PATH_SIXUSR &PATH_SIRWXU &PATH_SIRGRP
              &PATH_SIWGRP &PATH_SIXGRP &PATH_SIRWXG &PATH_SIROTH
              &PATH_SIWOTH &PATH_SIXOTH &PATH_SIRWXO
            );
my @DYNIT_CONSTANTS = (
                       @ALCUNIT_CONSTANTS,@RECFM_CONSTANTS,@DISP_CONSTANTS,
                       @DSORG_CONSTANTS,@VSAM_CONSTANTS,@DSNT_CONSTANTS,
                       @MISCFL_CONSTANTS,@PATH_CONSTANTS
                      );

@EXPORT = qw(
              &KEY_FIRST &KEY_LAST &KEY_EQ &KEY_EQ_BWD &KEY_GE
              &RBA_EQ &RBA_EQ_BWD
            );

@EXPORT_OK = ( qw( &flush 
                 &dsname_level  &dynalloc &dynfree
                 &forward &getname &get_dcb &mvsopen &mvswrite &pds_mem
                 &remove &rewind &resetpos &smf_record &sysdsnr
                 &svc99 &tmpnam &vol_ser
                 &vsamdelrec &vsamlocate &vsamupdate
                 ),
                 @ALCUNIT_CONSTANTS ,
                 @DISP_CONSTANTS ,
                 @DSORG_CONSTANTS ,
                 @RECFM_CONSTANTS ,
                 @MISCFL_CONSTANTS ,
                 @VSAM_CONSTANTS ,
                 @DSNT_CONSTANTS ,
                 @PATH_CONSTANTS 
             );
%EXPORT_TAGS = ( CONSTANTS => [ qw( 
                                    &KEY_FIRST &KEY_LAST &KEY_EQ &KEY_EQ_BWD
                                    &KEY_GE &RBA_EQ &RBA_EQ_BWD
                                  ) ],
                 ALCUNIT_CONSTANTS => [ @ALCUNIT_CONSTANTS ],
                 DISP_CONSTANTS    => [ @DISP_CONSTANTS ],
                 DSORG_CONSTANTS   => [ @DSORG_CONSTANTS ],
                 RECFM_CONSTANTS   => [ @RECFM_CONSTANTS ],
                 MISCFL_CONSTANTS  => [ @MISCFL_CONSTANTS ],
                 VSAM_CONSTANTS    => [ @VSAM_CONSTANTS ],
                 DSNT_CONSTANTS    => [ @DSNT_CONSTANTS ],
                 PATH_CONSTANTS    => [ @PATH_CONSTANTS ],
                 FUNCTIONS => [ qw( 
                                    &dynalloc &dynfree 
                                    &flush &forward
                                    &getname &get_dcb &mvsopen &mvswrite 
                                    &pds_mem &remove &rewind &resetpos
                                    &smf_record &sysdsnr &tmpnam 
                                    &vsamdelrec &vsamlocate &vsamupdate
                                    ) ], 
                 EXPERIMENTAL => [ qw( 
                                    &dsname_level 
                                    &svc99 &vol_ser 
                                    ) ], 
               );

bootstrap OS390::Stdio $VERSION;

sub AUTOLOAD {
    my($constname) = $AUTOLOAD;
    $constname =~ s/.*:://;
    if ($constname =~ /^KEY_|^RBA_|^O_|^ALCUNIT_|^RECFM_|^DISP_|^DSORG_|^MISCFL_|^VSAM_|^DSNT_|^PATH_/) {
      my($val) = constant($constname);
      defined $val or croak("Unknown OS390::Stdio constant $constname");
      *$AUTOLOAD = sub { $val; }
    }
    else { # We don't know about it; hand off to IO::File
      require IO::File;

      *$AUTOLOAD = eval "sub { shift->IO::File::$constname(\@_) }";
      croak "Error autoloading IO::File::$constname: $@" if $@;
    }
    goto &$AUTOLOAD;
}

sub DESTROY { close($_[0]); }

# in case we ever use AutoLoader

1;

__END__

=head1 NAME

OS390::Stdio - z/OS and OS/390 standard I/O functions with POSIX/XPG extensions

=head1 SYNOPSIS

    use OS390::Stdio qw( &dynalloc &dynfree 
                         &get_dcb &getname &pds_mem &sysdsnr
                         &mvsopen &mvswrite 
                         &flush &forward &rewind &resetpos
                         &remove &tmpnam 
                         &smf_record
                         &svc99 
                         &vsamdelrec &vsamlocate &vsamupdate
      # future dslist        &dsname_level &vol_ser 
                       );

    @dslist = dsname_level("FRED");
    $uniquename = tmpnam;
    $fh = mvsopen("//MY.STUFF","a recfm=F") or die $!;
    $name = getname($fh);
    print $fh "Hello, world!\n";
    flush($fh);
    rewind($fh);
    $line = <$fh>;
    undef $fh;  # closes data set
    $fh = mvsopen("dd:MYDD(MEM)", "recfm=U");
    sysread($fh,$data,128);
    close($fh);
    remove("dd:MYDD(MEM)");
    @members = pds_mem("//'SYS1.PARMLIB'");
    @aliases = pds_mem("//'SYS1.PARMLIB'",1);

=head1 DESCRIPTION

This package gives Perl scripts running on z/OS or OS/390 access via POSIX 
extensions to several C stdio operations not available through Perl's CORE 
I/O functions.  The specific routines are described below.  These functions
are prototyped as unary operators, with the exception of C<mvsopen>
which takes two arguments, C<mvswrite> and C<smf_record> each of which 
takes three arguments, C<svc99> which take several arguments, 
and C<tmpnam> which takes none.

All of the routines are available for export, though none are
exported by default.  All of the constants used by C<vsamupdate>
to specify update options are exported by default, other constants
that are not exported are available via explicit calls to C<constant>
or via Exporter tags *_CONSTANTS (see below).  

The routines are associated with the Exporter tag FUNCTIONS, the 
experimental routines are associated with the Exporter tag EXPERIMENAL, 
and the stdio.h VSAM constants are associated with the Exporter tag CONSTANTS, 
so you can more easily choose what you'd like to import:

    # import constants, but not functions
    use OS390::Stdio;  # same as use OS390::Stdio qw( :DEFAULT );
    # import functions, but not constants
    use OS390::Stdio qw( !:CONSTANTS :FUNCTIONS ); 
    # import both
    use OS390::Stdio qw( :CONSTANTS :FUNCTIONS ); 
    # import nothing
    use OS390::Stdio ();
    # import everything
    use OS390::Stdio qw(
        :CONSTANTS :FUNCTIONS :EXPERIMENTAL
        :ALCUNIT_CONSTANTS :DISP_CONSTANTS :DSORG_CONSTANTS :RECFM_CONSTANTS
        :MISCFL_CONSTANTS :VSAM_CONSTANTS :DSNT_CONSTANTS :PATH_CONSTANTS
                       );

Of course, you can also choose to import specific functions by
name, as usual.

This package C<ISA> IO::File, so that you can call L<IO::File>
methods on the handles returned by C<mvsopen>. 
The IO::File package is not initialized, however, until you
actually call a method that OS390::Stdio doesn't provide.  This
is done to save startup time for users who don't wish to use
the IO::File methods.

=head1 CONSTANTS

The constants handled by OS390::Stdio derive from #define preprocessor statements
in three C header files on z/OS or OS/390: stdio.h, fcntl.h, and dynit.h.

=head2 stdio.h constants

Constants related to VSAM usage in stdio.h have corresponding constants
in OS390::Stdio.  They are:

    &KEY_FIRST &KEY_LAST &KEY_EQ &KEY_EQ_BWD &KEY_GE
    &RBA_EQ &RBA_EQ_BWD

These are ordinarily imported by either C<use OS390::Stdio;> or 
C<use OS390::Stdio qw(:CONSTANTS);>

=head2 fcntl.h constants

fcntl.h constants intended for use with open() are also handled by OS390::Stdio.
They are:

    &O_APPEND &O_CREAT &O_EXCL &O_NDELAY &O_NOWAIT
    &O_RDONLY &O_RDWR &O_TRUNC &O_WRONLY

These are ordinarily not imported.

=head2 dynit.h constants

Constants defined in dynit.h are grouped and mapped to slightly different names
by  OS390::Stdio.  There are 8 distinct groupings of dynit.h constants:
ALCUNIT_CONSTANTS, DISP_CONSTANTS, DSORG_CONSTANTS, RECFM_CONSTANTS,
MISCFL_CONSTANTS, VSAM_CONSTANTS, DSNT_CONSTANTS, and PATH_CONSTANTS.
These constants are frequently used with routines like C<dynalloc()> and
C<dynfree()>.

=over 4

=item * ALCUNIT_CONSTANTS

Corresponding to allocation unit constants.  These can either be 
imported via C<use OS390::Stdio qw(:ALCUNIT_CONSTANTS);>
or they can be used individually as in:

    use OS390::Stdio;
    my $cylinder = OS390::Stdio::constants('ALCUNIT_CYL');

The constants and the corresponding definitions in this group are:

    ALCUNIT_CYL    __CYL
    ALCUNIT_TRK    __TRK

=item * DISP_CONSTANTS

These constants handle status (status), normal dispostion (normdisp),
and conditional disposition (conddisp) types.  These may optionally be 
imported via C<use OS390::Stdio qw(:DISP_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    DISP_OLD       __DISP_OLD
    DISP_MOD       __DISP_MOD
    DISP_NEW       __DISP_NEW
    DISP_SHR       __DISP_SHR
    DISP_UNCATLG   __DISP_UNCATLG
    DISP_CATLG     __DISP_CATLG
    DISP_DELETE    __DISP_DELETE
    DISP_KEEP      __DISP_KEEP

=item * DSORG_CONSTANTS

These are data set organization type constants.  These may optionally be 
imported via C<use OS390::Stdio qw(:DSORG_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    DSORG_unknown  __DSORG_unknown
    DSORG_VSAM     __DSORG_VSAM
    DSORG_GS       __DSORG_GS
    DSORG_PO       __DSORG_PO
    DSORG_POU      __DSORG_POU
    DSORG_DA       __DSORG_DA
    DSORG_DAU      __DSORG_DAU
    DSORG_PS       __DSORG_PS
    DSORG_PSU      __DSORG_PSU
    DSORG_IS       __DSORG_IS
    DSORG_ISU      __DSORG_ISU

=item * RECFM_CONSTANTS

These constants correspond to various record format types recognized by
dynfree().  These may optionally be imported via 
C<use OS390::Stdio qw(:RECFM_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    RECFM_M        _M_
    RECFM_A        _A_
    RECFM_S        _S_
    RECFM_B        _B_
    RECFM_D        _D_
    RECFM_V        _V_
    RECFM_F        _F_
    RECFM_U        _U_
    RECFM_FB       _FB_
    RECFM_VB       _VB_
    RECFM_FBS      _FBS_
    RECFM_VBS      _VBS_

=item * MISCFL_CONSTANTS

Miscellaneous flags constants.  These may optionally be imported 
via C<use OS390::Stdio qw(:MISCFL_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    MISCFL_CLOSE   __CLOSE
    MISCFL_RELEASE __RELEASE
    MISCFL_PERM    __PERM
    MISCFL_CONTIG  __CONTIG
    MISCFL_ROUND   __ROUND
    MISCFL_TERM    __TERM
    MISCFL_DUMMY_DSN __DUMMY_DSN
    MISCFL_HOLDQ   __HOLDQ

=item * VSAM_CONSTANTS

These constants designate VSAM record organizations types.  They
may optionally be imported via C<use OS390::Stdio qw(:VSAM_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    VSAM_KS        __KS
    VSAM_ES        __ES
    VSAM_RR        __RR
    VSAM_LS        __LS

=item * DSNT_CONSTANTS

These are PDS type constants and may optionally be imported 
via C<use OS390::Stdio qw(:DSNT_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    DSNT_HFS       __DSNT_HFS
    DSNT_PIPE      __DSNT_PIPE
    DSNT_PDS       __DSNT_PDS
    DSNT_LIBRARY   __DSNT_LIBRARY

=item * PATH_CONSTANTS

The constants in this group correspond to path options and to path
attributes.  They may optionally be imported via 
C<use OS390::Stdio qw(:PATH_CONSTANTS);>.

The constants and the corresponding definitions in this group are:

    PATH_OCREAT    __PATH_OCREAT
    PATH_OEXCL     __PATH_OEXCL
    PATH_ONOCTTY   __PATH_ONOCTTY
    PATH_OTRUNC    __PATH_OTRUNC
    PATH_OAPPEND   __PATH_OAPPEND
    PATH_ONONBLOCK __PATH_ONONBLOCK
    PATH_ORDWR     __PATH_ORDWR
    PATH_ORDONLY   __PATH_ORDONLY
    PATH_OWRONLY   __PATH_OWRONLY
    PATH_SISUID    __PATH_SISUID
    PATH_SISGID    __PATH_SISGID
    PATH_SIRUSR    __PATH_SIRUSR
    PATH_SIWUSR    __PATH_SIWUSR
    PATH_SIXUSR    __PATH_SIXUSR
    PATH_SIRWXU    __PATH_SIRWXU
    PATH_SIRGRP    __PATH_SIRGRP
    PATH_SIWGRP    __PATH_SIWGRP
    PATH_SIXGRP    __PATH_SIXGRP
    PATH_SIRWXG    __PATH_SIRWXG
    PATH_SIROTH    __PATH_SIROTH
    PATH_SIWOTH    __PATH_SIWOTH
    PATH_SIXOTH    __PATH_SIXOTH
    PATH_SIRWXO    __PATH_SIRWXO

=back

=head1 FUNCTIONS

In the following C<DSH> refers to a data set handle such as returned
by the C<mvsopen> routine.  For OS data sets C<NAME> refers to either a
double slashed name such as C<//BETTY.BAM>, or members such as
C<//BETTY.BAM(BAM)>; or to dd names such as C<dd:WILMA.PEBBLES>.

=over 4

=item dynalloc HASHREF

Dynamically allocates a data set via the C RTL C<dynalloc()> routine.
Returns a true value on success, undef on failure.

You may wish to refer to your system's F</usr/include/dynit.h> header
file for information on the __dyn_t struct typedef as well as
constants used by the C version of dynalloc().  You might also be 
interested in symbolic constant names as can be found in dynit.ph 
after running h2ph on dynit.h (see the INSTALL document for perl).

The hashref to be passed to dynalloc may contain keys with names 
derived from the __dyn_t member names with the two leading 
underscores removed.  For example:

    my $hashref = {("ddname" -=> "MYDD", "dsname" => "FRED.DSN", ... )};

While most of the hash values can be character strings (SvPV below)
some of the hash values must be integers or chars ((cast)SvIV below):

    Perl      C __dyn_t      Perl -> C
    hash key  member         value type
    ddname     __ddname =    SvPV(hval,len);
    dsname     __dsname =    SvPV(hval,len);
    sysout     __sysout =    (char)SvIV(hval);
    sysoutname __sysoutname = SvPV(hval,len);
    member     __member =    SvPV(hval,len);
    status     __status =    (char)SvIV(hval);
    normdisp   __normdisp =  (char)SvIV(hval);
    conddisp   __conddisp =  (char)SvIV(hval);
    unit       __unit =      SvPV(hval,len);
    volser     __volser =    SvPV(hval,len);
    dsorg      __dsorg =     (short)SvIV(hval);
    alcunit    __alcunit =   (char)SvIV(hval);
    primary    __primary =   SvIV(hval);
    secondary  __secondary = SvIV(hval);
    dirblk     __dirblk =    SvIV(hval);
    avgblk     __avgblk =    SvIV(hval);
    recfm      __recfm  =    (short)SvIV(hval);
    blksize    __blksize =   (short)SvIV(hval);
    lrecl      __lrecl =     (unsigned short)SvIV(hval);
    volrefds   __volrefds =  SvPV(hval,len);
    dcbrefds   __dcbrefds =  SvPV(hval,len);
    dcbrefdd   __dcbrefdd =  SvPV(hval,len);
    misc_flags __misc_flags = (unsigned char)SvIV(hval);
    password   __password =  SvPV(hval,len);
    miscitems  __miscitems = (char **)SvPV(hval,len);
    infocode   __infocode =  (short)SvIV(hval);
    errcode    __errcode =   (short)SvIV(hval);
    storclass  __storclass = SvPV(hval,len);
    mgntclass  __mgntclass = SvPV(hval,len);
    dataclass  __dataclass = SvPV(hval,len);
    recorg     __recorg =    (char)SvIV(hval);
    keyoffset  __keyoffset = (short)SvIV(hval);
    keylength  __keylength = (short)SvIV(hval);
    refdd      __refdd =     SvPV(hval,len);
    like       __like =      SvPV(hval,len);
    dsntype    __dsntype =   (char)SvIV(hval);
    pathname   __pathname =  SvPV(hval,len);
    pathopts   __pathopts =  SvIV(hval);
    pathmode   __pathmode =  SvIV(hval);
    pathndisp  __pathndisp = (char)SvIV(hval);
    pathcdisp  __pathcdisp = (char)SvIV(hval);

See also the B<C/C++ Run-Time Library Reference> for information on 
C<dynalloc()> and C<__dyn_t>.  See also C<svc99>.

=item dynfree HASHREF

Deallocates a data set via the C RTL C<dynfree()> routine.  Returns a 
true value on success, undef on failure.  For information
on the form of the HASHREF see C<dynalloc>.  Note that the only __dyn_t
struct members that are used by the underlying dynfree() rotuine are:

    ddname
    dsname
    member
    pathname
    normdisp
    pathndisp
    miscitems

See also C<svc99>.

=item flush EXPR

This function causes the contents of stdio buffers for the specified
data set handle to be flushed.  If C<undef> is used as the argument to
C<flush>, all currently open data set handles are flushed.  Like the CRTL
fflush() routine, the buffering mode and file type can have an effect on
when output data is flushed.  C<flush> returns a true value if successful, 
and C<undef> if not.

=item forward DSH

C<forward> resets the current position of the specified data set handle
to the end of the data set.  It's really just a convenience
method equivalent in effect to C<fseek($fh,0L,SEEK_END)>.  It returns a
true value if successful, and C<undef> if it fails.  See also 
C<rewind> and C<resetpos>.

=item get_dcb NAME

=item get_dcb DSH

This function retrieves the data control block information for the data set 
name or the data set handle passed to it and returns it in a hash with keys 
approximated by the names of the elements of the C<fldata_t> struct (see the 
documentaton for the C<fldata()> C RTL routine for further information).

For example:

    use OS390::Stdio qw(get_dcb);
    my %slate_dcb = get_dcb("//SEDIMENT.SLATE");
    for (sort(keys(%slate_dcb))) {
        print "$_ = $slate_dcb{$_}\n";
    }

For an example using the older data set handle mechanism:

    use OS390::Stdio qw(mvsopen get_dcb);
    my $dshandle = mvsopen("//SEDIMENT.SLATE","r");
    my %slate_dcb = get_dcb($dshandle);
    close($dshandle);
    for (sort(keys(%slate_dcb))) {
        print "$_ = $slate_dcb{$_}\n";
    }

For the inverse (i.e. setting data set attributes) use appropriate 
arguments with either C<mvsopen>, C<dynalloc>, or C<svc99>.  For just 
the filename you can use C<getname> in place of C<get_dcb>.

=item getname NAME

=item getname DSH

The C<getname> function returns the full data set filename associated
either with the given name or with a supplied Perl I/O handle 
(via C<fldata()>).  If an error occurs, it returns C<undef>.

As an example consider:

    $fullname = getname("//FOO.BAR");
    $hlq = $fullname;
    $hlq =~ s/\'([^\.]+)\..*/$1/;  # strip leading ' and trailing DS names
    print "The high level qualifier (HLQ) is $hlq\n";

The version of that previous example carried out with a Data Set Handle
might appear as:

    $dshandle = mvsopen("//FOO.BAR","r");
    $fullname = getname($dshandle);
    $hlq = $fullname;
    $hlq =~ s/\'([^\.]+)\..*/$1/;  # strip leading ' and trailing DS names
    print "The high level qualifier (HLQ) is $hlq\n";

or, assuming you are authorized to do so, in order to switch 
to a different HLQ:

    $mydshandle = mvsopen("//FOO.BAR","r");
    $myfullname = getname($mydshandle);
    $bobsuid = '214';
    setuid($bobsuid);
    $bobsdshandle = mvsopen("//FOO.BAR","r");
    $bobsfullname = getname($bobsdshandle);
    $bobshlq = $bobsfullname;
    $bobshlq =~ s/\'([^\.]+)\..*/$1/;
    print "Bob's pwname is ",(getpwuid($<))[0],"\n";
    print "Bob's high level qualifier (HLQ) is $bobshlq\n";

Note that both of these examples assume that UIDs map directly to 
profile prefixes, whereas they may not in general.  To obtain more
extensive information for a given data set handle see C<get_dcb>.

=item mvsopen NAME MODE

The C<mvsopen> function enables you to specify optional arguments
to the CRTL when opening a data set.  Its operation is similar to the 
built-in Perl C<open> function (see L<perlfunc> for a complete description),
but it will only open normal data sets; it cannot open pipes or duplicate
existing I/O handles.  The C<MODE> is typically taken from:

    qw(r w a r+ w+ a+ rb wb ab rt wt at rb+ wb+ ab+ rt+ wt+ at+)

Additional C<MODE> keyword parameters can be passed from:

    qw(acc= blksize= byteseek lrecl= recfm= type= asis password= noseek)

(See the B<C/C++ MVS Programming Guide> and the 
B<C/C++ Run-Time Library Reference> descriptions of C<fopen()> for detailed 
information on C<NAME> and C<MODE> arguments.)  If successful, C<mvsopen> 
returns a data set handle; if an error occurs, it returns C<undef>.

You can use the data set handle returned by C<mvsopen> just as you
would any other Perl file handle.  The class OS390::Stdio ISA
IO::File, so you can call IO::File methods using the handle
returned by C<mvsopen>.  However, C<use>ing OS390::Stdio does not
automatically C<use> IO::File; you must do so explicitly in
your program if you want to call IO::File methods.  This is
done to avoid the overhead of initializing the IO::File package
in programs which intend to use the handle returned by C<mvsopen>
as a normal Perl data set handle only.  When the scalar containing
a OS390::Stdio data set handle is overwritten, C<undef>d, or goes
out of scope, the associated data set is closed automatically.

=item mvswrite DSH EXPR LEN

The C<mvswrite> function provides access to stdio's C<fwrite()> function.
For example:

    use OS390::Stdio qw(mvsopen mvswrite);
    my $dshandle = mvsopen("//BED.ROCK","w+");
    my $fred,$data,$chrs_written;
    $fred = 100.00;
    $data = sprintf("Fred's salary is \$%3.2f",$fred);
    $chrs_written = mvswrite($dshandle,$data,length($data));
    close($dshandle);

=item pds_mem NAME

=item pds_mem NAME, FLAG

Returns a list of members for the named PDS directory.  Alias names 
may be returned depending on the value of the optional 
FLAG argument:

    FLAG   pds_mem() returns
           member names (if any) - this is the default
    0      member names (if any)
    1      alias names only (if there are any)
    2      member and alias names (if any) 

A list with a single C<undef> element is returned for PDS directories that 
have no members as well as for data set names that are not partitioned (in
the latter case a warning may appear on STDERR depending on how 
OS390::Stdio was compiled on your system).
For example:

    use OS390::Stdio qw(pds_mem);
    my @member_list = pds_mem("//'SLATE.PDS'");
    print " Members that are not aliases are:\n";
    foreach my $mem (@member_list) {
        print "SLATE.PDS($mem)\n";
    }
    print " Aliases are:\n";
    my @alias_list = pds_mem("//'SLATE.PDS'",1);
    foreach my $alias (@alias_list) {
        print "SLATE.PDS($alias)\n";
    }

=item remove NAME

This function deletes the data set (member) named in its argument, 
returning a true value if successful and C<undef> if not.  It differs 
from the CORE Perl function C<unlink> in that it does not try to
reset DS access if you are not authorized to delete the data set.

=item resetpos DSH

C<resetpos> resets the current position of the specified data set handle
to the current position.  This is useful for switching between input
and output at a given location.  It's really just a convenience
method equivalent in effect to C<fseek($fh,0L,SEEK_CUR)>.  It returns a
true value if successful, and C<undef> if it fails.  See also 
C<forward> and C<rewind> or Perl's builtin C<seek>.  (This was not 
called setpos to avoid namespace collision).

=item rewind DSH

C<rewind> resets the current position of the specified data set handle
to the beginning of the data set.  It's really just a convenience
method equivalent in effect to C<seek($fh,0,0)>.  It returns a
true value if successful, and C<undef> if it fails.  See also 
C<forward> and C<resetpos>.

=item smf_record TYPE SUBTYPE RECORD

If the System Management Facility is running and the BPX.SMF facility
does not exclude writing the type of record that you want then you
may use C<smf_record>.  For example:

    use OS390::Stdio ('smf_record');
    if ( smf_record($type,$sub_type,$record) ) {
        print "record successfully recorded with SMF\n";
    }
        warn "a problem recording with SMF was encountered";
    }

=item sysdsnr NAME

Returns true if the named data set is available to C<fopen()> in "r" mode.
Note that perl's built in C<stat()> function as well as the various 
file test operators such as C<-r> do not work with OS data sets, but 
that C<sysdsnr> will.

=item svc99 HASHREF

This function provides access to the SVC 99 system service via a
C RTL C<svc99()> call.  Returns a true value on success, undef 
on failure.

The hashref to be passed to svc99 may contain keys with names 
derived from the __S99struc member names with the two leading 
underscores removed.  For example:

While most of the hash values can be integers ((cast)SvIV below),
S99S99X can be a character string, and the S99TXTPP key must have 
a value that is an array reference pointing to an array of 
specially formatted "text units":

    Perl      C __S99struc Perl -> C
    S99VERB   .__S99VERB   (unsigned char)SvIV(hval)
    S99FLAG1  .__S99FLAG1  (unsigned short)SvIV(hval)
    S99FLAG2  .__S99FLAG2  (unsigned short)SvIV(hval)
    S99RBLN   .__S99RBLN   (unsigned char)SvIV(hval)
    S99S99X   .__S99S99X   (void * )SvPV(hval,len)
    S99TXTPP  .__S99TXTPP  [array reference]

Note that S99FLAG2 can only be set by perl programs that are APF
authorized.  See also the B<C/C++ Run-Time Library Reference> for
information on C<svc99()>.

=item tmpnam

The C<tmpnam> function returns a unique string which can be used
as an HFS (POSIX) data set name when creating temporary storage.  
If, for some reason, it is unable to generate a name, it returns 
C<undef>.  Note that in order to ensure the creation of an OS data
set try using C<mvsopen> with a data set name of the form C<//&&name>.

=item vsamdelrec DSH

Deletes a record from a VSAM data set via the C RTL C<fdelrec()> routine.
You must C<seek> to the proper record before invoking vsamdelrec of course.
See also C<mvsopen>, C<vsamlocate>, and C<vsamupdate>.

=item vsamlocate DSH, key, key_len, options

Locates a record in a VSAM data set via the C RTL C<flocate()> routine.
See also C<mvsopen>, C<vsamdelrec>, and C<vsamupdate>.

=item vsamupdate DSH, record, length

Updates a record in a VSAM data set via the C RTL C<fupdate()> routine.
See also C<mvsopen>, C<vsamdelrec>, and C<vsamlocate>.

=back

The following functions are experimental.  Some are not currently 
working and either produce fatal errors or simply do not work as 
intended.

=over

=item dsname_level

This function returns a ds list for a given HLQ plus optional additional 
qualifiers.  It returns C<undef> if it encounters an error.  (The name 
was taken from the ISPF 3.4 panel entry).  See also C<vol_ser>.

V 0.003..0.007: This routine is not yet implemented and causes a fatal error.

Until this is working properly you can from perl code things such as:

    @listcat = `tso listcat`;

=item vol_ser 

Returns a dslist for a given volume serial input.   (The name was taken
from the ISPF 3.4 panel entry).

V 0.003..0.007: This routine is not yet implemented and causes a fatal error.

=back

=head1 DIAGNOSTICS

The following messages may be seen when programming with this
extension:

=over 4

=item Data set %s [filename %s] does not appear to be a PDS directory.

Seen during a call to pds_mem() if the named data set does not have the
__dsorgPDSdir organization and if the module was compiled without 
-DNO_WARN_IF_NOT_PDS.

Try calling pds_mem() with the name of a PDS or re-install this module
being sure to specify -DNO_WARN_IF_NOT_PDS duruing the build process.

=item fopen(%s) returned NULL.

The initial attempt to read the data set from pds_mem() did not return a valid
FILE * pointer.  Perhaps the name that you gave to pds_mem() was not a valid
data set name?

=item fread(): failed in %s, line %d Expected to read %d bytes but read %d bytes

An error occurred while attempting to fread() a PDS.

=item EFREAD

An fatal error occurred while attempting to fread() a PDS.

=item malloc failed for %d bytes

An error occurred while attempting to malloc() space for a PDS member name.

=item ENONMEM

An error occurred while attempting to malloc() space for a PDS member name.

=item too many args

Seen if an attempt to call pds_mem() with more than 2 arguments
is made.  pds_mem() ought to be called with a PDS name and an
optional integer.  Try reducing the list of items passed to
pds_mem() to one or two.

=item alias flag must be an integer

Seen if the optional second argument passed to pds_mem() is
not an integer.  Try using an integer expression that evaluates
to 0 or 1 or 2 instead.

=item dynalloc() requires a hash reference

=item dynalloc() called with undefined value.

=item dynalloc() failed with error code %hX, info code %hX

=item dynalloc() unable to initialize struct __dyn_t

=item dynfree() requires a hash reference

=item dynfree() called with undefined value.

=item dynfree() failed with error code %hX, info code %hX

=item dynfree() unable to initialize struct __dyn_t

=item h2dyn_t warning key '%s' not recognized.

You tried calling dynalloc() or dynfree() with a hash ref, one of
whose keys was not a recognized part of the __dyn_t struct.

=item smf_record() value specified of length '%d' was incorrect

An internal error was encountered in smf_record.  Contact the author.

=item smf_record() not enough storage to complete __smf_record() call

A system diagnostic.  Try to allocate more storage.

=item smf_record() The calling process is not permitted access to the BPX.SMF facility class

Contact your system administrator about the BPX.SMF facility.

=item smf_record() The SMF service returned '%d', __errno2 = %08x

An error was encountered in calling __smf_record().

=item smf_record() The SMF service returned '%d'

An error was encountered in calling __smf_record().

=item svc99() requires a hash reference

Be sure to pass a hash reference to svc99().

=item  svc99() called with undefined value.

Be sure to pass a hash reference to svc99().

=item value of S99TXTPP was not a reference.

Be sure that the 'S99TXTPP' key of the hash reference passed to svc99()
points to a value that is an array reference.

=item array reference passed into S99TXTPP too large, %d elements.

Trim down the size of the 'S99TXTPP' referenced array or up the 
value of the OS390_STDIO_SVC99_TEXT_UNITS constant and re-install 
the extensions (please contact the author if you find this necessary).

=item svc99() warning key '%s' not recognized.

Pass a hash reference to svc99() that contains only recognized keys.

=item svc99() failed with error code %hX, info code %hX

The internal call to the C run time svc99() failed for the indicated
reasons (in hex).

=item svc99() unable to initialize struct __S99parms

A problem was encountered with the argument passed to svc99().

=item %s not yet implemented

Seen if an attempt to call an unfinished sub routine is made.
dsname_level() and vol_ser() are not yet implemented.

=back

=head1 REVISION

This document was last revised on 31-August-2002, for Perl 5.8.0.

13-June-2001, VERSION 0.006 for Perl 5.6.1.

18-May-2001, VERSION 0.005 for Perl 5.6.1.

14-Apr-2001, VERSION 0.004 for Perl 5.6.1.

13-Apr-1999, VERSION 0.003 for Perl 5.005_03.

31-Aug-1998, VERSION 0.002 for Perl 5.005_02.

=cut
