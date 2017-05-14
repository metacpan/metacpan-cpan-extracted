package Net::SFTP::Recursive;

# Perl standard modules
use strict;
use warnings;
use Carp;
use Net::SFTP;
use File::Stat::Ls qw(:all); 

require 5.003;
my $VERSION = 0.12;

require Exporter;
our @ISA         = qw(Exporter Net::SFTP);
our @EXPORT      = qw(rget rput local_ls);
our @EXPORT_OK   = qw(rget rput local_ls
    );
our %EXPORT_TAGS = (
    all  => [@EXPORT_OK]
    );
our @IMPORT_OK   = qw(
    new get put status ls do_open do_read do_write do_close
    do_lstat do_fstat do_stat do_setstat do_fsetstat 
    do_opendir do_remove do_mkdir do_rmdir do_realpath
    );

=head1 NAME

Net::SFTP::Recursive - Perl class for transfering files recursively
and securely

=head1 SYNOPSIS

  use Net::SFTP::Recursive;

  my %cfg = (user=>'usr_id', password=>'secret',
             local_dir=>'/ftp/dir', remote_dir=>'/remote/dir',
             file_filter=>'ftp*');
  my $sftp = Net::SFTP::Recursive->new;
  # or combine the two together
  my $sftp = Net::SFTP::Recursive->new(%cfg);

  # transfer files from local to remote
  $sftp->rput('/my/local/dir','/remote/dir'); 

  # transfer files from remote to local
  $sftp->rget('/pub/remotel/dir','/local/dir'); 

  # pass the output to &my_cb method to process
  $sftp->rget('/pub/mydir', '/local/dir', \&my_cb);

  # with file and dir filters
  $sftp->rget('/pub/mydir', '/local/dir', \&my_cb,
        {file_pat=>'pdf$', dir_pat=>'^f'});

  # you can also use a callback method for get or put method as well
  $sftp->rget('/remote/dir','/my/dir',\&my_cb,{cb4get=>\&myget_cb});
  $sftp->rput('/my/dir','/remote/dir',\&my_cb,{cb4put=>\&mysub_cb});

=head1 DESCRIPTION

This class contains methods to transfer files recursively and 
securely using Net::SFTP and Net::SSH::Perl.

I<Net::SFTP> is a pure-Perl implementation of the Secure File
Transfer Protocol (SFTP)--file transfer built on top of the
SSH protocol. I<Net::SFTP> uses I<Net::SSH::Perl> to build a
secure, encrypted tunnel through which files can be transferred
and managed. It provides a subset of the commands listed in
the SSH File Transfer Protocol IETF draft, which can be found
at I<http://www.openssh.com/txt/draft-ietf-secsh-filexfer-00.txt>.

SFTP stands for Secure File Transfer Protocol and is a method of
transferring files between machines over a secure, encrypted
connection (as opposed to regular FTP, which functions over an
insecure connection). The security in SFTP comes through its
integration with SSH, which provides an encrypted transport
layer over which the SFTP commands are executed, and over which
files can be transferred. The SFTP protocol defines a client
and a server; only the client, not the server, is implemented
in I<Net::SFTP>.

Because it is built upon SSH, SFTP inherits all of the built-in
functionality provided by I<Net::SSH::Perl>: encrypted
communications between client and server, multiple supported
authentication methods (eg. password, public key, etc.).

This class extends from I<Net::SFTP> and inherents all the methods
from it, plus more methods: I<rget>, I<rput>, and I<local_ls>.

=cut

=head2 new ($host, %args)

Input variables:

  $host - ftp host name or IP address 
  %args - configuration parameters 

Variables used or routines called:

  None

How to use:

   my $obj = new Net::SFTP::Recursive;      # or
   my $obj = Net::SFTP::Recursive->new;     # or
   my $svr = 'ftp.mydomain.com'; 
   my $obj = Net::SFTP::Recursive->new($svr,
      user=>'usr',password=>'pwd'); 

Return: new empty or initialized Net::SFTP::Recursive object.

Opens a new SFTP connection with a remote host I<$host>, and
returns a I<Net::SFTP> object representing that open
connection.

I<%args> can contain:

=over 4

=item * user

The username to use to log in to the remote server. This should
be your SSH login, and can be empty, in which case the username
is drawn from the user executing the process.

See the I<login> method in I<Net::SSH::Perl> for more details.

=item * password

The password to use to log in to the remote server. This should
be your SSH password, if you use password authentication in
SSH; if you use public key authentication, this argument is
unused.

See the I<login> method in I<Net::SSH::Perl> for more details.

=item * debug

If set to a true value, debugging messages will be printed out
for both the SSH and SFTP protocols. This automatically turns
on the I<debug> parameter in I<Net::SSH::Perl>.

The default is false.

=item * warn

