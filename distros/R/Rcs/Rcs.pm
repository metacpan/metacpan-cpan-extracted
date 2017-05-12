package Rcs;
require 5.002;
use strict;
use Exporter;
use Carp;
use Time::Local;
use vars qw($VERSION $revision);
use subs qw(_rcsError);

# Even though I don't really export anything, I use Exporter
# to look for 'nonFatal' 'Verbose' tags.
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(nonFatal Verbose);

#------------------------------------------------------------------
# global stuff
#------------------------------------------------------------------
$VERSION = '1.05';
$revision = '$Id: Rcs.pm,v 1.28 2003/12/12 00:53:34 freter Exp $';
my $Dir_Sep = ($^O eq 'MSWin32') ? '\\' : '/';
my $Exe_Ext = ($^O eq 'MSWin32') ? '.exe' : '';
my $Rcs_Bin_Dir = '/usr/local/bin';
my $Rcs_Dir = '.' . $Dir_Sep . 'RCS';
my $Work_Dir = '.';
my $Quiet = 1;       # RCS quiet mode
my $nonFatal = 0;    # default to fatal
my $Arc_Ext = ',v';

#------------------------------------------------------------------
# RCS object constructor
#------------------------------------------------------------------
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

    # provide default values for system stuff
    $self->{"_BINDIR"}  = \$Rcs_Bin_Dir;
    $self->{"_QUIET"}   = \$Quiet;
    $self->{"_RCSDIR"}  = \$Rcs_Dir;
    $self->{"_WORKDIR"} = \$Work_Dir;
    $self->{"_ARCEXT"}  = \$Arc_Ext;

    $self->{FILE}       = undef;
    $self->{ARCFILE}    = undef;
    $self->{AUTHOR}     = undef;
    $self->{COMMENTS}   = undef;
    $self->{DATE}       = undef;
    $self->{LOCK}       = undef;
    $self->{ACCESS}     = [];
    $self->{REVISIONS}  = [];
    $self->{REVINFO}    = undef;
    $self->{STATE}      = undef;
    $self->{SYMBOLS}    = undef;
    bless($self, $class);

    # Allow user to pass archive file to object constructor
    # Example: Rcs->new('RCS/diskio.c,v')
    if (@_) {
        $self->pathname(shift);
    }

    return $self;
}

#------------------------------------------------------------------
# Use import function to check for 'nonFatal' Tag.
#------------------------------------------------------------------
sub import {
    my $pkg = shift;
    $nonFatal = 1 if scalar grep /^nonFatal$/, @_;
    $Quiet    = 0 if scalar grep /^Verbose$/,  @_;
}

#------------------------------------------------------------------
# access
# Access list of archive file.
#------------------------------------------------------------------
sub access {
    my $self = shift;

    if (not @{ $self->{ACCESS} }) {
        _parse_rcs_header($self);
    }

    # dereference revisions list
    my @access = @{ $self->{ACCESS} };

    return @access;
}

#------------------------------------------------------------------
# arcext
# Set the RCS archive file extension (default is ',v').
#------------------------------------------------------------------
sub arcext {
    my $self = shift;

    # called as object method
    if (ref $self) {
        if (@_) { $self->{"_ARCEXT"} = shift };
        return ref $self->{"_ARCEXT"} ? ${ $self->{"_ARCEXT"} } : $self->{"_ARCEXT"};
    }

    # called as class method
    else {
        if (@_) { $Arc_Ext = shift; }
        return $Arc_Ext;
    }
}

#------------------------------------------------------------------
# arcfile
# Name of RCS archive file.
# If not set then return name of working file with RCS
# extension (',v').
#------------------------------------------------------------------
sub arcfile {
    my $self = shift;
    if (@_) { $self->{ARCFILE} = shift }
    return $self->{ARCFILE} || $self->file . $self->arcext;
}

#------------------------------------------------------------------
# author
# Return the author of an RCS revision.
# If revision is not provided, default to 'head' revision.
#------------------------------------------------------------------
sub author {
    my $self = shift;

    if (not defined $self->{AUTHOR}) {
        _parse_rcs_header($self);
    }
    my $revision = shift || $self->head;

    # dereference author hash
    my %author_array = %{ $self->{AUTHOR} };

    return $author_array{$revision};
}

#------------------------------------------------------------------
# bindir
# Set the bin directory in which the RCS distribution programs
# reside.
#------------------------------------------------------------------
sub bindir {
    my $self = shift;

    # called as object method
    if (ref $self) {
        if (@_) { $self->{"_BINDIR"} = shift };
        return ref $self->{"_BINDIR"} ? ${ $self->{"_BINDIR"} } : $self->{"_BINDIR"};
    }

    # called as class method
    else {
        if (@_) { $Rcs_Bin_Dir = shift };
        return $Rcs_Bin_Dir;
    }
}

