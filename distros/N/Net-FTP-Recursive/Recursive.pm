package Net::FTP::Recursive;

use Net::FTP;
use Carp;
use Cwd 'getcwd';
use strict;

use vars qw/@ISA $VERSION/;
use vars qw/%options %filesSeen %dirsSeen %linkMap $success/;

@ISA = qw|Net::FTP|;
$VERSION = '2.04';

sub new {
    my $class = shift;

    my $ftp = new Net::FTP(@_);

    bless $ftp, $class if defined($ftp);

    return $ftp;
}

#------------------------------------------------------------------
# - cd to directory, lcd to directory
# - grab all files, process symlinks according to options
#
# - foreach directory
#    - create it unless options say to flatten
#    - call function recursively.
#    - cd .. unless options say to flatten
#    - lcd ..
#
# -----------------------------------------------------------------

sub rget{
    my $ftp = shift;

    %options = (
                 ParseSub => \&parse_files,
                 SymLinkIgnore => 1,
                 @_,
                 InitialDir => $ftp->pwd
                );    #setup the options

    local %dirsSeen = ();
    local %filesSeen = ();

    if ( $options{SymlinkFollow} ) {
        $dirsSeen{ $ftp->pwd } = Cwd::cwd();
    }

    local $success = '';

    $ftp->_rget(); #do the real work here

    return $success;
}