If given a sub ref, the sub is called with $self and any warning
message; if set to false, warnings are supressed; otherwise they
are output with 'warn' (default).

=item * ssh_args

Specifies a reference to a list of named arguments that should
be given to the constructor of the I<Net::SSH::Perl> object
underlying the I<Net::SFTP> connection.

For example, you could use this to set up your authentication
identity files, to set a specific cipher for encryption, etc.

See the I<new> method in I<Net::SSH::Perl> for more details.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
       $self->{host} = shift;
    $self->init(@_);
}

=head1 METHODS

The following are the common methods, routines, and functions 
defined in this classes.

=head2 Exported Tag: All 

The I<:all> tag includes all the methods or sub-rountines 
defined in this class. 

  use Net::SFTP::Recursive qw(:all);

It includes the following sub-routines:

=head3 rget ($remote, $local, \&callback, $ar)

Input variables:

  $remote - remote path on ftp server
  $local  - local path for storing the files and directories
  \&callback - a sub routine to process the intermediate information
  $ar     - hash ref for additional parameters 
      file_pat - pattern for filtering file name such as
        .txt$ - all the files with .txt extension 
      dir_pat  - pattern for filtering directory name 
        ^F   - all the dir starting with F
      cb4get - sub ref for passing to get method. See callback 
               in get method in Net::SFTP
 
Variables used or routines called:

  None

How to use:

  my $svt = 'ftp.mydomain.com';
  my %cfg = (user=>'test_user', password => 'secure', debug=>1);
  my $sftp = Net::SFTP::Recursive->new($svr, %cfg);
     $sftp->rget('/pub/mydir', '/local/dir', \&my_cb);
  # with file and dir filters
     $sftp->rget('/pub/mydir', '/local/dir', \&my_cb,
        {file_pat=>'pdf$', dir_pat=>'^f', cb4get=>\&myget_cb});

Return: $msg - number of files transferred

Downloads files and/or sub-directory from I<$remote> to I<$local>.
If I<$local> is specified, it is opened/created, and 
the contents of the remote file I<$remote> are written to I<$local>. 
In addition, its filesystem attributes (atime, mtime, permissions, etc.)
will be set to those of the remote file.

If I<rget> is called in a non-void context, returns the contents
of I<$remote> (as well as writing them to I<$local>, if I<$local>
is provided.  Undef is returned on failure.

I<$local> is default to the current directory if it is not specified.

If I<\&callback> is specified, it should be a reference to a
subroutine. The subroutine will be executed at each iteration
of transfering a file. 
The callback function will receive as arguments: a
I<Net::SFTP> object with an open SFTP connection; the remote file 
path and name; the local file path and name
and the hash reference containing atime, mtime, flags, uid, gid, 
perm, and size in bytes). 
You can use this mechanism to provide status messages,
download progress meters, etc.:

    sub callback {
        my($sftp, $remote, $local, $ar) = @_;
        print "Copied from $remote to $local ($ar->{size} Bytes)\n";
    }


=cut

sub rget {
    my $s = shift;
    my ($rdr, $ldr, $cb, $p) = @_;
    print "No remote directory is specified.\n"  if !$rdr;
    return                                       if !$rdr; 
    my $vbm = (exists $s->{debug})?$s->{debug}:0; 

    # check local dir
    my $idn = ($p && exists $p->{_idn})?$p->{_idn}:0;
    $ldr = '.' if ! $ldr; 
    print " + making local dir $ldr...\n" if ! -d $ldr && $vbm;
    mkdir $ldr,0777 if ! -d $ldr;
    my $idc  = " " x $idn; 
    my $msg  = "$idc + from $rdr\n$idc     to $ldr...\n";
    print "$msg\n" if $vbm; 
    my $ds = '/'; 
    my $fp = ($p && exists $p->{file_pat})?$p->{file_pat}:0;
    my $dp = ($p && exists $p->{dir_pat})?$p->{dir_pat}:0;
    my $cb4get = ($p && exists $p->{cb4get})?$p->{cb4get}:undef;

    # check remote list
    my @dr = $s->ls($rdr); 
    foreach my $d (@dr) {
        my $fn = $d->{filename};   # file name only
        my $ln = $d->{longname};   # file long list
        my $fa = $d->{a};          # file attributes
        # foreach my $k (sort keys %$fa) { print "$k=$fa->{$k}\n"; }
        if ($ln =~ /^d/ |\ $ln =~ /<DIR>/i) { # it is a dir
            next if $dp && $dp !~ /$dp/;
            $p->{_idn} += 2 if $p && $p =~ /HASH/; 
            my $d1 = join $ds, $rdr, $fn;
            my $d2 = join $ds, $ldr, $fn;
            $s->rget($d1, $d2, $cb, $p); 
            next; 
        }
        # check file pattern
        next if $fp && $fp !~ /$fp/; 
        # it is a file
        print "$idc   FN: $fn\n" if $vbm;
        print "$idc   LN: $ln\n" if $vbm && $vbm > 1; 
        my $rfn = join $ds, $rdr, $fn;
        my $lfn = join $ds, $ldr, $fn; 
        $s->get($rfn, $lfn, $cb4get);
        $cb->($s, $rfn, $lfn, $fa) if defined $cb;
    }
}