#------------------------------------------------------------------
# ci
# Execute RCS 'ci' program.
# Make archive filename same as working filename unless
# specifically set.
#------------------------------------------------------------------
sub ci {
    my $self = shift;
    my @param = @_;

    my $ciprog = $self->bindir . $Dir_Sep . 'ci' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $workdir = $self->workdir;
    my $file = $self->file;
    my $arcfile = $self->arcfile;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    my $workfile = $workdir . $Dir_Sep . $file;
    push @param, $archive_file, $workfile;
    unshift @param, "-q" if $self->quiet;     # quiet mode

    # run program
    return(_rcsError "ci program $ciprog not found")      unless -e $ciprog;
    return(_rcsError "ci program $ciprog not executable") unless -x $ciprog;
    system($ciprog, @param) == 0 or return(_rcsError "$?");

    # re-parse RCS file and clear comments hash
    _parse_rcs_header($self);
    $self->{COMMENTS} = undef;
    return 1;
}

#------------------------------------------------------------------
# co
# Execute RCS 'co' program.
# Make archive filename same as working filename unless
# specifically set.
#------------------------------------------------------------------
sub co {
    my $self = shift;
    my @param = @_;

    my $coprog = $self->bindir . $Dir_Sep . 'co' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $workdir = $self->workdir;
    my $file = $self->file;
    my $arcfile = $self->arcfile;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    my $workfile = $workdir . $Dir_Sep . $file;
    push @param, $archive_file, $workfile;
    unshift @param, "-q" if $self->quiet;     # quiet mode

    # run program
    return(_rcsError "co program $coprog not found") unless -e $coprog;
    return(_rcsError "co program $coprog not executable") unless -x $coprog;
    system($coprog, @param) == 0 or return(_rcsError "$?");

    # re-parse RCS file and clear comments hash
    _parse_rcs_header($self);
    $self->{COMMENTS} = undef;
    return 1;
}

#------------------------------------------------------------------
# comments
#------------------------------------------------------------------
sub comments {
    my $self = shift;

    if (not defined $self->{COMMENTS}) {
        _parse_rcs_body($self);
    }

    return %{$self->{COMMENTS}};
}

#------------------------------------------------------------------
# daterev
#
# Returns revisions which were created before a specified date.
#
# Method takes one or six arguments.
#
# If one argument, then argument is date number.
#
# If six arguments, then year (4 digit year), month (1-12), day
# of month (1-31), hour (0-23), minute (0-59) and second (0-59).
#------------------------------------------------------------------
sub daterev {

    my $self = shift;
    my $target_time;

    # validate arguments
    unless (@_ == 1 or @_ == 6) {
        croak "daterev must have either 1 or 6 arguments";
    }

    # string date passed
    if (@_ == 6) {
        my($year, $mon, $mday, $hour, $min, $sec) = @_;

        if($year !~ /^\d{4}$/) {
            croak "year (1st param) must be 4 digit number";
        }

        $mon--;        # convert to 0-11 range
        $target_time = timegm($sec, $min, $hour, $mday, $mon, $year);
    }

    # system date passed
    else {
        $target_time = shift;

        if ($target_time !~ /^\d+$/) {
            croak "system date must be an integer";
        }
    }

    if (not defined $self->{DATE}) {
        _parse_rcs_header($self);
    }

    my @revisions = ();
    my %dates;
    my %dates_hash = %{$self->{DATE}};

    my $revision;
    foreach $revision (keys %dates_hash) {
        my $date = $dates_hash{$revision};
        $dates{$date}{$revision} = 1;
    }

    my $date;
    foreach $date (reverse sort keys %dates) {
        foreach $revision (keys %{ $dates{$date} }) {
            push @revisions, $revision if $date <= $target_time;
        }
    }

    return wantarray ? @revisions : $revisions[0];
}

#------------------------------------------------------------------
# dates
# Return a hash of revision dates, keyed on revision, when called
# in list mode.
# Return the most recent date when called in scalar mode.
#
# RCS stores dates in GMT.
# The date values are system dates.
#------------------------------------------------------------------
sub dates {
    my $self = shift;

    if (not defined $self->{DATE}) {
        _parse_rcs_header($self);
    }

    my %DatesHash = %{$self->{DATE}};
    my @dates_list = sort {$b<=>$a} values %DatesHash;
    my $MostRecent = $dates_list[0];

    return wantarray ? %DatesHash : $MostRecent;
}

#------------------------------------------------------------------
# file
# Name of working file.
#------------------------------------------------------------------
sub file {
    my $self = shift;
    if (@_) { $self->{FILE} = shift }
    return $self->{FILE};
}

#------------------------------------------------------------------
# pathname
# Full name of working file, including path to it and RCS file extension.
# Sets the location of 'RCS' archive directory.
#------------------------------------------------------------------
sub pathname {

    my $self = shift;

    if (@_) {
        my $filename = shift;
        if ($filename =~ m/(.*)$Dir_Sep(.*)/) {
            $self->rcsdir($1);
            $filename = $2;
        }
        else {
            $self->rcsdir('.');
        }

        # Strip off archive extension if exists
        my $arcext = $self->arcext;
        $filename =~ s/$arcext$//;

        $self->file($filename);
    }
    return $self->rcsdir . $Dir_Sep . $self->file;
}

#------------------------------------------------------------------
# head
# Return the head revision.
#------------------------------------------------------------------
sub head {
    my $self = shift;

    if (not defined $self->{HEAD}) {
        _parse_rcs_header($self);
    }
    return $self->{HEAD};
}

