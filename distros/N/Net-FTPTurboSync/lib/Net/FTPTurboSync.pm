# Copyright (c) 2011 Daneel S. Yaitskov <rtfm.rtfm.rtfm@gmail.com.>. 

# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Net::FTPTurboSync;

use 5.010001;
use strict;
use warnings;
use Cwd;
use File::Find;
use Net::FTPTurboSync::PrgOpts;
use Net::FTPTurboSync::LocalFile;
use Net::FTPTurboSync::LocalDir;
use Net::FTPTurboSync::RemoteDir;
use Net::FTPTurboSync::RemoteFile;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FTPTurboSync ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.07';

sub theOpts {
    return $Net::FTPTurboSync::PrgOpts::theOpts;
}

my $theOpts = $Net::FTPTurboSync::PrgOpts::theOpts;

=head1 NAME

Net::FTPTurboSync - Perl extension for turbo-ftp-sync script

=head1 SYNOPSIS

=head1 DESCRIPTION

Blah blah blah.

=head2 EXPORT

None by default.

=over 

=item B<buildlocaltree>()

  class - name of this module

It build two hashes of all directories and all files including nested and
returns an array of hash references to them, respectively. Hashes' key is a
relative path to file or folder from current folder.

=cut

sub buildlocaltree () {
    my ($class) = @_;
    my %ldirs = ();
    my %lfiles = ();
    chdir theOpts()->{localdir};    
    my $ldl = length(Cwd::getcwd());
    if ($theOpts->{doflat}) {
        my @globbed=glob("{*,.*}");
        foreach my $curglobbed (@globbed) {
            next if (! -f $curglobbed);
            $lfiles{$curglobbed} = Net::FTPTurboSync::LocalFile->load ( $curglobbed );            
        }
    } else {
        find ( { wanted=> sub { noticelocalfile ( $File::Find::name,
                                                  \%ldirs,
                                                  \%lfiles, $ldl ) ;  },
                 follow_fast => $theOpts->{followsymlinks},
                 no_chdir => 1
               },
               
               Cwd::getcwd()."/"
            );
    }
    return ( \%ldirs, \%lfiles );
    
    sub noticelocalfile {
        my ( $fileName, $ldirs, $lfiles, $ldl ) = @_;
        my $relfilename = substr( $fileName, $ldl );
        $relfilename =~ s!^/!!;
        if (length($relfilename) == 0) { return; }
        my $theOpts = theOpts();
        if (theOpts()->{ignoremask} ne "") {
            if ($relfilename =~ /$theOpts->{ignoremask}/ ) {
                if ($theOpts->{doverbose}) {
                    print "Ignoring $relfilename which matches $theOpts->{ignoremask}\n";
                }
                return;
            }
        }
        if (-d $_) {
            $ldirs->{$relfilename} = Net::FTPTurboSync::LocalDir->load ( $relfilename );
        }elsif (-f $_) {
            $lfiles->{$relfilename} = Net::FTPTurboSync::LocalFile->load ( $relfilename );
        }elsif (-l $_) {
            print "Link isn't supported: $fileName\n";
        }elsif (! $theOpts->{doquiet}) {
            print "Ignoring file of unknown type: $fileName\n";
        }
    }
}

=item B<buildremotetree>($ftp,$dbh)

  class - name of this module

  ftp   - object Net::FTPTurboSync::MyFtp

  dbh   - database handle which is returned from DBI->connect(...)

The method returns an array with two elements. First is a hash ref of
directories found in current folder on FTP server. Second is a hash ref o files
found in current folder on FTP server. A hask key of both hashes is an absolute
path.  A hash value of first hash is RemoteDir object and a second one is
RemoteFile object.

The method gets data from the database object rather than ftp. Ftp object is
passed for futher using. 
=cut

sub buildremotetree() {
    my ( $class, $ftp, $dbh  )  = @_;
    my %rdirs = ();
    my %rfiles = ();
    my $dirs = $dbh->selectAllDirs();
    foreach my $dir ( @$dirs ){
        $rdirs{ $dir->{fullname} } = Net::FTPTurboSync::RemoteDir->load ( $ftp, $dbh, $dir ) ;
    }
    my $files = $dbh->selectAllFiles();
    foreach my $file ( @$files ){
        $rfiles{ $file->{fullname} } = Net::FTPTurboSync::RemoteFile->load( $ftp, $dbh, $file );
    }
    return ( \%rdirs, \%rfiles );
}

=item B<fillDb>($dbh,$ldir,$lfiles)

  class - name of this module

  dbh   - database handle object

  ldir  - a hash ref of directories to be written in db
 
  lfiles - a hash ref of files to be written in db

=cut

sub fillDb {
    my ($class, $dbh, $ldirs, $lfiles) = @_;
    foreach my $lfile (values(%$lfiles)) {
        $dbh->uploadFile( $lfile->getPath,
                          $lfile->getPerms,
                          $lfile->getModDate,
                          $lfile->getSize );
    }
    foreach my $ldir ( values ( %$ldirs ) ) {
        $dbh->createDir( $ldir->getPath, $ldir->getPerms );
    }
}

1;
__END__

=back

=head1 AUTHOR

Daneel S. Yaitskov, E<lt>rtfm.rtfm.rtfm@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Daneel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
