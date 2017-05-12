#line 1 "inc/File/NCopy.pm - /usr/lib/perl5/site_perl/5.8.0/File/NCopy.pm"
package File::NCopy;
require 5.004; # just because I think you should upgrade :)

#line 174

use Cwd ();
use strict;
use vars qw(@EXPORT_OK @ISA $VERSION);
@ISA = qw(Exporter);
# we export nothing by default :)
@EXPORT_OK = qw(copy cp);

$VERSION = '0.32';

# this works on Unix
sub u_chmod($$)
{
    my ($file_from,$file_to) = @_;

    my ($mode) = (stat $file_from)[2];
    chmod $mode & 0777,$file_to
        unless ref $file_to eq 'GLOB' || ref $file_to eq 'FileHandle';
    1;
}

# this also works on Unix
sub f_check($$)
{
    my ($file_from,$file_to) = @_;

    # get a shared lock on file to copy from
    flock $file_from,5
        or return 0;
    # try and get an exclusive lock on the file to copy to
    flock $file_to,6
        or do {
            flock $file_from,8;
            return 0;
        };
    flock $file_from,8;
    flock $file_to,8;

    1;
}

# this also works on Unix, it's not the default but you can easily use
# it by using the module in an object oriented way
# $copy = File::NCopy->new('file_check' => \&File::NCopy::unix_check);
sub unix_check($$)
{
    my ($file_from,$file_to) = @_;

    my ($fdev,$fino) = (stat $file_from)[0,1];
    my ($tdev,$tino) = (stat $file_to)[0,1];

    return 0
        if $fdev == $tdev && $fino == $tino;
    1;
}

sub s_times($$)
{
    my ($file_from,$file_to) = @_;

    my ($uid,$gid,$atime,$mtime) = (stat $file_from)[4,5,8,9];

    utime $atime,$mtime,$file_to
        unless ref $file_to eq 'GLOB' || ref $file_to eq 'FileHandle';

    # this may only work for men in white hats; on Unix
    chown $uid,$gid,$file_to
        unless ref $file_to eq 'GLOB' || ref $file_to eq 'FileHandle';
    1;
}

# all the actual copying is done here, folks ;)
sub _docopy_file_file($$$)
{
    my $this = shift;
    my ($file_from,$file_to) = @_;
    local (*FILE_FROM,*FILE_TO);
    my ($was_handle);

    # did we get a file handle ?
    unless(ref $file_from eq 'GLOB' || ref $file_from eq 'FileHandle') {
        open FILE_FROM,"<$file_from"
            or do {
                print "*** Couldn\'t open from file <$!> ==> $file_from\n"
                    if $this->{'_debug'};
                return 0;
            };
    }
    else {
        *FILE_FROM = *$file_from;
    }

    unless(ref $file_to eq 'GLOB' || ref $file_to eq 'FileHandle') {
        # we must open in update mode since on some systems exclusive
        # locks are only granted to files that are going to be written;
        open FILE_TO,"+<$file_to"
            or goto NO_FILE; # no file, so file can't be the same :)
    }
    else {
        *FILE_TO = *$file_to;
        $was_handle = 1;
    }

    unless(-t FILE_FROM || -t FILE_TO) {
        $this->{'file_check'}->(\*FILE_FROM,\*FILE_TO)
            or return 0;
    }

NO_FILE:
    # files aren't the same; now open for writing unless we got a
    # filehandle
    if(! $was_handle) {
        open FILE_TO,">$file_to"
            or chmod 0644, "$file_to"
                if $this->{'force_write'};
        open FILE_TO,">$file_to"
            or do {
                print "*** Couldn\'t open to file <$!> ==> $file_to\n"
                    if $this->{'_debug'};
                return 0;
            };
    }

    # and now for the braindead OS's
    binmode FILE_FROM;
    binmode FILE_TO;

    my $buf = '';
    my ($len,$write_n);
    # read file and write to new file, recover from write errors and
    # read errors; we accept however much we read and try to write it
    # 8K is a nice buffer size for most file systems
    while(1) {
        $len = sysread(FILE_FROM,$buf,8192);
        return 0
            unless defined $len;
        last
            unless $len > 0;
        while($len) {
            $write_n = syswrite(FILE_TO,$buf,$len);
            return 0
                unless defined $write_n;
            $len -= $write_n;
        }
    }

    $this->{'set_permission'}->($file_from,$file_to);
    $this->{'set_times'}->($file_from,$file_to)
        if $this->{'preserve'};

    # we only close files we opened
    close FILE_FROM
        unless ref $file_from eq 'GLOB' || ref $file_from eq 'FileHandle';
    close FILE_TO
        unless ref $file_to eq 'GLOB' || ref $file_to eq 'FileHandle';

    print "$file_from ==> $file_to\n"
        if $this->{'_debug'};

    1;
}