#------------------------------------------------------------------
# lock
# Return user who has file locked.
#------------------------------------------------------------------
sub lock {
    my $self = shift;

    if (not defined $self->{LOCK}) {
        _parse_rcs_header($self);
    }
    my $revision = shift || $self->{HEAD};
    
    return wantarray ? %{ $self->{LOCK} } : ${ $self->{LOCK} }{$revision};
}

#------------------------------------------------------------------
# quiet
# Set or un-set RCS quiet mode.
#------------------------------------------------------------------
sub quiet {
    my $self = shift;

    # called as object method
    if (ref $self) {

        # set/un-set quiet mode
        if (@_) {
            my $mode = shift;
            croak "Passed parameter must be either '0' or '1'"
                unless $mode == 0 or $mode == 1;
            $self->{"_QUIET"} = $mode;
            return ref $self->{"_QUIET"} ? ${ $self->{"_QUIET"} } : $self->{"_QUIET"};
        }

        # access quiet mode
        else {
            return ref $self->{"_QUIET"} ? ${ $self->{"_QUIET"} } : $self->{"_QUIET"};
        }
    }

    # called as class method
    else {

        # set/un-set quiet mode
        if (@_) {
            my $mode = shift;
            croak "Passed parameter must be either '0' or '1'"
                unless $mode == 0 or $mode == 1;
            $Quiet = $mode;
            return $Quiet;
        }

        # access quiet mode
        else {
            return $Quiet;
        }
    }
}

#------------------------------------------------------------------
# rcs
# Execute RCS 'rcs' program.
# Make archive filename same as working filename unless
# specifically set.
#------------------------------------------------------------------
sub rcs {
    my $self = shift;
    my @param = @_;

    my $rcsprog = $self->bindir . $Dir_Sep . 'rcs' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $workdir = $self->workdir;
    my $file = $self->file;
    my $arcfile = $self->arcfile;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    my $workfile = $workdir . $Dir_Sep . $file;
    push @param, $archive_file, $workfile;
    unshift @param, "-q" if $self->quiet;     # quiet mode

    # run program
    return(_rcsError "rcs program $rcsprog not found") unless -e $rcsprog;
    return(_rcsError "rcs program $rcsprog not executable") unless -x $rcsprog;
    system($rcsprog, @param) == 0 or return(_rcsError "$?");

    # re-parse RCS file and clear comments hash
    _parse_rcs_header($self);
    $self->{COMMENTS} = undef;
    return 1;
}

#------------------------------------------------------------------
# rcsclean
# Execute RCS 'rcsclean' program.
#------------------------------------------------------------------
sub rcsclean {
    my $self = shift;
    my @param = @_;

    my $rcscleanprog = $self->bindir . $Dir_Sep . 'rcsclean' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $workdir = $self->workdir;
    my $file = $self->file;
    my $arcfile = $self->arcfile;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    my $workfile = $workdir . $Dir_Sep . $file;
    push @param, $archive_file, $workfile;

    # run program
    return(_rcsError "rcsclean program $rcscleanprog not found") unless -e $rcscleanprog;
    return(_rcsError "rcsclean program $rcscleanprog not executable") unless -x $rcscleanprog;
    system($rcscleanprog, @param) == 0 or return(_rcsError "$?");

    # re-parse RCS file and clear comments hash
    _parse_rcs_header($self);
    $self->{COMMENTS} = undef;
    return 1;
}

#------------------------------------------------------------------
# rcsdiff
# Execute RCS 'rcsdiff' program.
# Calling in list context returns the output of rcsdiff, while
# calling in scalar context returns the return status of the
# rcsdiff program.
#------------------------------------------------------------------
sub rcsdiff {
    my $self = shift;
    my @param = @_;

    my $rcsdiff_prog = $self->bindir . $Dir_Sep . 'rcsdiff' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $arcfile = $self->arcfile;
    $arcfile = $rcsdir . $Dir_Sep . $arcfile;
    my $workfile = $self->workdir . $Dir_Sep . $self->file;

    # un-taint parameter string
    unshift @param, "-q" if $self->quiet;     # quiet mode
    my $param_str = join(' ', @param);
    $param_str =~ s/([\w-]+)/$1/g;

    return(_rcsError "rcsdiff program $rcsdiff_prog not found")
        unless -e $rcsdiff_prog;
    return(_rcsError "rcsdiff program $rcsdiff_prog not executable")
        unless -x $rcsdiff_prog;
    open(DIFF, "$rcsdiff_prog $param_str $arcfile $workfile |")
        or return(_rcsError "Can't fork $rcsdiff_prog: $!");
    my @diff_output = <DIFF>;

    # rcsdiff returns exit status 0 for no differences, 1 for differences,
    # and 2 for error condition.
    close DIFF;
    my $status = $?;
    $status >>= 8;
    return(_rcsError "$rcsdiff_prog failed") if $status == 2;
    return wantarray ? @diff_output : $status;
}

