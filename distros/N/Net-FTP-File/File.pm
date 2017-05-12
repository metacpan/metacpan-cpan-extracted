package Net::FTP::File;

use strict;
use warnings;
use Net::FTP;

our $VERSION = '0.06';

my $pretty = 1;
our $_fatal = 0;    # not my() because you can't localize lexical variables

my %cols = (
    pretty => {
        0 => 'Permissions',
        1 => 'Number of Links',
        2 => 'Owner',
        3 => 'Group',
        4 => 'Bytes',
        5 => 'Last Modified Month',
        6 => 'Last Modified Day',
        7 => 'Last Modified Year/Time',
        8 => 'Path'
    },
    utility => {
        0 => 'perms',
        1 => 'links',
        2 => 'owner',
        3 => 'group',
        4 => 'bytes',
        5 => 'month',
        6 => 'day',
        7 => 'yr_tm',
        8 => 'path'
    }
);

our %DirProcHash = (
    cols => $cols{pretty},
    proc => sub {
        my $line = shift;
        my $hash = shift;
        if ( $line !~ m/^total/ ) {

            my @parts = split /\s+/, $line;
            my @lin   = split /\s/,  $line;
            my $path_re = join '\s+', map { quotemeta } @parts[ 8 .. $#parts ];
            $path_re = '\s*' . $path_re . '\s*';
            $path_re = qr($path_re);
            my ($path) = $line =~ m{($path_re)};
            $path = substr( $path, 1 );    # remove first space that is there but is not part of the name
            my ( $file, $link ) = split / \-\> /, $path;
            $hash->{$file}->{'Link To'} = defined $link && $link ? $link : undef;

            for ( 0 .. 8 ) {
                my $label = exists $Net::FTP::File::DirProcHash{cols}->{$_} ? $Net::FTP::File::DirProcHash{cols}->{$_} : $_;
                $hash->{$file}->{$label} = $_ == 8 ? $file : $parts[$_];
            }
        }
    },

);

sub Net::FTP::pretty_dir {
    shift;
    my $newp = shift;
    if ( defined $newp ) {
        $pretty = $newp;
        $DirProcHash{cols} = $cols{pretty}  if $pretty;
        $DirProcHash{cols} = $cols{utility} if !$pretty;
    }
    return $pretty;
}

my $setmsg = sub {
    my $ftp = shift;
    my $msg = shift() . "\n";
    $msg .= 'net_cmd_resp: ' . scalar $ftp->message if $ftp->message;
    ${*$ftp}{'net_cmd_resp'} = [$msg];
    $_fatal = 1;
};

sub Net::FTP::isfile {
    my $ftp = shift;
    return 1 if $ftp->exists(@_) && !$ftp->isdir(@_);
    0;
}

sub Net::FTP::isdir {
    my $ftp = shift;
    local $_fatal;
    my $c = $ftp->pwd();
    my $r = $ftp->cwd(@_);
    my $d = $ftp->cwd($c);
    my $e = $ftp->pwd();
    $setmsg->( $ftp, "Could not CWD into original directory $c" ) if $c ne $e || !$d;
    return undef if $_fatal;
    return $r ? 1 : 0;
}

sub Net::FTP::exists {
    my $ftp = shift;
    if    ( defined $ftp->size(@_) ) { return 1; }
    elsif ( $ftp->isdir(@_) )        { return 1; }
    else                             { return 0; }
}

sub Net::FTP::dir_hashref {
    my $ftp = shift;
    my %dir;
    for my $ln ( $ftp->dir(@_) ) {
        $Net::FTP::File::DirProcHash{proc}->( $ln, \%dir );
    }
    return \%dir;
}

sub Net::FTP::copy {
    my $ftp = shift;
    my ( $t, $f );
    my $fd = $ftp->pwd;
    my ( $o, $n, $cd, $to ) = @_;
    if ( $ftp->isfile($o) ) {
        if ( !defined $to && defined $cd && $cd =~ m/^\d+$/ ) { $to = $cd; $cd = ''; }
        my $g = $ftp->retr($o);
        while ( $g->read( $f, 1024, $to ) ) { $t .= $f; }
        $g->close();
        $ftp->cwd($cd) if $cd;
        my $p = $ftp->stor($n);
        $p->write( $t, length($t), $to );
        $p->close();
        $ftp->cwd($fd) if $cd;
        return 1 if $ftp->exists($n);
        return 0;
    }
    else { return undef; }
}

sub Net::FTP::move {
    my $ftp = shift;
    if ( $_[0] eq $_[1] ) {
        $setmsg->( $ftp, "copy $_[0] to $_[1] failed: they are the same file" );
        return;
    }
    my $cp = $ftp->copy(@_);
    local $_fatal = 0;
    $setmsg->( $ftp, "copy $_[0] to $_[1] failed: $_[0] does not exist" )  if !defined $cp;
    $setmsg->( $ftp, "copy $_[0] to $_[1] failed: $_[1] was not created" ) if !$cp;
    $ftp->delete( $_[0] ) or $setmsg->( $ftp, "Unable to delete original file $_[0] after copy" );
    return 0 if $_fatal;
    1;
}

sub Net::FTP::chmod {
    my $ftp = shift;
    if ( $ftp->supported('SITE CHMOD') ) {
        my $chmod = $ftp->site( 'CHMOD', @_ );
        return 1 if $chmod == 2;
        return 0 if $chmod == 5;
        return -1;
    }
    return undef;
}

sub Net::FTP::touch {
    my $ftp = shift;
    my $rfl = shift;
    if ( $ftp->isdir($rfl) ) {
        if ( shift() ) {
            $ftp->empty($rfl) or return;
        }
        else { return -1 }
    }
    elsif ( $ftp->isfile($rfl) && $ftp->size($rfl) > 0 ) {
        $ftp->copy( $rfl, $rfl ) or return;    # becasue $ftp->append and $ftp->appe don't change $ftp->mdtm() if you append nothing, if you knwo of a better way please let me know, thx :)
    }
    else {
        $ftp->empty($rfl) or return;
    }
    return $ftp->mdtm($rfl);
}

sub Net::FTP::empty {
    my $ftp = shift;
    my $zb  = '';
    open ZBF, '>', \$zb or return;
    $ftp->put( \*ZBF, shift() ) or return;
    close ZBF;
}

# not 'stat' since one day Net::FTP may want to support STAT and likely will call it stat()
sub Net::FTP::fstat { die 'fstat() in not yet implemented' }

1;

__END__

=head1 NAME

Net::FTP::File - Perl extension for simplifying FTP file operations.

=head1 SYNOPSIS

   use Net::FTP::File;

   my $ftp = Net::FTP->new("some.host.name", Debug => 0)
      or die "Cannot connect to some.host.name: $@";

   $ftp->login("anonymous",'-anonymous@')
      or die "Cannot login ", $ftp->message;

   if($ftp->isfile($file) {
      $ftp->move($file,$newfile) or warn $ftp->message;
      $ftp->chmod(644, $newfile) or warn $ftp->message;
   } else { print "$file does not exist or is a directory"; }

   my $dirinfo_hashref = $ftp->dir_hashref;

   print Dumper $dirinfo_hashref->{$file}; # Dumper() is from Data::Dumper, just FYI

   $ftp->quit;

=head1 METHODS 

=head2 $ftp->exists

Returns true if the argument exists and is a file or directory.

   print "$file exists\n" if $ftp->exists($file);


=head2 $ftp->isfile

Returns true if the argument exists and is not a directory.

   print "$file is a file\n" if $ftp->isfile($file);

=head2 $ftp->isdir

Returns true if the argument is a directory. It returns undef and sets $ftp->message if there is a problem while determining its status.

   my $isdir = $ftp->isdir($file);
   
   print "$file is a directory\n" if $isdir;
   print $ftp->message if undef $ftp->message; 

=head2 $ftp->copy

Copies files (not directories) on the remote server. Returns undef if the argument !$ftp->isfile or there are otherwise errors.

   $ftp->copy($orig, $new) or die $ftp->message;

or you can specify a directory to change into after $orig is read and before it writes $new 
(it will attempt to change back to the current directory once its done):

   $ftp->copy($orig, $new, $dir) or die $ftp->message;

and also a timout for the reading and writing of the files:

   $ftp->copy($orig, $new, $dir, $timeout) or die $ftp->message;

or only a timout (IE third argument is numeric)

   $ftp->copy($orig, $new, $timeout) or die $ftp->message;

if you want to change into a directory whose name is made of all numbers then you can either define the forth argument or use a trailing slash on the third argument (if there is no forth argument) so that it is not all numeric.

=head2 $ftp->move

$ftp->copy()'s a file (so all of $ftp->copy()'s arguments and paradigms apply to this method, then deletes the original if successful and checks that all went well and sets $ftp->message if it didn't.

   $ftp->move($orig, $new) or die $ftp->message;

It returns undef and sets $ftp->message if you specify the same thing for each file so that its not deleted when the original is removed.

=head2 $ftp->chmod

Returns undefined if the FTP server does not support the FTP protocol's SITE CHMOD.
Otherwise it returns 1 if response is ok, 0 if it failed and -1 if it was neither specifically.

   $ftp->chmod(644, $file) or die $ftp->message;

The arguments are sent basically as "SITE CHMOD your args here" so you will need to call $ftp->chmod with arguments the FTP server you are connected to understands.
99% of the time it will be  like the example above.

=head2 $ftp->touch

   $ftp->touch or die $ftp->message;

If the file does not exist it creates a new zero byte file.

If the file does exist it modifies its $ftp->mdtm to now.

If the file is a directory it will return -1 * since $ftp->mdtm doesn't really work with directories. You can have it attempt to create a new file of the same name by specifying a second argument that is true:

   $ftp->touch('public_html'); # returns -1 since its a directory 

If any knows of a way to change the equivalent of $ftp->mdtm of a directory using ftp, let me know please :)

   $ftp->touch('public_html',1); # attempts to create a file called public_html 

One caveat is that some FTP servers will give "public_html: Is a directory" even though its trying to $ftp->put a new file. Anyone who knows a way around that I'd be happy to hear from you :)

Unless there is a problem (IE or die $ftp->message) it will return the current $ftp->mdtm

=head2 $ftp->empty

Create a new empty file or make an existing file 0 size (used by $ftp->touch for non existant or 0 byte files).

   $ftp->empty($file) or die $ftp->message;

=head2 $ftp->dir_hashref

It takes the same arguments as $ftp->dir and returns a hashref of info parsed from $ftp->dir.
Each key is the file or path name as returned by $ftp->dir and the value is another hashref of info whose keys are defined in $Net::FTP::File::DirProcHash{cols} (Default is the "Pretty" version, see $ftp->pretty_dir below) and corresponding values are parsed with $Net::FTP::File::DirProcHash{proc}. This can all be customized as needed, see "HANDLING DIRECTORY LISTING FORMATS OF DIFFERENT FTP SERVERS" below for more info. 

   my $dir_info_hashref = $ftp->dir_hashref(@net_ftp_dir_args);

Note that spaces in path names and links are not escaped. if that is necessary for your application then you must escape them.

Multiple spaces and single or multiple spaces at the beginning or end are properly preserved.

=head2 $ftp->pretty_dir

Returns true or false if "Pretty" mode is on or off respectively, sets "Pretty" mode if given an argument. "Pretty" mode means that the keys of each file's hashref in $ftp->dir_hashref are either long names (IE Pretty) or short [a-z_]+ versions (IE Utilitarian)

   print $ftp->pretty_dir ? 'I feel Pretty oh so Pretty' : 'I am Utilitarian hear me roar';

   use Net::FTP::File;
   use Data::Dumper;
   ...

   print Dumper $ftp->dir_hashref(@net_ftp_dir_args); # "Pretty" version

   $ftp->pretty_dir(0);
   print Dumper $ftp->dir_hashref(@net_ftp_dir_args); # [a-z_]+ version

   $ftp->pretty_dir(1);   
   print Dumper $ftp->dir_hashref(@net_ftp_dir_args); # "Pretty" version

Changing $Net::FTP::File::DirProcHash{cols} overrides any previous $ftp->pretty_dir call/setting and setting $ftp->pretty_dir overrides any custom $Net::FTP::File::DirProcHash{cols}

=head2 $ftp->fstat

This is currently not implemented but will be in the next version. The goal will be to imitate Perl's built in stat() function.
It is not $ftp->stat since one day Net::FTP may want to support STAT and likely will call it stat()

=head1 HANDLING DIRECTORY LISTING FORMATS OF DIFFERENT FTP SERVERS

Since most FTP servers have their own format of results when using $ftp->dir, this module has a setup that will work with, hopefully, most *nix FTP servers.
You can control how $ftp->dir is parsed by customizing the entries in %Net::FTP::File::DirProcHash to suit your FTP server's particular whims.
The parts of that hash are described below. Also the source will be very helpful to learn how it fits together so you can achieve whatever you need.

=head2 $Net::FTP::File::DirProcHash{proc}

This is a code reference that you can specify that will parse the lines returned from $ftp->dir
The first argument is the line and the second is a hash ref that will ultimatley be returned by $ftp->dir_hashref

=head2 $Net::FTP::File::DirProcHash{cols}

The keys of this hashref should correspond to the index number of the array of items you get when you parse the line in $Net::FTP::File::DirProcHash{proc}->() 
The values are the labels for these fields.

=head1 SEE ALSO

L<Net::FTP>

=head1 COMPARISON

Is this module just like another module with similar functionality? 

No it is not!

=item 1

It is a subclass and not a new class that uses Net::FTP underneath. That means the object is a normal Net::FTP object and has all the methods Net::FTP has.

=item 2

It does not override Net::FTP methods (IE does not have methods the same name as Net::FTP) which means you don't have to sort through how the function differs from the standard version in the Net::FTP module. 

=item 3

Its waaaay simpler to use without a bunch of weird config stuff to cloud the issue, odd hard to remember arguments, obscure methods to replace valid existing ones that are part of Net::FTP, or new methods that are badly named (IE think "grep" on this one). There are other things as well.

=item 4

It follows the paradigm of Perl name spaces, objects, and general good practice much better and in a way that is more intuitive and expandable.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