sub _rget {
    my($ftp) = shift;

    my @dirs;

    my @ls = $ftp->dir();

    my @files = $options{ParseSub}->( @ls );

    @files = grep { $_->filename =~ $options{MatchAll} } @files
      if $options{MatchAll};

    @files = grep { $_->filename !~ $options{OmitAll} } @files
      if $options{OmitAll};

    print STDERR join("\n", @ls), "\n"
      if $ftp->debug;

    my $remote_pwd = $ftp->pwd;
    my $local_pwd = Cwd::cwd();

    FILE:
    foreach my $file (@files){
        #used to make sure that if we're deleting the files, we
        #successfully retrieved the file
        my $get_success = 1;
        my $filename = $file->filename();

        #if it's not a directory we just need to get the file.
        if ( $file->is_plainfile() ) {

            if( (     $options{MatchFiles}
                  and $filename !~ $options{MatchFiles} )
                or
                (     $options{OmitFiles}
                  and $filename =~ $options{OmitFiles} )){

                next FILE;
            }

            if ( $options{FlattenTree} and $filesSeen{$filename} ) {
                print STDERR "Retrieving $filename as ",
                             "$filename.$filesSeen{$filename}.\n"
                  if $ftp->debug;

                $get_success = $ftp->get( $filename,
                                          "$filename.$filesSeen{$filename}" );
            } else {
                print STDERR "Retrieving $filename.\n"
                  if $ftp->debug;

                $get_success = $ftp->get( $filename );
            }

            $filesSeen{$filename}++ if $options{FlattenTree};

            if ( $options{RemoveRemoteFiles} ) {
                if ( $options{CheckSizes} ) {
                    if ( -e $filename and ( (-s $filename) == $file->size ) ) {
                        $ftp->delete( $filename );
                        print STDERR "Deleting '$filename'.\n"
                          if $ftp->debug;
                    } else {
                        print STDERR "Will not delete '$filename': ",
                                     'remote file size and local file size ',
                                     "do not match!\n"
                          if $ftp->debug;
                    }
                } else {
                    if ( $get_success ) {
                        $ftp->delete( $filename );
                        print STDERR "Deleting '$filename'.\n"
                          if $ftp->debug;
                    } else {
                        print STDERR "Will not delete '$filename': ",
                                     "error retrieving file!\n"
                          if $ftp->debug;
                    }
                }
            }
        }
        elsif ( $file->is_directory() ) {

            if( (     $options{MatchDirs}
                  and $filename !~ $options{MatchDirs} )
                or
                (     $options{OmitDirs}
                  and $filename =~ $options{OmitDirs} )){

                next FILE;
            }

            if ( $options{SymlinkFollow} ) {
                $dirsSeen{"$remote_pwd/$filename"} = "$local_pwd/$filename";
                print STDERR "Mapping '$remote_pwd/$filename' to ",
                             "'$local_pwd/$filename'.\n";
            }

            push @dirs, $file;
        }
        elsif ( $file->is_symlink() ) {

            #SymlinkIgnore is really the default.
            if ( $options{SymlinkIgnore} ) {
                print STDERR "Ignoring the symlink ", $filename, ".\n"
                  if $ftp->debug;
                if ( $options{RemoveRemoteFiles} ) {
                    $ftp->delete( $filename );
                    print STDERR 'Deleting \'', $filename, "'.\n"
                      if $ftp->debug;
                }
                next FILE;
            }

            if( (     $options{MatchLinks}
                  and $filename !~ $options{MatchLinks} )
                or
                (     $options{OmitLinks}
                  and $filename =~ $options{OmitLinks} )){

                next FILE;
            }

            #otherwise we need to see if it points to a directory
            print STDERR "Testing to see if $filename refers to a directory.\n"
              if $ftp->debug;
            my $path_before_chdir = $ftp->pwd;
            my $is_directory = 0;

            if ( $ftp->cwd($file->filename()) ) {
                $ftp->cwd( $path_before_chdir );
                $is_directory = 1;
            }

            if ( not $is_directory and $options{SymlinkCopy} ) {
                #if it's not a directory and SymlinkCopy is set,
                # we'll just copy the file as a regular file

                #symlink to non-directory.  need to grab it and
                #make sure the filename does not collide
                my $get_success;
                if ( $options{FlattenTree} and $filesSeen{$filename}) {
                    print STDERR "Retrieving $filename as ",
                                 $filename.$filesSeen{$filename},
                                 ".\n"
                      if $ftp->debug;

                    $get_success = $ftp->get($filename,
                                             "$filename.$filesSeen{$filename}");
                } else {
                    print STDERR "Retrieving $filename.\n"
                      if $ftp->debug;

                    $get_success = $ftp->get( $filename );
                }

                $filesSeen{$filename}++;

                if ( $get_success and $options{RemoveRemoteFiles} ) {
                    $ftp->delete( $filename );

                    print STDERR "Deleting '$filename'.\n"
                      if $ftp->debug;
                }
            } #end of if (not $is_directory and $options{SymlinkCopy}
            elsif ( $is_directory and $options{SymlinkFollow} ) {
                #we need to resolve the link to an absolute path

                my $remote_abs_path = path_resolve( $file->linkname(),
                                                    $remote_pwd,
                                                    $filename
                );

                print STDERR "'$filename' got converted to '",
                             $remote_abs_path, "'.\n";

                #if it's a directory structure we've already seen,
                #we'll just make a relative symlink to that
                #directory

                # OR

                #if it's in the same tree that we started
                #downloading, we should get to it later, so we'll
                #just make a relative symlink to that directory.

                if (    $dirsSeen{$remote_abs_path}
                    or $remote_abs_path =~ s{^$options{InitialDir}}
                                            {$dirsSeen{$options{InitialDir}}}){

                    unless( $options{FlattenTree} ){
                        print STDERR "\$dirsSeen{$remote_abs_path} = ",
                                     $dirsSeen{$remote_abs_path}, "\n"
                          if $ftp->debug;

                        print STDERR "Calling convert_to_relative( '",
                                     $local_pwd, '/', $filename, "', '",
                                     (    $dirsSeen{$remote_abs_path}
                                       || $remote_abs_path ),
                                     "');\n"
                          if $ftp->debug;

                        my $rel_path =
                          convert_to_relative( "$local_pwd/$filename",
                                                  $dirsSeen{$remote_abs_path}
                                               || $remote_abs_path
                        );

                        print STDERR "Symlinking '$filename' to '$rel_path'.\n"
                          if $ftp->debug;

                        symlink $rel_path, $filename;
                    }

                    if ( $options{RemoveRemoteFiles} ) {
                        $ftp->delete( $filename );

                        print STDERR "Deleting '$filename'.\n"
                          if $ftp->debug;
                    }

                    next FILE;
                }
                # Otherwise we need to grab the directory and put
                # the info in a hash in case there is another link
                # to this directory
                else {

                    print STDERR "New directory to grab!\n"
                      if $ftp->debug;
                    push @dirs, $file;

                    $dirsSeen{$remote_abs_path} = "$local_pwd/$filename";
                    print STDERR "Mapping '$remote_abs_path' to '",
                                 "$local_pwd/$filename'.\n"
                      if $ftp->debug;
                    #no deletion, will handle that down below.

                }

            } #end of elsif($is_directory and $options{SymlinkFollow})

            # if it's a dir and SymlinkFollow is not set but
            # SymlinkLink is set, we'll just create the link.

            # OR

            # if it was a file and SymlinkCopy is not set but
            # SymlinkLink is, we'll just create the link.

            elsif ( $options{SymlinkLink} ) {
                #we need to make the symlink and that's it.
                symlink $file->linkName(), $file->filename();

                if ( $options{RemoveRemoteFiles} ) {
                    $ftp->delete( $file->filename );

                    print STDERR "Deleting '$filename'.\n"
                      if $ftp->debug;
                }
                next FILE;
            }
        }

        $success .= "Had a problem retrieving '$remote_pwd/$filename'!\n"
          unless $get_success;
    } #end of foreach ( @files )

    undef @files; #save memory in recursing.

    #this will do depth-first retrieval

    DIRECTORY:
    foreach my $file (@dirs) {
        my $filename = $file->filename;

        #check to make sure that we actually have permissions to
        #change into the directory

        unless ( $ftp->cwd($filename) ) {
            print STDERR 'Was unable to cd to ', $filename,
                         ", skipping!\n"
              if $ftp->debug;

            $success .= "Was not able to chdir to '$remote_pwd/$filename'!\n";
            next DIRECTORY;
        }

        unless ( $options{FlattenTree} ) {
            print STDERR "Making dir: ", $filename, "\n"
              if $ftp->debug;

            mkdir $filename, "0755"; # mkdir, ignore errors due to
                                     # pre-existence

            chmod 0755, $filename;   # just in case the UMASK in the
                                     # mkdir doesn't work

            unless ( chdir $filename ){
                print STDERR 'Could not change to the local directory ',
                             $filename, "!\n"
                  if $ftp->debug;

                $ftp->cwd( $remote_pwd );
                $success .= q{Could not chdir to local directory '}
                          . "$local_pwd/$filename'!\n";

                next DIRECTORY;
            }
        }

        #don't delete files that are accessed through a symlink

        my $remove;
        if ( $options{RemoveRemoteFiles} and $file->is_symlink() ) {
            $remove = $options{RemoveRemoteFiles};
            $options{RemoveRemoteFiles} = 0;
        }

        #need to recurse
        print STDERR 'Calling rget in ', $remote_pwd, "\n"
          if $ftp->debug;
        $ftp->_rget( );

        #once we've recursed, we'll go back up a dir.
        print STDERR 'Returned from rget in ', $remote_pwd, ".\n"
          if $ftp->debug;

        if ( $file->is_symlink() ) {
            $ftp->cwd( $remote_pwd );
            $options{RemoveRemoteFiles} = $remove;
        } else {
            $ftp->cdup;
        }

        chdir '..' unless $options{FlattenTree};

        if ( $options{RemoveRemoteFiles} ) {
            if ( $file->is_symlink() ) {
                print STDERR "Removing symlink '$filename'.\n"
                  if $ftp->debug;

                $ftp->delete( $filename );
            } else {
                print STDERR "Removing directory '$filename'.\n"
                  if $ftp->debug;

                $ftp->rmdir( $filename );
            }
        }
    }
}

sub rput{
  my $ftp = shift;

  %options = (
               ParseSub => \&parse_files,
               @_
              );

  local %filesSeen = ();

  local $success = '';

  $ftp->_rput(); #do the real work here

  return $success;
}

#------------------------------------------------------------------
# - make the directory on the remote host
# - cd to directory, lcd to directory
# - foreach directory, call the function recursively
# - cd .., lcd ..
# -----------------------------------------------------------------

sub _rput {
    my($ftp) = shift;

    my @dirs;  #list of directories to recurse into after this dir is processed

    my @files = read_current_directory();

    print STDERR join("\n", sort map { $_->filename() } @files),"\n"
      if $ftp->debug;

    my $remote_pwd = $ftp->pwd;

    foreach my $file (@files){
        my $put_success = 1;
        my $filename = $file->filename(); #we're gonna need it a lot here

        #if it's a file we just need to put the file
        if ( $file->is_plainfile() ) {

            #we're going to check for filename conflicts here if
            #the user has opted to flatten out the tree
            if ( $options{FlattenTree} and $filesSeen{$filename} ) {
                print STDERR "Sending $filename as ",
                             "$filename.$filesSeen{$filename}.\n"
                  if $ftp->debug;
                $put_success = $ftp->put( $filename,
                                         "$filename.$filesSeen{$filename}" );
            } else {
                print STDERR "Sending $filename.\n" if $ftp->debug;

                #I've saved $put_success here, but apparently the
                #return val isn't very useful-can probably stop
                #saving it
                $put_success = $ftp->put( $filename );
            }

            $filesSeen{$filename}++ if $options{FlattenTree};

            if ( $options{RemoveLocalFiles} and $options{CheckSizes} ) {
                if ( $ftp->size($filename) == (-s $filename) ) {
                    print STDERR q{Removing '}, $filename,
                                 "' from the local system.\n"
                      if $ftp->debug;

                    unlink $file->filename();
                } else {
                    print STDERR "Will not delete '$filename': ",
                                 'remote file size and local file size',
                                 " do not match!\n"
                      if $ftp->debug;
                }
            }
            elsif( $options{RemoveLocalFiles} ) {
                print STDERR q{Removing '}, $filename,
                             "' from the local system.\n"
                  if $ftp->debug;
                unlink $file->filename();
            }
        }

        #otherwise, if it's a directory, we have to create the directory
        #on the remote machine, cd to it, then recurse

        elsif ( $file->is_directory() ) {
            push @dirs, $file;
        }

        #if it's a symlink, there's nothing we can do with it.
        elsif ( $file->is_symlink() ) {

            if ( $options{SymlinkIgnore} ) {
                print STDERR "Not doing anything to ", $filename,
                             " as it is a link.\n"
                  if $ftp->debug;

                if ( $options{RemoveLocalFiles} ) {
                    print STDERR q{Removing '}, $filename,
                                 "' from the local system.\n"
                      if $ftp->debug;

                    unlink $file->filename();
                }
            }
            else {
                # check to see what kind of file the link target is
                if ( -f $filename and $options{SymlinkCopy} ) {
                    if ( $options{FlattenTree} and $filesSeen{$filename}) {
                        print STDERR "Sending $filename as ",
                                     "$filename.$filesSeen{$filename}.\n"
                          if $ftp->debug;

                        $put_success = $ftp->put( $filename,
                                       "$filename.$filesSeen{$filename}" );

                    } else {
                        print STDERR "Sending $filename.\n"
                          if $ftp->debug;

                        $put_success = $ftp->put( $filename );
                    }

                    $filesSeen{$filename}++ if $options{FlattenTree};

                    if ( $put_success and $options{RemoveLocalFiles} ) {
                        print STDERR q{Removing '}, $filename,
                                     "' from the local system.\n"
                          if $ftp->debug;

                        unlink $file->filename();
                    }
                }
                elsif ( -d $file->filename() and $options{SymlinkFollow} ) {
                    #then it's a directory, we need to add it to the
                    #list of directories to grab
                    push @dirs, $file;
                }
            }
        }

        $success .= "Had trouble putting $filename into $remote_pwd\n"
          unless $put_success;

    }

    undef @files; #save memory in recursing.

    # we'll use an absolute path to chdir at the end.
    my $local_pwd  = Cwd::cwd();

    foreach my $file (@dirs) {

        my $filename = $file->filename();

        unless ( chdir $filename ){
            print STDERR 'Could not change to the local directory ',
                         $filename, "!\n"
              if $ftp->debug;

            $success .= 'Could not change to the local directory '
                      . qq{'$local_pwd/$filename'!\n};
            next;
        }

        # try to chdir to the remote path, if it's not possible,
        # try to make the directory instead
        unless( $ftp->cwd($filename) ){
            print STDERR "Making dir: ", $filename, "\n"
              if $ftp->debug;

            unless( $ftp->mkdir($filename) ){
                print STDERR 'Could not make remote directory ',
                             $filename, "!\n"
                  if $ftp->debug;

                $success .= q{Could not make remote directory '}
                         .  qq{$remote_pwd/$filename}
                          . qq{!\n};
            }

            unless ( $ftp->cwd($filename) ){
                print STDERR 'Could not change remote directory to ',
                             $filename, ", skipping!\n"
                  if $ftp->debug;

                $success .= qq{Could not change remote directory to '}
                          . qq{$remote_pwd/$filename}
                          . qq{'!\n};
                next;
            }
        }

        print STDERR "Calling rput in ", $local_pwd, "\n"
          if $ftp->debug;
        $ftp->_rput();

        #once we've recursed, we'll go back up a dir.
        print STDERR 'Returned from rput in ',
                     $filename, ".\n"
          if $ftp->debug;

        $ftp->cdup;

        if ( $file->is_symlink() ) {
            chdir $local_pwd;
            unlink $filename if $options{RemoveLocalFiles};
        } else {
            chdir '..';
            rmdir $filename if $options{RemoveLocalFiles};
        }
    }
}


sub rdir{
    my($ftp) = shift;

    %options = ( ParseSub => \&parse_files,
                 OutputFormat => '%p %lc %u %g %s %d %f %l',
                 @_,
                 InitialDir => $ftp->pwd
               );    #setup the options

    unless( $options{Filehandle} ) {
        Carp::croak("You must pass a filehandle when using rdelete/rls!");
    }

    local %dirsSeen = ();
    local %filesSeen = ();

    $dirsSeen{$ftp->pwd}++;

    local $success = '';

    $ftp->_rdir;

    return $success;
}

sub _rdir{
    my $ftp = shift;

    my @ls = $ftp->dir;

    print STDERR join("\n", @ls) if $ftp->debug;

    my(@dirs);
    my $fh = $options{Filehandle};
    print $fh $ftp->pwd, ":\n" unless $options{FilenameOnly};

    my $remote_pwd = $ftp->pwd;
    my $local_pwd  = Cwd::cwd();

    LINE:
    foreach my $line ( @ls ) {
        my($file) = $options{ParseSub}->( $line );
        next LINE unless $file;

        my $filename = $file->filename;

        # if it's a symlink that points to a directory, we need to
        # check it for cycles, and then put it on the list of directories
        # to examine

        if ( $file->is_symlink() and $ftp->cwd($filename) ) {
            $ftp->cwd( $remote_pwd );

            #we need to resolve the link to an absolute path
            my $remote_abs_path = path_resolve( $file->linkname,
                                                $remote_pwd,
                                                $filename );

            print STDERR qq{'$filename' got converted to '$remote_abs_path'.\n};

            #if it's a directory structure we've already seen,
            #we'll just treat it as a regular file

            # OR

            #if it's in the same tree that we started
            #downloading, we should get to it later, so we'll
            #just treat it as a regular file

            unless (    $dirsSeen{$remote_abs_path}
                     or $remote_abs_path =~ m%^$options{InitialDir}% ){

                # Otherwise we need to grab the directory and put
                # the info in a hash in case there is another link
                # to this directory

                push @dirs, $file;
                $dirsSeen{$remote_abs_path}++;

                if( $ftp->debug() ){
                    print STDERR q{Mapping '},
                                 $remote_abs_path,
                                 q{' to '},
                                 $dirsSeen{$remote_abs_path},
                                 ".\n";
                }
            }
        }
        elsif ( $file->is_directory() ) {
            push @dirs, $file;

            #since we won't get to the code below, we need this
            #code here
            if ( $options{FilenameOnly} && $options{PrintType} ) {
                print $fh $remote_pwd, '/', $filename, " d\n";
            }

            next LINE if $options{FilenameOnly};
        }


        if( $options{FilenameOnly} ){
            print $fh $remote_pwd, '/', $filename;
            if ( $options{PrintType} ) {
                my $filetype;
                if ( $file->is_symlink() ) {
                    print $fh ' s';
                } elsif ( $file->is_plainfile() ) {
                    print $fh ' f';
                }
            }
            print $fh "\n";
        }
        else {
            print $fh $line, "\n";
        }
    }

    print $fh "\n" unless $options{FilenameOnly};

    foreach my $dir (@dirs){
        my $dirname = $dir->filename;

        unless ( $ftp->cwd( $dirname ) ){
            print STDERR 'Was unable to cd to ', $dirname,
                         " in $remote_pwd, skipping!\n"
              if $ftp->debug;
            $success .= qq{Was unable to cd to '$remote_pwd/$dirname'\n};
            next;
        }

        print STDERR "Calling rdir in ", $remote_pwd, "\n"
          if $ftp->debug;
        $ftp->_rdir( );

        #once we've recursed, we'll go back up a dir.
        print STDERR "Returned from rdir in ", $dirname, ".\n"
          if $ftp->debug;

        if ( $dir->is_symlink() ) {
            $ftp->cwd($remote_pwd);
        }
        else {
            $ftp->cdup;
        }
    }
}

sub rls{
  my $ftp = shift;
  return $ftp->rdir(@_, FilenameOnly => 1);
}

#---------------------------------------------------------------
# CD to directory
# Recurse through all subdirectories and delete everything
# This will not go into symlinks
#---------------------------------------------------------------

sub rdelete {

   my($ftp) = shift;

   %options = ( ParseSub => \&parse_files,
                @_
               );    #setup the options

   local $success = '';

   $ftp->_rdelete(); #do the real work here

   return $success;

}

sub _rdelete {

    my $ftp = shift;

    my @dirs;

    my @ls = $ftp->dir;

    print STDERR join("\n", @ls) if $ftp->debug;

    my $remote_pwd = $ftp->pwd;

    foreach my $line ( @ls ){
        my($file) = $options{ParseSub}->($line);

        #just delete plain files and symlinks
        if ( $file->is_plainfile() or $file->is_symlink() ) {
            my $filename = $file->filename();
            my $del_success = $ftp->delete($filename);

            $success .= qq{Had a problem deleting '$remote_pwd/$filename'!\n}
              unless $del_success;
        }
        #otherwise, if it's a directory, we have more work to do.
        elsif ( $file->is_directory() ) {
            push @dirs, $file;
        }
    }

    #this will do depth-first delete
    foreach my $file (@dirs) {
        my $filename = $file->filename();

        #in case we didn't have permissions to cd into that
        #directory
        unless ( $ftp->cwd( $file->filename() ) ){
            print STDERR qq{Could not change dir to $filename!\n}
              if $ftp->debug;
            $success .= qq{Could not change dir to '$remote_pwd/$filename'!\n};
            next;
        }

        #need to recurse
        print STDERR 'Calling _rdelete in ', $ftp->pwd, "\n"
          if $ftp->debug;
        $ftp->_rdelete( );

        #once we've recursed, we'll go back up a dir.
        print STDERR "Returned from _rdelete in ", $ftp->pwd, ".\n"
          if $ftp->debug;
        $ftp->cdup;

        ##now delete the directory we just came out of
        $ftp->rmdir($file->filename())
          or $success .= 'Could not delete remote directory "'
                       . qq{$remote_pwd/$filename}
                       . qq{"!\n};
    }
}

#-------------------------------------------------------------#
#
# read_current_directory()
#
# Used by the _rput() method to retrieve the list of local
# files to send to the remote server.  This eliminates the need
# to use "ls" or "dir" to read the local directory and then parse
# the output from those commands.
#
#-------------------------------------------------------------#
sub read_current_directory {
    opendir THISDIR, '.' or die "Couldn't open ", getcwd();

    my $path = getcwd();

    my @to_return;

    foreach my $file ( sort readdir(THISDIR) ){
        next if $file =~ /^[.]{1,2}$/;

        my $file_obj;

        # checking for the symlink must come first; -d and -f can resolve
        # to true if the link points to either a dir or a plain file
        if( -l $file ){
            $file_obj
              = Net::FTP::Recursive::File->new(
                                                'symlink' => 1,
                                                filename  => $file,
                                                path      => $path,
                                                linkname  => readlink($file),
                                               );
        }
        elsif( -d $file ){
            $file_obj = Net::FTP::Recursive::File->new(
                                                        directory  => 1,
                                                        filename   => $file,
                                                        path       => $path,
                                                       );
        }
        elsif( -f $file ){
            $file_obj = Net::FTP::Recursive::File->new(
                                                        plainfile => 1,
                                                        filename  => $file,
                                                        path      => $path,
                                                       );
        }

        push @to_return, $file_obj if $file_obj;
    }

    closedir THISDIR;

    return @to_return;
}

#-------------------------------------------------------------------#
# Should look at all of the output from the current dir and parse
# through and extract the filename, date, size, and whether it is a
# directory or not
#
# The date should also have a time, so that if the script needs to be
# run several times in one day, it will grab any files that changed
# that day.
#-------------------------------------------------------------------#

sub parse_files {
    my(@to_return) = ();

    foreach my $line (@_) {
        next unless $line =~ /^
                               (\S+)\s+             #permissions
                                \d+\s+              #link count
                                \S+\s+              #user owner
                                \S+\s+              #group owner
                                \d+\s+              #size
                                \w+\s+\w+\s+\S+\s+  #last modification date
                                (.+?)\s*            #filename
                                (?:->\s*(.+))?      #optional link part
                               $
                              /x;

        my($perms, $filename, $linkname) = ($1, $2, $3);

        next if $filename =~ /^\.{1,2}$/;

        my $file;
        if ($perms =~/^-/){
            $file = Net::FTP::Recursive::File->new( plainfile => 1,
                                                    filename  => $filename );
        }
        elsif ($perms =~ /^d/) {
            $file = Net::FTP::Recursive::File->new( directory => 1,
                                                    filename  => $filename );
        } elsif ($perms =~/^l/) {
            $file = Net::FTP::Recursive::File->new( 'symlink' => 1,
                                                    filename  => $filename,
                                                    linkname  => $linkname );
        } else {
            next; #didn't match, skip the file
        }

        push(@to_return, $file);
    }

    return(@to_return);
}

=begin blah

  This subroutine takes a path and converts the '.' and
  '..' parts of it to make it into a proper absolute path.

=end blah

=cut

sub path_resolve{
    my($link_path, $pwd, $filename) = @_;
    my $remote_pwd; #value to return

    #this case is so that if we have gotten to this
    #symlink through another symlink, we can actually
    #retrieve the correct files (make the correct
    #symlink, whichever)

    if ( $linkMap{$pwd} and $link_path !~ m#^/# ) {
        $remote_pwd = $linkMap{$pwd} . '/' . $link_path;
    }

    # if it was an absolute path, just make sure there aren't
    # any . or .. in it, and make sure it ends with a /
    elsif ( $link_path =~ m#^/# ) {
        $remote_pwd = $link_path;
    }

    #otherwise, it was a relative path and we need to
    #prepend the current working directory onto it and
    #then eliminate any .. or . that are present
    else {
        $remote_pwd = $pwd;
        $remote_pwd =~ s#(?<!/)$#/#;
        $remote_pwd .= $link_path;
    }

    #Collapse the resulting path if it has . or .. in it.  The
    #while loop is needed to make it start over after each
    #match (as it will need to go back for parts of the
    #regex).  It's probably possible to write a regex to do it
    #without the while loop, but I don't think that making it
    #less readable is a good idea.  :)

    while ( $remote_pwd =~ s#(?:^|/)\.(?:/|$)#/# ) {}
    while ( $remote_pwd =~ s#(?:/[^/]+)?/\.\.(?:/|$)#/# ){}

    #the %linkMap will store as keys the absolute paths
    #to the links and the values will be the "real"
    #absolute paths to those locations (to take care of
    #../-type links

    $filename =~ s#/$##;
    $remote_pwd =~ s#/$##;

    $pwd =~ s#(?<!/)$#/#; #make sure there's a / on the end
    $linkMap{$pwd . $filename} = $remote_pwd;

    $remote_pwd; #return the result
}

=begin comment

  This subroutine takes two absolute paths and basically
  'links' them together.  The idea is that all of the paths
  that are created for the symlinks should be relative
  paths.  This is the sub that does that.

  There are essentially 6 cases:

    -Different root hierarchy:
    /tmp/testdata/blah -> /usr/local/bin/blah
    -Current directory:
    /tmp/testdata/blah -> /tmp/testdata
    -A file in the current directory:
    /tmp/testdata/blah -> /tmp/testdata/otherblah
    -Lower in same hierarchy:
    /tmp/testdata/blah -> /tmp/testdata/dir/otherblah
    -A higher directory along the same path (part of link abs path) :
    /tmp/testdata/dir/dir2/otherblah -> /tmp/testdata/dir
    -In same hierarchy, somewhere else:
    /tmp/testdata/dir/dir2/otherblah -> /tmp/testdata/dir/file

  The last two cases are very similar, the only difference
  will be that it will create '../' for the first rather
  than the possible '../../dir'.  The last case will indeed
  get the '../file'.

=end comment

=cut

sub convert_to_relative{
    my($link_loc, $realfile) = (shift, shift);
    my $i;
    my $result;
    my($new_realfile, $new_link, @realfile_parts, @link_parts);

    @realfile_parts = split m#/#, $realfile;
    @link_parts = split m#/#, $link_loc;

    for ( $i = 0; $i < @realfile_parts; $i++ ) {
        last unless $realfile_parts[$i] eq $link_parts[$i];
    }

    $new_realfile = join '/', @realfile_parts[$i..$#realfile_parts];
    $new_link = join '/', @link_parts[$i..$#link_parts];

    if( $i == 1 ){
        $result = $realfile;
    }
    elsif ( $i > $#realfile_parts and $i == $#link_parts  ) {
        $result = '.';
    }
    elsif ( $i == $#realfile_parts and $i == $#link_parts ) {
        $result = $realfile_parts[$i];
    }
    elsif ( $i >= $#link_parts  ) {
        $result = join '/', @realfile_parts[$i..$#realfile_parts];
    }
    else {
        $result = '../' x ($#link_parts - $i);
        $result .= join '/', @realfile_parts[$i..$#realfile_parts]
          if $#link_parts - $i > 0;
    }

    return $result;
}


package Net::FTP::Recursive::File;

use vars qw/@ISA/;
use Carp;

@ISA = ();

sub new{
    my $pkg = shift;

    my $self = { plainfile => 0,
                 directory => 0,
                 'symlink' => 0,
                 @_
               };

    croak 'Must set a filename when creating a File object!'
      unless defined $self->{filename};

    if( $self->{'symlink'} and not $self->{linkname} ){
        croak 'Must set a linkname when creating a File object for a symlink!';
    }

    bless $self, $pkg;
}

sub linkname{
    return $_[0]->{linkname};
}

sub filename{
    return $_[0]->{filename};
}

sub is_symlink{
    return $_[0]->{symlink};
}

sub is_directory{
    return $_[0]->{directory};
}

sub is_plainfile{
    return $_[0]->{plainfile};
}

1;

__END__

=head1 NAME

Net::FTP::Recursive - Recursive FTP Client class

=head1 SYNOPSIS

    use Net::FTP::Recursive;

    $ftp = Net::FTP::Recursive->new("some.host.name", Debug => 0);
    $ftp->login("anonymous",'me@here.there');
    $ftp->cwd('/pub');
    $ftp->rget( ParseSub => \&yoursub );
    $ftp->quit;

=head1 DESCRIPTION

C<Net::FTP::Recursive> is a class built on top of the Net::FTP package
that implements recursive get and put methods for the retrieval and
sending of entire directory structures.

This module's default behavior is such that the remote ftp
server should understand the "dir" command and return
UNIX-style directory listings.  If you'd like to provide
your own function for parsing the data retrieved from this
command (in case the ftp server does not understand the
"dir" command), all you need do is provide a function to one
of the Recursive method calls.  This function will take the
output from the "dir" command (as a list of lines) and
should return a list of Net::FTP::Recursive::File objects.
This module is described below.

All of the methods also take an optional C<KeepFirstLine>
argument which is passed on to the default parsing routine.
This argument supresses the discarding of the first line of
output from the dir command.  wuftpd servers provide a
total line, the default behavior is to throw that total line
away.  If yours does not provide the total line,
C<KeepFirstLine> is for you.  This argument is used like the
others, you provide the argument as the key in a key value
pair where the value is true (ie, KeepFirstLine => 1).

When the C<Debug> flag is used with the C<Net::FTP> object, the
C<Recursive> package will print some messages to C<STDERR>.

All of the methods should return false ('') if they are
successful, and a true value if unsuccessful.  The true
value will be a string of the concatenations of all of the
error messages (with newlines).  Note that this might be the
opposite of the more intuitive return code.

=head1 CONSTRUCTOR

=over

=item new (HOST [,OPTIONS])

A call to the new method to create a new
C<Net::FTP::Recursive> object just calls the C<Net::FTP> new
method.  Please refer to the C<Net::FTP> documentation for
more information.

=back

=head1 METHODS

=over


=item rget ( [ParseSub =>\&yoursub] [,FlattenTree => 1]
         [,RemoveRemoteFiles => 1] )

The recursive get method call.  This will recursively
retrieve the ftp object's current working directory and its
contents into the local current working directory.

This will also take an optional argument that will control what
happens when a symbolic link is encountered on the ftp
server.  The default is to ignore the symlink, but you can
control the behavior by passing one of these arguments to
the rget call (ie, $ftp->rget(SymlinkIgnore => 1)):

=over 12

=item SymlinkIgnore - disregards symlinks (default)

=item SymlinkCopy - copies the link target from the server to the client (if accessible).  Works on files other than a directory.  For directories, see the C<SymlinkFollow> option.

=item SymlinkFollow - will recurse into a symlink if it
points to a directory.  This option may be given along with
one of the others above.

=item SymlinkLink - creates the link on the client.  This is
superceded by each of the previous options.

=back

The C<SymlinkFollow> option, as of v1.6, does more
sophisticated handling of symlinks.  It will detect and
avoid cycles, on all client platforms.  Also, if on a UNIX
(tm) platform, if it detects a cycle, it will create a
symlink to the location where it downloaded the directory
(or will download it subsequently, if it is in the subtree
under where the recursing started).  On Windows, it will
call symlink just as on UNIX (tm), but that's probably not
gonna do much for you.  :)

The C<FlattenTree> optional argument will retrieve all of
the files from the remote directory structure and place them
in the current local directory.  This option will resolve
filename conflicts by retrieving files with the same name
and renaming them in a "$filename.$i" fashion, where $i is
the number of times it has retrieved a file with that name.

The optional C<RemoveRemoteFiles> argument to the function
will allow the client to delete files from the server after
it retrieves them.  The default behavior is to leave all
files and directories intact.  The default behavior for this
is to check the return code from the FTP GET call.  If that
is successful, it will delete the file.  C<CheckSizes> is an
additional argument that will check the filesize of the
local file against the file size of the remote file, and
only if they are the same will it delete the file.  You must
l provide the C<RemoveRemoteFiles> option in order for
option to affect the behavior of the code.  This check will
only be performed for regular files, not directories or
symlinks.

For the v1.6 release, I have also added some additional
functionality that will allow the client to be more specific
in choosing those files that are retrieved.  All of these
options take a regex object (made using the C<qr> operator)
as their value.  You may choose to use one or more of these
options, they are applied in the order that they are
listed.  They are:

=over

=item MatchAll - Will process file that matches this regex,
regardless of whether it is a plainish file, directory, or a
symlink.  This behavior can be overridden with the previous
options.

=item OmitAll - Do not process file that matches this
regex. Also may be overridden with the previous options.

=item MatchFiles - Only transfer plainish (not a directory
or a symlink) files that match this pattern.

=item OmitFiles - Omit those plainish files that match this
pattern.

=item MatchDirs - Only recurse into directories that match
this pattern.

=item OmitDirs - Do not recurse into directories that match
this pattern.

=item MatchLinks - Only deal with those links that match
this pattern (based on your symlink option, above).

=item OmitLinks - Do not deal with links that match this
pattern.

=back

Currently, some of the added functionality given to the rget method
is not implemented for the rput method.

=item rput ( [FlattenTree => 1] [,RemoveLocalFiles => 1] )

The recursive put method call.  This will recursively send the local
current working directory and its contents to the ftp object's current
working directory.

This will take an optional argument that will control what
happens when a symbolic link is encountered on the ftp
server.  The default is to ignore the symlink, but you can
control the behavior by passing one of these arguments to
the rput call (ie, $ftp->rput(SymlinkIgnore => 1)):

=over

=item SymlinkIgnore - disregards symlinks

=item SymlinkCopy - will copy the link target from the client to the server.

=item SymLinkFollow - will recurse into a symlink if it
points to a directory.  This does not do cycle checking, use
with EXTREME caution.  This option may be given along with one of
the others above.

=back

The C<FlattenTree> optional argument will send all of the
files from the local directory structure and place them in
the current remote directory.  This option will resolve
filename conflicts by sending files with the same name
and renaming them in a "$filename.$i" fashion, where $i is
the number of times it has retrieved a file with that name.

The optional C<RemoveLocalFiles> argument to the function
will allow the client to delete files from the client after
it sends them.  The default behavior is to leave all files
and directories intact.  This option is very unintelligent,
it does a delete no matter what.

As of v1.11, there is a C<CheckSizes> option that can be
used in conjunction with the C<RemoveLocalFiles> that will
check the filesize of the file locally against the remote
filesize and only delete if the two are the same.  This
option only affects regular files, not symlinks or
directories.  This option does not affect the normal
behavior of C<RemoveRemoteFiles> option (ie, it will try to
delete symlinks and directories no matter what).

=item rdir ( Filehandle => $fh
         [, FilenameOnly => 1 [, PrintType => 1] ]
         [, ParseSub => \&yoursub ] )

The recursive dir method call.  This will recursively retrieve
directory contents from the server in a breadth-first fashion.

The method needs to be passed a filehandle to print to.  The method
call just does a C<print $fh>, so as long as this call can succeed
with whatever you pass to this function, it'll work.

The second, optional argument, is to retrieve only the filenames
(including path information).  The default is to display all of the
information returned from the $ftp-dir call.

This method B<WILL> follow symlinks.  It has the same basic
cycle-checking code that is in rget, so it should not infinitely
loop.

The C<PrintType> argument will print either an 's', an 'f',
or a 'd' after the filename when printed, to tell you what
kind of file it thinks it is.  This argument must be given
along with the FilenameOnly argument.  (Submitted by Arturas
Slajus).

=item rls ( Filehandle => $fh
        [, PrintType => 1 ]
        [, ParseSub => \&yoursub] )

The recursive ls method call.  This will recursively
retrieve directory contents from the server in a
breadth-first fashion.  This is equivalent to calling
C<$ftp->rdir( Filehandle => $fh, FilenameOnly => 1 )>.

There is also a new argument to this, the C<PrintType>
referenced in the rdir part of the documentation.  For rls,
the FilenameOnly argument is automatically passed.

=item rdelete ( [ ParseSub => \&yoursub ] )

The recursive delete method call.  This will recursively
delete everything in the directory structure.  This
disregards the C<SymlinkFollow> option and does not recurse
into symlinks that refer to directories.

=back

=head1 Net::FTP::Recursive::File

This is a helper class that encapsulates the data
representing one file in a directory listing.

=head1 METHODS

=over

=item new ( )

This method creates the File object.  It should be passed
several parameters.  It should always be passed:

=over

=item OriginalLine => $line

=item Fields => \@fields

=back

And it should also be passed at least one (but only one a
true value) of:

=over

=item IsPlainFile => 1

=item IsDirectory => 1

=item IsSymlink => 1

=back

OriginalLine should provide the original line from the
output of a directory listing.

Fields should provide an 8 element list that supplies
information about the file.  The fields, in order, should
be:

=over

=item Permissions

=item Link Count

=item User Owner

=item Group Owner

=item Size

=item Last Modification Date/Time

=item Filename

=item Link Target

=back

The C<IsPlainFile>, C<IsDirectory>, and C<IsSymlink> fields
need to be supplied so that for the output on your
particular system, your code (in the ParseSub) can determine
which type of file it is so that the Recursive calls can
take the appropriate action for that file.  Only one of
these three fields should be set to a "true" value.

=back

=head1 TODO LIST

=over

=item Allow for formats to be given for output on rdir/rls.

=back

=head1 REPORTING BUGS

When reporting bugs, please provide as much information as possible.
A script that exhibits the bug would also be helpful, as well as
output with the "Debug => 1" flag turned on in the FTP object.

=head1 AUTHOR

Jeremiah Lee <texasjdl_AT_yahoo.com>

=head1 SEE ALSO

L<Net::FTP>

L<Net::Cmd>

ftp(1), ftpd(8), RFC 959

=head1 CREDITS

Thanks to everyone who has submitted bugs over the years.

=head1 COPYRIGHT

Copyright (c) 2009 Jeremiah Lee.

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