#------------------------------------------------------------------
# rcsdir
# Location of 'RCS' archive directory.
#------------------------------------------------------------------
sub rcsdir {
    my $self = shift;

    # called as object method
    if (ref $self) {
        if (@_) { $self->{"_RCSDIR"} = shift }
        return ref $self->{"_RCSDIR"} ? ${ $self->{"_RCSDIR"} } : $self->{"_RCSDIR"};
    }

    # called as class method
    else {
        if (@_) { $Rcs_Dir = shift }
        return $Rcs_Dir;
    }
}

#------------------------------------------------------------------
# revdate
# Return the revision date of an RCS revision.
# If revision is not provided, default to 'head' revision.
#
# RCS stores dates in GMT.  This method will return dates relative
# to the local time zone.
#------------------------------------------------------------------
sub revdate {
    my $self = shift;

    if (not defined $self->{DATE}) {
        _parse_rcs_header($self);
    }
    my $revision = shift || $self->head;

    # dereference date hash
    my %date_array = %{ $self->{DATE} };
    my $date_str = $date_array{$revision};

    return wantarray ? localtime($date_str) : $date_str;
}

#------------------------------------------------------------------
# revisions
#------------------------------------------------------------------
sub revisions {
    my $self = shift;

    if (not @{ $self->{REVISIONS} }) {
        _parse_rcs_header($self);
    }

    # dereference revisions list
    my @revisions = @{ $self->{REVISIONS} };

    @revisions;
}

#------------------------------------------------------------------
# rlog
# Execute RCS 'rlog' program.
# Make archive filename same as working filename unless
# specifically set.
#------------------------------------------------------------------
sub rlog {
    my $self = shift;
    my @param = @_;

    my $rlogprog = $self->bindir . $Dir_Sep . 'rlog' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $arcfile = $self->arcfile || $self->file;

    # un-taint parameter string
    my $param_str = join(' ', @param);
    $param_str =~ s/([\w-]+)/$1/g;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    return(_rcsError "rlog program $rlogprog not found") unless -e $rlogprog;
    return(_rcsError "rlog program $rlogprog not executable") unless -x $rlogprog;
    open(RLOG, "$rlogprog $param_str $archive_file |")
        or return(_rcsError "Can't fork $rlogprog: $!");

    my @logoutput = <RLOG>;
    close RLOG;
    return(_rcsError "$rlogprog failed") if $?;
    @logoutput;
}

#------------------------------------------------------------------
# rcsmerge
# Execute RCS 'rcsmerge' program.
#------------------------------------------------------------------
sub rcsmerge {
    my $self = shift;
    my @param = @_;

    my $rcsmergeprog = $self->bindir . $Dir_Sep . 'rcsmerge' . $Exe_Ext;
    my $rcsdir = $self->rcsdir;
    my $arcfile = $self->arcfile || $self->file;

    # un-taint parameter string
    my $param_str = join(' ', @param);
    $param_str =~ s/([\w-]+)/$1/g;

    my $archive_file = $rcsdir . $Dir_Sep . $arcfile;
    return(_rcsError "rcsmerge program $rcsmergeprog not found") unless -e $rcsmergeprog;
    return(_rcsError "rcsmerge program $rcsmergeprog not executable") unless -x $rcsmergeprog;
    open(RCSMERGE, "$rcsmergeprog $param_str $archive_file |")
        or return(_rcsError "Can't fork $rcsmergeprog $!");

    my @logoutput = <RCSMERGE>;
    close RCSMERGE;
    return(_rcsError "$rcsmergeprog failed") if $?;
    @logoutput;
}

#------------------------------------------------------------------
# state
# If revision is not provided, default to 'head' revision
#------------------------------------------------------------------
sub state {
    my $self = shift;

    if (not defined $self->{STATE}) {
        _parse_rcs_header($self);
    }
    my $revision = shift || $self->head;

    # dereference author hash
    my %state_array = %{ $self->{STATE} };

    return $state_array{$revision};
}

#------------------------------------------------------------------
# symbol
# Return symbol(s) based on revision.
#------------------------------------------------------------------
sub symbol {
    my $self = shift;

    my $sym;
    my @sym_array;

    if (not defined $self->{SYMBOLS}) {
        _parse_rcs_header($self);
    }
    my $revision = shift || $self->head;

    # dereference symbols hash
    my %symbols = %{ $self->{SYMBOLS} };

    foreach $sym (keys %symbols) {
        my $rev = $symbols{$sym};
        push @sym_array, $sym if $rev eq $revision;
    }

    # return only first array element if user wants scalar
    return wantarray ? @sym_array : $sym_array[0];
}

#------------------------------------------------------------------
# symbols
# Returns hash of all revisions keyed on symbol defined against file.
#------------------------------------------------------------------
sub symbols {
    my $self = shift;

    if(not defined $self->{SYMBOLS}) {
        _parse_rcs_header($self);
    }

    return %{$self->{SYMBOLS}};
}

#------------------------------------------------------------------
# symrev
# Returns the revision against which a specified symbol was
# defined. If the symbol was not defined against any version
# of this file, 0 is returned.
#------------------------------------------------------------------
sub symrev {
    my $self = shift;
    my $sym = shift or croak "You must supply a symbol to symrev";;

    if (not defined $self->{SYMBOLS}) {
        _parse_rcs_header($self);
    }

    my %symbols = %{ $self->{SYMBOLS} };
    my $revision = $symbols{$sym} ? $symbols{$sym} : 0;

    my %matched_symbols = map { $_ => $symbols{$_} } grep(/$sym/, keys %symbols);

    return wantarray ? %matched_symbols : $revision;
}