sub get_path($)
{
    my $dir = shift;

    my $save_dir = Cwd::cwd;
    chdir $dir
        or return undef;
    $dir = Cwd::cwd;
    chdir $save_dir;

    $dir;
}

sub _recurse_from_dir($$$);

# we never actually change the directory :)
sub _recurse_from_dir($$$)
{
    my $this = shift;
    my ($from_dir,$to_dir) = @_;
    local (*DIR);

    opendir DIR,$from_dir
        or do {
            print "*** Couldn\'t opendir <$!> ==> $from_dir\n"
                if $this->{'_debug'};
            return 0;
        };
    my @files = readdir DIR
        or do {
            print "*** Couldn\'t read dir <$!> ==> $from_dir\n"
                if $this->{'_debug'};
            return 0;
        };
    closedir DIR;

    my $made_dir;
    unless(-e $to_dir) {
        mkdir $to_dir,0777
            or return 0;
        $made_dir = 1;
    }

    my ($retval,$ret,$link,$save_link);

    # make sure we don't end up with a recursive, circular link
    # this isn't totally foolproof, though it does prevent circular
    # links
    if($this->{'follow_links'}) {
        if(defined($save_link = get_path $from_dir)) {
            $this->{'_links'}->{$save_link} = 1;
        }
    }

    for (@files) {
        next
            if /^\.\.?$/;
        if(-f "$from_dir/$_") {
            $ret = _docopy_file_file $this, $from_dir . '/' . $_ ,
                    $to_dir . '/' . $_;
        }
        elsif(-d "$from_dir/$_") {
            if($this->{'follow_links'} && -l "$from_dir/$_") {
                $link = get_path "$from_dir/$_";
            }
            if(! -l "$from_dir/$_" || $this->{'follow_links'}
                    && defined $link
                    && ! exists $this->{'_links'}->{$link}) {
                $ret = _recurse_from_dir
                        $this,$from_dir . '/' . $_ ,$to_dir . '/' . $_;
            }
            else {
                if(defined($link = get_path "$from_dir/$_")) {
                    $ret = symlink $link, "$to_dir/$_";
                }
            }
        }
        $retval = $retval || $ret;
    }

    if($made_dir) {
        $this->{'set_permission'}->($from_dir,$to_dir);
        $this->{'set_times'}->($from_dir,$to_dir)
            if $this->{'preserve'};
    }

    # remove the name so that there can be link to it from other dirs
    # that are not subdirs of this one
    if($this->{'follow_links'}) {
        delete $this->{'_links'}->{$save_link};
    }

    $retval;
}

sub _docopy_dir_dir($$$)
{
    my $this = shift;
    my ($dir_from,$dir_to) = @_;
    my ($from_name);

    $dir_from =~ s/\/$//; # remove trailing slash, if any
    if($dir_from =~ tr/\///) {
        $from_name = substr $dir_from,rindex($dir_from,'/') + 1;
    }
    else {
        $from_name = $dir_from;
        if($from_name =~ /^\.\.?$/) {
            $from_name = '';
        }
    }

    unless($dir_to =~ /\/$/) {
        $dir_to .= '/';
    }
    $dir_to .= $from_name;

    $this->{'_links'} = {};

    _recurse_from_dir $this, $dir_from,$dir_to;
}

sub _docopy_file_dir($$$)
{
    my $this = shift;
    my ($file,$dir) = @_;
    my $file_to;

    if($file =~ tr/\///) {
        $file_to = substr $file,rindex($file,'/') + 1;
    }
    else {
        $file_to = $file;
    }

    $dir =~ s/\/$//; # remove trailing slash

    _docopy_file_file $this, $file,$dir.'/'.$file_to;
}

# this just redirects calls, like copy ;)
sub _docopy_files_dir($$@)
{
    my $this = shift;
    my $copies = shift;
    my $dir = pop;

    for (@_) {
        if(-d $_ && $this->{'recursive'}) {
            _docopy_dir_dir $this, $_, $dir
                and push @$copies, $_;
        }
        elsif(-f $_) {
            _docopy_file_dir $this, $_, $dir
                and push @$copies, $_;
        }
    }
    1;
}

# does glob work on all systems?
sub expand(@)
{
    my @args;

    return 
        if @_ < 2;

    for (my $i = 0;$i < $#_;++$i) {
        push @args,glob $_[$i];
    }
    push @args,$_[$#_];

    @args;
}

sub new(@);

# this just redirects calls
sub copy(@)
{
    my $this;

    # were we called through an object reference?
    if(ref $_[0] eq 'File::NCopy') {
        $this = shift;
    }
    else {
        # no, so let's make one
        $this = new File::NCopy;
        if(ref $_[0] eq 'SCALAR') {
            my $rec = shift;
            $this->recursive($$rec);
        }
    }

    my @copies;
    my @args = expand @_;

    print "passed args ==> @args\n"
        if $this->{'_debug'};

    # one or more files/directories to a directory
    if(@args >= 2 && -d $args[$#args]) {
        _docopy_files_dir $this, \@copies, @args;
    }
    # file to file
    elsif(@args == 2 && -f $args[0]) {
        _docopy_file_file $this, $args[0],$args[1]
            and push @copies, $args[0];
    }

    @copies;
}

sub cp(@) {
    return copy @_;
}

# instantiate our object
sub new(@)
{
    my $this = shift;
    
    my $conf = {
        'recursive'      => 0,
        'preserve'       => 0,
        'follow_links'   => 0,
        'force_write'    => 0,
        '_debug'         => 0,
        'set_permission' => \&File::NCopy::u_chmod,
        'file_check'     => \&File::NCopy::f_check,
        'set_times'      => \&File::NCopy::s_times,
        '_links'         => {},
    };

    my $ref;
    if(@_ % 2 == 0) {
        my %ref = @_;
        $ref = \%ref;
    }
    elsif(ref $_[0] eq 'HASH') {
        $ref = shift;
    }

    if(ref $ref eq 'HASH') {
        $conf->{'recursive'} = abs int $ref->{'recursive'}
            if defined $ref->{'recursive'};
        $conf->{'preserve'} = abs int $ref->{'preserve'}
            if defined $ref->{'preserve'};
        $conf->{'follow_links'} = abs int $ref->{'follow_links'}
            if defined $ref->{'follow_links'};
        $conf->{'force_write'} = abs int $ref->{'force_write'}
            if defined $ref->{'force_write'};
        $conf->{'_debug'} = abs int $ref->{'_debug'}
            if defined $ref->{'_debug'};
        $conf->{'set_permission'} = $ref->{'set_permission'}
            if defined $ref->{'set_permission'}
                && ref $ref->{'set_permission'} eq 'CODE';
        $conf->{'file_check'} = $ref->{'file_check'}
            if defined $ref->{'file_check'}
                && ref $ref->{'file_check'} eq 'CODE';
        $conf->{'set_times'} = $ref->{'set_times'}
            if defined $ref->{'set_times'}
                && ref $ref->{'set_times'} eq 'CODE';
    }

    bless $conf,$this;
}

sub recursive($;$)
{
    return
        if @_ < 1;
    my $this = shift;

    return
        unless ref $this eq 'File::NCopy';

    @_ ? $this->{'recursive'} = abs int shift
       : $this->{'recursive'};
}

sub preserve($;$)
{
    return
        if @_ < 1;
    my $this = shift;

    return
        unless ref $this eq 'File::NCopy';

    @_ ? $this->{'preserve'} = abs int shift
       : $this->{'preserve'};
}

sub follow_links($;$)
{
    return
        if @_ < 1;
    my $this = shift;

    return
        unless ref $this eq 'File::NCopy';

    @_ ? $this->{'follow_links'} = abs int shift
       : $this->{'follow_links'};
}

sub force_write($;$)
{
    return
        if @_ < 1;
    my $this = shift;

    return
        unless ref $this eq 'File::NCopy';

    @_ ? $this->{'force_write'} = abs int shift
       : $this->{'force_write'};
}

1;