=head3 rput ($local, $remote, \&callback, $ar)

Input variables:

  $local  - local path for storing the files and directories
  $remote - remote path on ftp server
  \&callback - a sub routine to process the intermediate information
  $ar     - hash ref for additional parameters 
      file_pat - pattern for filtering file name such as
        .txt$ - all the files with .txt extension 
      dir_pat  - pattern for filtering directory name 
        ^F   - all the dir starting with F
      cb4put - sub ref for passing to get method. See callback 
               in put method in Net::SFTP
 
Variables used or routines called:

  None

How to use:

  my $svt = 'ftp.mydomain.com';
  my %cfg = (user=>'test_user', password => 'secure', debug=>1);
  my $sftp = Net::SFTP::Recursive->new($svr, %cfg);
     $sftp->rput('/local/mydir', '/remote/dir', \&my_cb);
  # with file and dir filters
     $sftp->rput('/local/mydir', '/remote/dir', \&my_cb,
        {file_pat=>'pdf$', dir_pat=>'^f', cb4put=>\&myput_cb});

Return: $msg - number of files transferred

Downloads files and/or sub-directory from I<$remote> to I<$local>.
If I<$local> is specified, it is opened/created, and 
the contents of the remote file I<$remote> are written to I<$local>. 
In addition, its filesystem attributes (atime, mtime, permissions, etc.)
will be set to those of the remote file.

If I<rget> is called in a non-void context, returns the contents
of I<$remote> (as well as writing them to I<$local>, if I<$local>
is provided.  Undef is returned on failure.

I<$local> is default to the current directory if it is not specified.

If I<\&callback> is specified, it should be a reference to a
subroutine. The subroutine will be executed at each iteration
of transfering a file. 
The callback function will receive as arguments: a
I<Net::SFTP> object with an open SFTP connection; the remote file 
path and name; the local file path and name
and the hash reference containing atime, mtime, flags, uid, gid, 
perm, and size in bytes). 
You can use this mechanism to provide status messages,
download progress meters, etc.:

    sub callback {
        my($sftp, $local, $remote, $ar) = @_;
        print "Copied from $remote to $local ($ar->{size} Bytes)\n";
    }

=cut

sub rput {
    my $s = shift;
    my ($ldr, $rdr, $cb, $p) = @_;
    print "No local directory is specified.\n"  if !$ldr;
    return                                      if !$ldr; 
    my $vbm = (exists $s->{debug})?$s->{debug}:0; 

    # check remote dir
    my $idn = ($p && exists $p->{_idn})?$p->{_idn}:0;
    $rdr = '/' if ! $rdr; 
    my @tmp = $s->ls($rdr); 
    print " + making remote dir $rdr...\n" if ! @tmp && $vbm;
    my $attr = Net::SFTP::Attributes->new;
    my $ldr_sa = stat_attr($ldr, 'sftp');
    foreach my $k (keys %$ldr_sa) { $attr->{$k} = $ldr_sa->{$k}; }
    $s->do_mkdir($rdr,$attr) if ! @tmp;
    my $idc  = " " x $idn; 
    my $msg  = "$idc + from $ldr\n$idc     to $rdr...\n";
    print "$msg\n" if $vbm; 
    my $ds = '/'; 
    my $fp = ($p && exists $p->{file_pat})?$p->{file_pat}:0;
    my $dp = ($p && exists $p->{dir_pat})?$p->{dir_pat}:0;
    my $cb4put = ($p && exists $p->{cb4put})?$p->{cb4put}:undef;

    # check remote list
    my @dr = $s->local_ls($ldr); 
    foreach my $d (@dr) {
        my $fn = $d->{filename};   # file name only
        my $ln = $d->{longname};   # file long list
        my $fa = $d->{a};          # file attributes
    # foreach my $k (sort keys %$fa) { print "$k=$fa->{$k}\n"; }
        if ($ln =~ /^d/ |\ $ln =~ /<DIR>/i) { # it is a dir
            next if $dp && $dp !~ /$dp/;
            $p->{_idn} += 2 if $p && $p =~ /HASH/; 
            my $d1 = join $ds, $rdr, $fn;
            my $d2 = join $ds, $ldr, $fn;
            $s->rput($d2, $d1, $cb, $p); 
            next; 
        }
        # check file pattern
        next if $fp && $fp !~ /$fp/; 
        # it is a file
        print "$idc   FN: $fn\n" if $vbm;
        print "$idc   LN: $ln\n" if $vbm && $vbm > 1; 
        my $rfn = join $ds, $rdr, $fn;
        my $lfn = join $ds, $ldr, $fn; 
        $s->put($lfn, $rfn, $cb4put);
        $cb->($s, $lfn, $rfn, $fa) if defined $cb;
    }
}