#------------------------------------------------------------------
# workdir
# Location of working directory.
#------------------------------------------------------------------
sub workdir {
    my $self = shift;

    # called as object method
    if (ref $self) {
        if (@_) { $self->{"_WORKDIR"} = shift }
        return ref $self->{"_WORKDIR"} ? ${ $self->{"_WORKDIR"} } : $self->{"_WORKDIR"};
    }

    # called as class method
    else {
        if (@_) { $Work_Dir = shift }
        return $Work_Dir;
    }
}

#------------------------------------------------------------------
# _parse_rcs_body
# Private function
#------------------------------------------------------------------
sub _parse_rcs_body {

    my $self = shift;
    local $_;

    my %comments;

    my $rcsdir = $self->rcsdir;
    my $file = $self->file;
    my $rcs_file = $rcsdir . $Dir_Sep . $file . $self->arcext;

    # parse RCS archive file
    open RCS_FILE, $rcs_file
        or return(_rcsError "Unable to open $rcs_file: $!");

    # skip header info and get description
    DESC: while (<RCS_FILE>) {
        if (/^desc$/) {
            $comments{0} = '';
            $_ = <RCS_FILE>;      # read first line
            s/^\@//;              # remove leading '@'
            while (1) {
                last DESC if /^\@$/;
                s/\@\@/\@/g;      # RCS replaces single '@' with '@@'
                $comments{0} .= $_;
                $_ = <RCS_FILE>;
            }
        }
    }

    # parse revision comments
    my $revision;
    REVISION: while (<RCS_FILE>) {
        if (/^[\d\.]+$/) {
            chomp($revision = $_);
            $_ = <RCS_FILE>;
            if (/^log$/) {
                $comments{$revision} = '';
                $_ = <RCS_FILE>;  # read first line
                s/^\@//;          # remove leading '@'
                while (1) {
                    next REVISION if /^\@$/;
                    s/\@\@/\@/g;  # RCS replaces single '@' with '@@'
                    $comments{$revision} .= $_;
                    $_ = <RCS_FILE>;
                }
            }
        }
    }

    # loop through 'text' section to avoid capturing bogus info
    continue {
        if (/^text$/) {  # 'text' tag should always be there, but check anyway
            $_ = <RCS_FILE>;         # read first line
            if (not /^\@\@$/) {      # forced revisions have single '@@' in text section
                while (<RCS_FILE>) {
                    s/\@\@//g;       # RCS replaces single '@' with '@@'
                    last if /\@$/
                }
            }
        }
    }

    close RCS_FILE;
    $self->{COMMENTS} = \%comments;
}

#------------------------------------------------------------------
# _parse_rcs_header
# Private function
# Directly parse the RCS archive file.
#------------------------------------------------------------------
sub _parse_rcs_header {

    my $self = shift;
    local $_;

    my ($head, %lock);
    my (@access_list, @revisions);
    my (%author, %date, %state, %symbols);

    my $rcsdir = $self->rcsdir;
    my $file = $self->file;
    my $rcs_file = $rcsdir . $Dir_Sep . $file . $self->arcext;

    # parse RCS archive file
    open RCS_FILE, $rcs_file
        or return(_rcsError "Unable to open $rcs_file: $!");
    while (<RCS_FILE>) {
        next if /^\s*$/;    # skip blank lines
        last if /^desc$/;   # end of header info

        # get head revision
        if (/^head\s/) {
            ($head) = /^head\s+(.*?);$/;
            next;
        }

        # get access list
        if (/^access$/) {
            while (<RCS_FILE>) {
                chomp;
                s/\s//g;        # remove all whitespace
                push @access_list, (split(/;/))[0];
                last if /;$/;
            }
            next;
        }

        # get symbols
        if (/^symbols$/) {
            while (<RCS_FILE>) {
                chomp;
                s/\s//g;        # remove all whitespace
                my ($sym, $rev) = split(/:/);
                $rev =~ s/;$//;
                $symbols{$sym} = $rev;
                last if /;$/;
            }
            next;
        }

        # get locker
        if (/^locks/) {

            # file not locked
            if (/;$/) {
                %lock = ();
                next;
            }

            # get user who has file locked
            while(<RCS_FILE>) {
                s/\s+//g;          # remove all white space
                next unless $_ ;   # skip blank line (now empty string)
                last if /^;/;      # end of locks
                my ($locker, $rev) = split(/:/);
                $rev =~ s/;.*//;
                $lock{$rev} = $locker;
                last if /;$/;      # end of locks
            }
            next;
        }

        # get all revisions
        if (/^\d+\.\d+/) {
            chomp;
            push @revisions, $_;

            # get author, state and date of each revision
            my $next_line = <RCS_FILE>;
            chop(my $author = (split(/\s+/, $next_line))[3]);
            chop(my $state  = (split(/\s+/, $next_line))[5]);
            chop(my $date   = (split(/\s+/, $next_line))[1]);

            # store date as date number
            my ($year, $mon, $mday, $hour, $min, $sec) = split(/\./, $date);
            $mon--;        # convert to 0-11 range
            my @date = ($sec,$min,$hour,$mday,$mon,$year);

            # store value in hash using revision as key
            $author{$_} = $author;
            $state{$_} =  $state;
            $date{$_} =   timegm(@date);
        }
    }
    close RCS_FILE;

    $self->{HEAD}        = $head;
    $self->{LOCK}        = \%lock;
    $self->{ACCESS}      = \@access_list;
    $self->{REVISIONS}   = \@revisions;
    $self->{AUTHOR}      = \%author;
    $self->{DATE}        = \%date;
    $self->{STATE}       = \%state;
    $self->{SYMBOLS}     = \%symbols;
}

#------------------------------------------------------------------
# _rcsError
#------------------------------------------------------------------
sub _rcsError {
    my $error_msg = shift;

    not $nonFatal             and croak $error_msg;
    $nonFatal and not $Quiet  and carp $error_msg and return 0;
    $nonFatal and $Quiet      and return 0;
}

1;

__END__

=head1 NAME

Rcs - Perl Object Class for Revision Control System (RCS).

=head1 SYNOPSIS

    use Rcs;

    # Use tags to control how the rcs programs handle errors
    # and the use of the rcs -q (quiet) flag.
    use Rcs qw(nonFatal Verbose);

The default behavior is to run rcs programs with the -q (quiet) flag,
and to die if any rcs program returns an error.

=head1 DESCRIPTION

This Perl module provides an object oriented interface to access 
B<Revision Control System (RCS)> utilities.  RCS must be installed on
the system prior to using this module.  This module should simplify
the creation of an RCS front-end.

=head2 OBJECT CONSTRUCTOR

The B<new> method may be used as either a class method or an object
method to create a new object.

    # called as class method
    $obj = Rcs->new;

    # called as object method
    $newobj = $obj->new;

Note: You may now set the pathname of the working file through the object
constructor.  This is the same as calling the pathname method after
calling the new method.

Thus

    $obj = Rcs->new($pathname);

is the same as

    $obj = Rcs->new;
    $obj->pathname($pathname);

See B<pathname> method for additional details.

=head2 CLASS METHODS

Besides the object constructor, there are three class methods provided
which effect any newly created objects.

The B<arcext> method sets the RCS archive extension, which is ',v' by
default.

    # set/unset RCS archive extension
    Rcs->arcext('');            # set no archive extension
    Rcs->arcext(',v');          # set archive extension to ',v'
    $arc_ext = Rcs->arcext();   # get current archive extension

The B<bindir> method sets the directory path where the RCS executables
(i.e. rcs, ci, co) are located.  The default location is '/usr/local/bin'.

    # set RCS bin directory
    Rcs->bindir('/usr/bin');

    # access RCS bin directory
    $bin_dir = Rcs->bindir;

The B<quiet> method sets/unsets the quiet mode for the RCS executables.
Quiet mode is set by default.

    # set/unset RCS quiet mode
    Rcs->quiet(0);      # unset quiet mode
    Rcs->quiet(1);      # set quiet mode

    # access RCS quiet mode
    $quiet_mode = Rcs->quiet;

These methods may also be called as object methods.

    $obj->arcext('');
    $obj->bindir('/usr/bin');
    $obj->quiet(0);

=head2 OBJECT ATTRIBUTE METHODS

These methods set the attributes of the RCS object.

The B<file> method is used to set the name of the RCS working file.  The
filename must be set before invoking any access of modifier methods on the
object.

    $obj->file('mr_anderson.pl');

The B<arcfile> method is used to set the name of the RCS archive file.
Using this method is optional, as the other methods will assume the archive
filename is the same as the working file unless specified otherwise.  The
RCS archive extension (default ',v') is automatically added to the filename.

    $obj->arcfile('principle_mcvicker.pl');

The B<workdir> methods set the path of the RCS working directory.  If not
specified, default path is '.' (current working directory).

    $obj->workdir('/usr/local/source');

The B<rcsdir> methods set the path of the RCS archive directory.  If not
specified, default path is './RCS'.

    $obj->rcsdir('/usr/local/archive');

The B<pathname> method will set both the working filename and archive
directory.

    $obj->pathname($RCS_DIR . '/' . 'butthead.c');
and
    $obj->pathname($RCS_DIR . '/' . 'butthead.c,v');

are the same as

    $obj->rcsdir($RCS_DIR);
    $obj->file('butthead.c');

=head2 RCS PARSE METHODS

This class provides methods to directly parse the RCS archive file.

The B<access> method returns a list of all user on the access list.

    @access_list = $obj->access;

The B<author> method returns the author of the revision.  The head revision
is used if no revision argument is passed to method.

    # returns the author of revision '1.3'
    $author = $obj->author('1.3');

    # returns the authos of the head revision
    $author = $obj->author;

The B<head> method returns the head revision.

    $head = $obj->head;

The B<lock> method returns the locker of the revision.  The method returns
null if the revision is unlocked.  The head revision is used if no revision
argument is passed to method.  When called in list context the lock method
returns a hash of all locks.

    # returns locker of revision '1.3'
    $locker = $obj->lock('1.3');

    # returns locker of head revision
    $locker = $obj->lock;

    # return hash of all locks
    %locks = $obj->lock;    # called in list context
    foreach $rev (keys %locks) {
        $locker = $locks{$rev};
        print "User $locker has revision $rev locked\n";
    }

The B<revisions> method returns a list of all revisions of archive file.

    @revisions = $obj->revisions;

The B<state> method returns the state of the revision. The head revision
is used if no revision argument is passed to method.

    # returns state of revision '1.3'
    $state = $obj->state('1.3');

    # returns state of head revision
    $state = $obj->state;

The B<symbol> method returns the symbol(s) associated with a revision.
If called in list context, method returns all symbols associated with
revision.  If called in scalar context, method returns last symbol
assciated with a revision.  The head revision is used if no revision argument
is passed to method.

    # list context, returns all symbols associated with revision 1.3
    @symbols = $obj->symbol('1.3');

    # list context, returns all symbols associated with head revision
    @symbols = $obj->symbol;

    # scalar context, returns last symbol associated with revision 1.3
    $symbol = $obj->symbol('1.3');

    # scalar context, returns last symbol associated with head revision
    $symbol = $obj->symbol;

The B<symbols> method returns a hash, keyed by symbol, of all of the revisions
associated with the file.

    %symbols = $obj->symbols;
    foreach $sym (keys %symbols) {
        $rev = $symbols{$sym};
    }

The B<revdate> method returns the date of a revision.  The returned date format
is the same as the localtime format.  When called as a scalar, it returns the 
system date number.  If called is list context, the list
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) is returned.

    # scalar mode
    $scalar_date = $obj->revdate;
    print "Scalar date number = $scalar_date\n";
    $date_str = localtime($scalar_date);
    print "Scalar date string = $date_str\n";

    # list mode
    @list_date = $obj->revdate;
    print "List date = @list_date\n";

The B<dates> method returns a hash of revision dates, keyed on revision.  The
hash values are system date numbers.  When called in scalar mode, the method
returns the most recent revision date.

    # list mode
    %DatesHash = obj->dates;
    @dates_list = sort {$b<=>$a} values %DatesHash;
    $MostRecent = $dates_list[0];

    # scalar mode
    $most_recent = $obj->dates;
    print "Most recent date = $most_recent\n";
    $most_recent_str = localtime($most_recent);
    print "Most recent date string = $most_recent_str\n";

The B<symrev> method returns the revision against which a specified symbol was
defined. If the symbol was not defined against any version of this file, 0 is
returned.

    # gets revision that has 'MY_SYMBOL' defined against it
    $rev = $obj->symrev('MY_SYMBOL');

The B<daterev> method returns revisions which were created before a specified
date.  Method may take one or six arguments.  If one arguments is passed, then
the argument is a date number.  If six arguments are passed, then they represent
a date string.

    # one argument, date number
    # gets revisions created before Sun Sep  6 22:23:47 1998
    @revs = $obj->daterev(841436420);

    # six argument
    # gets revisions created before 25th June 1998 16:45:30
    @revs = $obj->daterev(1998, 6, 25, 16, 45, 30);

The B<comments> method returns a hash of revision comments, keyed on revision.
A key value of 0 returns the description.

    %comments = $obj->comments;
    $description = $comments{0};
    $comment_1_3 = $comments{'1.3'};

=head2 RCS SYSTEM METHODS

These methods invoke the RCS system utilities.

The B<ci> method calls the RCS ci program.

    # check in, and then check out in unlocked state
    $obj->ci('-u');

The B<co> method calls the RCS co program.

    # check out in locked state
    $obj->co('-l');

The B<rcs> method calls the RCS rcs program.

    # lock file
    $obj->rcs('-l');

The B<rcsdiff> method calls the RCS rcsdiff program.  When called in
list context, this method returns the outpout of the rcsdiff program.
When called in scalar context, this method returns the return status of
the rcsdiff program.  The return status is 0 for the same, 1 for some
differences, and 2 for error condition.

When called without parameters, rcsdiff does a diff between the current
working file, and the last revision checked in.

    # call in list context
    @diff_output = $obj->rcsdiff;

    # call in scalar context
    $changed = $obj->rcsdiff;
    if ($changed) {
        print "Working file has changed\n";
    }

Call rcsdiff with parameters to do a diff between any two revisions.

    @diff_output = $obj->rcsdiff('-r1.2', '-r1.1');

The B<rlog> method calls the RCS rlog program.  This method returns the
output of the rlog program.

    # get complete log output
    @rlog_complete = $obj->rlog;

    # called with '-h' switch outputs only header information
    @rlog_header = $obj->rlog('-h');
    print @rlog_header;

The B<rcsclean> method calls the RCS rcsclean program.

    # remove working file
    $obj->rcsclean;


=head1 EXAMPLES

=head2 CREATE ACCESS LIST

Using method B<rcs> with the B<-a> switch allows you to add users to
the access list of an RCS archive file.

    use Rcs;
    $obj = Rcs->new;

    $obj->rcsdir("./project_tree/archive");
    $obj->workdir("./project_tree/src");
    $obj->file("cornholio.pl");

Methos B<rcs> invokes the RCS utility rcs with the same parameters.

    @users = qw(beavis butthead);
    $obj->rcs("-a@users");

Calling method B<access> returns list of users on access list.

    $filename = $obj->file;
    @access_list = $obj->access;
    print "Users @access_list are on the access list of $filename\n";


=head2 PARSE RCS ARCHIVE FILE

Set class variables and create 'RCS' object.
Set bin directory where RCS programs (e.g. rcs, ci, co) reside.  The
default is '/usr/local/bin'.  This sets the bin directory for all objects.

    use Rcs;
    Rcs->bindir('/usr/bin');
    $obj = Rcs->new;

Set information regarding RCS object.  This information includes name of the
working file, directory of working file ('.' by default), and RCS archive
directory ('./RCS' by default).

    $obj->rcsdir("./project_tree/archive");
    $obj->workdir("./project_tree/src");
    $obj->file("cornholio.pl");

    $head_rev = $obj->head;
    $locker = $obj->lock;
    $author = $obj->author;
    @access = $obj->access;
    @revisions = $obj->revisions;

    $filename = $obj->file;

    if ($locker) {
        print "Head revision $head_rev is locked by $locker\n";
    }
    else {
        print "Head revision $head_rev is unlocked\n";
    }

    if (@access) {
        print "\nThe following users are on the access list of file $filename\n";
        map { print "User: $_\n"} @access;
    }

    print "\nList of all revisions of $filename\n";
    foreach $rev (@revisions) {
        print "Revision: $rev\n";
    }

=head2 CHECK-IN FILE

Set class variables and create 'RCS' object.
Set bin directory where RCS programs (e.g. rcs, ci, co) reside.  The
default is '/usr/local/bin'.  This sets the bin directory for all objects.

    use Rcs;
    Rcs->bindir('/usr/bin');
    Rcs->quiet(0);      # turn off quiet mode
    $obj = Rcs->new;

Set information regarding RCS object.  This information includes name of
working file, directory of working file ('.' by default), and RCS archive
directory ('./RCS' by default).

    $obj->file('cornholio.pl');

    # Set RCS archive directory, is './RCS' by default
    $obj->rcsdir("./project_tree/archive");

    # Set working directory, is '.' by default
    $obj->workdir("./project_tree/src");

Check in file using B<-u> switch.  This will check in the file, and will then
check out the file in an unlocked state.  The B<-m> switch is used to set the
revision comment.

Command:

    $obj->ci('-u', '-mRevision Comment');

is equivalent to commands:

    $obj->ci('-mRevision Comment');
    $obj->co;

=head2 CHECK-OUT FILE

Set class variables and create 'RCS' object.
Set bin directory where RCS programs (e.g. rcs, ci, co) reside.  The
default is '/usr/local/bin'.  This sets the bin directory for all objects.

    use Rcs;
    Rcs->bindir('/usr/bin');
    Rcs->quiet(0);      # turn off quiet mode
    $obj = Rcs->new;

Set information regarding RCS object.  This information includes name of
working file, directory of working file ('.' by default), and RCS archive
directory ('./RCS' by default).

    $obj->file('cornholio.pl');

    # Set RCS archive directory, is './RCS' by default
    $obj->rcsdir("./project_tree/archive");

    # Set working directory, is '.' by default
    $obj->workdir("./project_tree/src");

Check out file read-only:

    $obj->co;

or check out and lock file:

    $obj->co('-l');

=head2 RCSDIFF

Method B<rcsdiff> does an diff between revisions.

    $obj = Rcs->new;
    $obj->bindir('/usr/bin');

    $obj->rcsdir("./project_tree/archive");
    $obj->workdir("./project_tree/src");
    $obj->file("cornholio.pl");

    print "Diff of current working file\n";
    if ($obj->rcsdiff) {       # scalar context
        print $obj->rcsdiff;   # list context
    }
    else {
       print "Versions are Equal\n";
    }

    print "\n\nDiff of revisions 1.2 and 1.1\n";
    print $obj->rcsdiff('-r1.2', '-r1.1');

=head2 RCSCLEAN

Method B<rcsclean> will remove an unlocked working file.

    use Rcs;
    Rcs->bindir('/usr/bin');
    Rcs->quiet(0);      # turn off quiet mode
    $obj = Rcs->new;

    $obj->rcsdir("./project_tree/archive");
    $obj->workdir("./project_tree/src");
    $obj->file("cornholio.pl");

    print "Quiet mode NOT set\n" unless Rcs->quiet;

    $obj->rcsclean;

=head1 AUTHOR

Craig Freter, E<lt>F<craig@freter.com>E<gt>

=head1 CONTRIBUTORS

David Green, E<lt>F<greendjf@cvhp152.gpt.marconicomms.com>E<gt>

Jamie O'Shaughnessy, E<lt>F<jamie@thanatar.demon.co.uk>E<gt>

Raju Krishnamurthy, E<lt>F<raju_k@iname.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 1997,2003 Craig Freter.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