=head3 local_ls ($ldr[,$sr[,$hr]])

Input variables:

  $ldr    - local path for files and sub-directories to be listed
  $sr     - sub ref for processing each file stat
  $hr     - hash ref for passing any additional parameters 
      file_pat - pattern for filtering file name such as
        .txt$ - all the files with .txt extension 
      dir_pat  - pattern for filtering directory name 
        ^F   - all the dir starting with F
      cb4put - sub ref for passing to get method. See callback 
               in put method in Net::SFTP
 
Variables used or routines called:

  None

How to use:

  my $svt = 'ftp.mydomain.com';
  my %cfg = (user=>'test_user', password => 'secure', debug=>1);
  my $sftp = Net::SFTP::Recursive->new($svr, %cfg);
  # just get the result in list
  my @dir = $sftp->local_ls('/local/dir');
  # pass additional parameters and get the result as scalar (array ref) 
  my $ar2 = $sftp->local_ls('/local/dir',undef,
        {file_pat=>'pdf$', dir_pat=>'^f'}
     );
  # process the file in proc_file sub routine
  $sftp->local_ls('/local/dir',\&proc_file);

Return: @r or \@r depends on the caller subroutine.

This methods fetches a directory listing of I<$ldr>.

If I<$sr> is specified, for each entry in the directory,
I<$sr> will be called and given a reference to a hash
with three keys: I<filename>, the name of the entry in the
directory listing; I<longname>, an entry in a "long" listing
like C<ls -l>; and I<a>, a I<Net::SFTP::Attributes> object,
which contains the file attributes of the entry (atime, mtime,
permissions, etc.).

If I<$subref> is not specified, returns a list of directory
entries, each of which is a reference to a hash as described
in the previous paragraph.

=cut

sub local_ls {
    my $s = shift;
    my ($ldr, $sr, $p) = @_;
    my $ds = '/'; 
    my $fp = ($p && exists $p->{file_pat})?$p->{file_pat}:0;
    my $dp = ($p && exists $p->{dir_pat})?$p->{dir_pat}:0;
    my $vm = ($p && exists $p->{debug})?$p->{debug}:0;
    my @r = ();
    if (!$ldr || !-d $ldr) {
        print "ERR: could not find dir - $ldr\n" if $vm; 
        return wantarray ? @r : \@r; 
    } 
    opendir DIR, "$ldr" || croak "Unable to open dir - $ldr: $! \n";
    my @dir = readdir DIR;
    close DIR;
    my $vs  = 'dev,ino,mode,nlink,uid,gid,rdev,size,atime,mtime,';
       $vs .= 'ctime,blksize,blocks'; 
    my $v1  = 'flags,perm,uid,gid,size,atime,mtime';
    # atime=0, flags=12, gid=0, mtime=1120058679, 
    # perm=16886, size=0, uid=0
    my @v = split /,/, $v1;
    foreach my $d (@dir) {
        next if !$d || $d =~ /^(\.|\.\.)$/;
        my $fn = join $ds, $ldr, $d; 
        next if -f $fn && $fp && $d !~ /$fp/; 
        next if -d $fn && $dp && $d !~ /$dp/; 
        my $ls = ls_stat($fn);
        # my @a = stat($fn); 
        my @a = (stat($fn))[1,2,4,5,7,8,9]; 
        $a[0] = 0;       # set it to 0
        $a[0] |= 0x01;   # SSH2_FILEXFER_ATTR_SIZE        => 0x01
        $a[0] |= 0x02;   # SSH2_FILEXFER_ATTR_UIDGID      => 0x02
        $a[0] |= 0x04;   # SSH2_FILEXFER_ATTR_PERMISSIONS => 0x04
        $a[0] |= 0x08;   # SSH2_FILEXFER_ATTR_ACMODTIME   => 0x084
        my %par = map { $v[$_] => $a[$_] } 0..$#a ;
        push @r, {filename=>$d,longname=>$ls, a=>\%par};
        $sr->($d, $ls, \%par) if defined $sr;     
    }
    wantarray ? @r : \@r; 
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version includes the I<rget>, I<rput> and I<local_ls> methods.
It is released on 07/12/2005. 

07/13/2005 (htu) - changed I<rput> so that it is passing a 
I<Net::SFTP::Attributes> object to I<do_mkdir>. 
Changed version to 0.11.

=cut

=head1 SEE ALSO (some of docs that I check often)

Data::Describe, Oracle::Loader, CGI::Getopt, File::Xcopy

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut


