package Muck::FS::VFS;

# Virtual File System operations

# needs to be able to see $fuse_self

use File::Basename;
use IO::File;
use POSIX qw(ENOENT ENOSYS EEXIST EPERM O_RDONLY O_RDWR O_APPEND O_CREAT);
use Fcntl qw(S_ISBLK S_ISCHR S_ISFIFO S_IFDIR S_IFLNK SEEK_SET);
use Data::Dumper;
use POE::Component::IKC::ClientLite;
#use threads;
#use threads::shared;
use strict;

use constant BLOCK => 4096;

# these are up front in an array so the Muck::FS can pre-prepare these
# and cache the resulting statement handles for re-use
our @statements = ( 
   { name => 'chown_uid',
      sql => 'UPDATE inodes SET uid=? WHERE inode=?' },
   { name => 'chown_gid',
      sql => 'UPDATE inodes SET gid=? WHERE inode=?' },
   { name => 'chown_uid_gid',
      sql => 'UPDATE inodes SET uid=?, gid=? WHERE inode=?' },
   { name => 'chmod',
      sql => 'UPDATE inodes SET mode=? WHERE inode=?' },
   { name => 'getattr',
      sql => 'SELECT inode, mode, uid, gid, atime, mtime, ctime, ' .
             'size, dirty, cachetime ' .
             'FROM inodes WHERE inode=? AND deleted = 0' },
   { name => 'inuse',
      sql => 'UPDATE inodes SET inuse = inuse + ? WHERE inode = ?' },
   { name => 'last_id',
      sql => 'SELECT LAST_INSERT_ID()'},
   { name => 'mkdir',
      sql => 'INSERT INTO tree (name, parent, inode) VALUES (?,?,?)' },
   { name => 'mknod_tree',
      sql => 'INSERT INTO tree (name, parent) VALUES (?,?)' },
   { name => 'mknod_inode',
      sql => 'INSERT INTO inodes ' .
             '(inode, mode, uid, gid, atime, ctime, mtime, dirty, cachetime) '.
             'VALUES(?, ?, ?, ?, UNIX_TIMESTAMP(NOW()), ' .
             'UNIX_TIMESTAMP(NOW()), UNIX_TIMESTAMP(NOW()), 1, ' .
             'UNIX_TIMESTAMP(NOW()) )' },
   { name => 'mksym',
      sql => 'INSERT INTO symlinks (inode, data) VALUES (?,?)' },
   { name => 'readdir',
      sql => 'SELECT name FROM tree WHERE parent = ?' },
   { name => 'read_symlink',
      sql => 'SELECT data FROM symlinks WHERE inode = ?' },
   { name => 'rename',
      sql => 'UPDATE tree SET name = ?, parent = ? ' .
             'WHERE inode = ? AND name = ? and parent = ?'},
   { name => 'rmdir',
      sql => 'DELETE FROM tree WHERE name=? AND parent=?' },
   { name => 'set_clean',
      sql => 'UPDATE inodes SET dirty=0 WHERE inode=?' },
   { name => 'set_deleted',
      sql => 'UPDATE inodes SET deleted=1 WHERE inode = ?' },
   { name => 'set_dirty',
      sql => 'UPDATE inodes SET size=?, dirty=1 WHERE inode=?' },
   { name => 'statfs',
      sql => 'SELECT count(*) AS inodes, sum(size) AS size ' .
             'FROM inodes WHERE deleted = 0' },
   { name => 'truncate',
      sql => 'UPDATE inodes SET size=? WHERE inode=?' },
   { name => 'update_utime',
      sql => 'UPDATE inodes SET atime=?, mtime=? WHERE inode=?' },
);

sub err { 
   my $msg = shift;
   $msg = "ERROR: " . $msg;
   return (-shift || -$!);
}

sub debug { 
   my ( $msg, $lvl ) = @_;
   $lvl ||= 1;
   my $debug = $Muck::FS::fuse_self->{debug};
   warn "DEBUG: $msg\n" if $debug >= $lvl;
}

#----------------------------------------------------------------------------
sub x_getattr {
#----------------------------------------------------------------------------
# - getattr from db
   debug("CALLBACK: x_getattr(@_)");
   my $file = shift;
   my ( $inode, $name, $parent, $nlink ) = path2inode($file);
   return -ENOENT() unless $inode;
   my $attr = db_retrieve('getattr', 2, $inode );
   return -$! unless $attr;
   my $blocks = int(($attr->[7]+BLOCK-1)/BLOCK);
   my @rtn = (
      0,             #  0 dev      device number of filesystem
      $inode,       #  1 ino      inode number
      $attr->[1],   #  2 mode     file mode  (type and permissions)
      $nlink,        #  3 nlink    number of (hard) links to the file
      $attr->[2],    #  4 uid      numeric user ID of file's owner
      $attr->[3],    #  5 gid      numeric group ID of file's owner
      0,             #  6 rdev     the device identifier (special files only)
      $attr->[7],    #  7 size     total size of file, in bytes
      $attr->[4],    #  8 atime    last access time in seconds since the epoch
      $attr->[5],    #  9 mtime    last modify time in seconds since the epoch
      $attr->[6],    # 10 ctime    inode change time in seconds since the epoch
      BLOCK,         # 11 blksize  preferred block size for file system I/O
      $blocks,       # 12 blocks   actual number of blocks allocated
      );
   return @rtn;
}

#----------------------------------------------------------------------------
sub x_getdir {
#----------------------------------------------------------------------------
# getdir listing from db
   debug("CALLBACK: x_getdir(@_)");
   my $dirname = shift;
   my ( $inode ) = path2inode($dirname);
   my $files = db_retrieve('readdir', 3, $inode );
   debug("RETURN: " . Dumper $files);
   if ( scalar @$files ) {
      return ('.', '..', @{ $files }, 0);
   } else {
      return ( '.', '..', 0);
   }
}

#----------------------------------------------------------------------------
sub x_open {
#----------------------------------------------------------------------------
   debug("CALLBACK: x_open(@_)");
   my ( $file, $mode ) = @_;
   my ( $cachefile, $inode, $cachetime, $dirty, $current ) = path2cache($file);
   if ( $dirty ) {
      # a new file - we need to make a cachefile that we can open
      system('touch', $cachefile);
   } elsif ( ! $current ) {
      fetchS3($inode, $cachetime);
   }
   db_execute('inuse', 1, $inode ); # increment inuse counter
   return -$! unless sysopen(FILE,$cachefile,$mode);
   close(FILE);
   debug("RETURN: 0");
   return 0;
}

#----------------------------------------------------------------------------
sub x_read {
#----------------------------------------------------------------------------
# we should have open() by now, so the file should be retrieved from S3
# and cached to local filesystem by now, otherwise we have a big error
   debug("CALLBACK: x_read(@_)");
	my ($file,$bufsize,$off) = @_;

   my $rfh = $Muck::FS::fuse_self->{Rfh_cache};

   unless ( $rfh->{$file} ) {
      my ( $cachefile, $inode, $cachetime, $dirty, $current ) = path2cache($file);

      ($rfh->{$file}) = new IO::File;
      return -ENOENT() unless -e $cachefile;
      my ($fsize) = -s $cachefile;
      return -ENOSYS() unless open($rfh->{$file},$cachefile);
   }
   my ($rv) = -ENOSYS();
   my $handle = $rfh->{$file};
   if(seek($handle,$off,SEEK_SET)) {
      read($handle,$rv,$bufsize);
   }
   return $rv;
}

#----------------------------------------------------------------------------
sub x_write {
#----------------------------------------------------------------------------
# - synchronously update the file on local and update DB
# - wait for release() to asynch write to S3
   my ($file,$buf,$off) = @_;
   debug("CALLBACK: x_write($file)");

   my $wfh = $Muck::FS::fuse_self->{Wfh_cache};
   unless ( $wfh->{$file} ) {
      my ( $cachefile, $inode, $cachetime, $dirty, $current ) = path2cache($file);
      return -ENOENT() unless -e $cachefile;
      my ($fsize) = -s $cachefile;
      return -ENOSYS() unless open($wfh->{$file},'+<',$cachefile);
   }
   my ($rv);
   my $handle = $wfh->{$file};
   if($rv = seek($handle,$off,SEEK_SET)) {
      $rv = print($handle $buf);
   }
   $rv = -ENOSYS() unless $rv;

   # TODO - set_dirty on first write, and every N writes thereafter
   #my ($curr_size) = (stat($cachefile))[7];
   #db_execute( 'set_dirty', $curr_size, $inode );

   return length($buf);
}

#----------------------------------------------------------------------------
sub x_release {
#----------------------------------------------------------------------------
# - check our inode states in db 
# - trigger asynch replicate from cachefile to S3 if needed
   debug("CALLBACK: x_release(@_)");
   my $file = shift;

   my ( $cachefile, $inode, $cachetime, $dirty, $current ) = path2cache($file);

   my $wfh = $Muck::FS::fuse_self->{Wfh_cache};
   if ( $wfh->{$file} ) {
      close $wfh->{$file};
      delete $wfh->{$file};
      my ($curr_size) = (stat($cachefile))[7];
      db_execute( 'set_dirty', $curr_size, $inode );
   }
   my $rfh = $Muck::FS::fuse_self->{Rfh_cache};
   if ( $rfh->{$file} ) {
      close $rfh->{$file};
      delete $rfh->{$file};
   }
   db_execute('inuse', -1, $inode ); # decrement inuse counter
   if ( $dirty ) {
      storeS3($inode, $cachetime); # triggers a call to muckd lazy writer
      # set clean will be done by the muckd lazy writer when complete
   }
   return 0;
}


#----------------------------------------------------------------------------
sub x_readlink { 
#----------------------------------------------------------------------------
# this should just be a db read - no cachefile/S3 intereaction needed
   debug("CALLBACK: x_readlink(@_)");
   my $symlink = shift;
   my ( $inode, $name, $parent, $nlinks ) = path2inode($symlink);
   my $sympath = db_retrieve('read_symlink', 1, $inode );
   return $sympath;
}

#----------------------------------------------------------------------------
sub x_unlink { 
#----------------------------------------------------------------------------
#  - mark the inode in the DB to prevent other clients from getting this
#  - leave the cahce/S3 alone so that we can undelete later
   debug("CALLBACK: x_unlink(@_)");
   my $file = shift;
   my ( $inode, $name, $parent, $nlinks ) = path2inode($file, 'NOCACHE' );
   db_execute('rmdir', $name, $parent );

   # we need to delete cache before our nlinks check to make sure every 
   # path that is linked to this inode is removed from memcache
   my $memcache = $Muck::FS::fuse_self->{memcached};
   $memcache->delete($file);

   # Only the last unlink() must set deleted flag.
   # This is a shortcut - query_set_deleted() wouldn't
   # set the flag if there is still an existing direntry
   # anyway. But we'll save some DB processing here. */
   return 0 if defined $nlinks and $nlinks > 1;
      
   db_execute('set_deleted', $inode );

   # no datastore purging since we want to have undelete
   return 0;
}

#----------------------------------------------------------------------------
sub x_symlink { 
#----------------------------------------------------------------------------
   debug("CALLBACK: x_symlink(@_)");
   my ( $from, $to ) = @_;
   x_mknod( $to, S_IFLNK | 0755 );
   my ( $to_inode )  = path2inode( $to );
   db_execute('mksym', $to_inode, $from );
   return 0;
}

#----------------------------------------------------------------------------
sub x_rename {
#----------------------------------------------------------------------------
# update tree to point to same old inode content
   debug("CALLBACK: x_rename(@_)");
   my ( $oldpath, $newpath )  = @_;

   my ( $inode ) = path2inode($oldpath);
   my ( $parent_from ) = path2inode( dirname( $oldpath ) );
   my $oldname = basename( $oldpath );

   my ( $parent_to ) = path2inode( $newpath );
   my $newname = basename( $newpath );

   x_unlink( $oldpath );
   db_execute('rename', $newname, $parent_to, $inode, $oldname, $parent_from);

   my $memcache = $Muck::FS::fuse_self->{memcached};
   $memcache->delete($oldpath);

   return 0;
}

#----------------------------------------------------------------------------
sub x_link { 
#----------------------------------------------------------------------------
# update db to link the two inodes - no cachefile/S3 changes needed
   debug("CALLBACK: x_link(@_)");
   my ( $from, $to ) = @_;
   my ( $source_inode ) = path2inode($from);
   my $targetdir = dirname($to);
   my ( $new_parent ) = path2inode($targetdir);
   db_execute('mkdir', basename($to), $new_parent, $source_inode );

   my $memcache = $Muck::FS::fuse_self->{memcached};
   $memcache->delete($from); # purge from cache to allow regen of nlinks
   # TODO - should really look for any other paths that use this same inode
   #        and delete their caches too so that nlinks will get fixed in cache

   return 0;
}

#----------------------------------------------------------------------------
sub x_chown {
#----------------------------------------------------------------------------
# update db only - no cachefile/s3 changes needed
   debug("CALLBACK: x_chown(@_)");
   my ( $file, $uid, $gid ) = @_;
   my ( $inode ) = path2inode( $file );
   if ( $uid and $gid ) {
      db_execute('chown_uid_gid', $uid, $gid, $inode);
   } elsif ( $uid ) {
      db_execute('chown_uid', $uid, $inode);
   } elsif ( $gid ) {
      db_execute('chown_gid', $gid, $inode);
   }
   return 0;
}

#----------------------------------------------------------------------------
sub x_chmod {
#----------------------------------------------------------------------------
# update db only - no cachefile/s3 changes needed
   debug("CALLBACK: x_chmod(@_)");
   my ( $file, $mode ) = @_;
   my ( $inode ) = path2inode($file);
   db_execute('chmod', $mode, $inode);
   return 0;
}

#----------------------------------------------------------------------------
sub x_truncate { 
#----------------------------------------------------------------------------
# - update db, 
# - truncate cachefile
# - let release handle asynch to S3
   debug("CALLBACK: x_truncate(@_)");
   my ( $file, $length ) = @_;
   my ( $inode ) = path2inode($file);
   db_execute('truncate', $length, $inode);
   my ( $cachefile, $inod2, $cachetime, $dirty, $current ) = path2cache($file);
   #TODO - this should be trunacting a new snapshot
   return truncate($cachefile,$length) ? 0 : -$! ; 
}

#----------------------------------------------------------------------------
sub x_utime { 
#----------------------------------------------------------------------------
# - update db only
   debug("CALLBACK: x_utime(@_)");
   my ($file, $atime, $mtime) = @_;
   my ( $inode ) = path2inode($file);
   my $ok = db_execute('update_utime',$atime, $mtime, $inode);
   return ($ok ? 0 : 1 );
}

#----------------------------------------------------------------------------
sub x_mkdir { 
#----------------------------------------------------------------------------
# update db only
   debug("CALLBACK: x_mkdir(@_)");
   my ($file, $mode) = @_; 

   err("Directory name is too long: $file") if too_long($file);
   my $parentpath = dirname($file);
   my ( $parent ) = path2inode($parentpath);
   db_execute('mknod_tree', basename($file), $parent );
   my $inode = db_retrieve('last_id', 1);
   my ( $uid, $gid ) = get_current_user();
   db_execute('mknod_inode', $inode, S_IFDIR | $mode, $uid, $gid );
   return 0;
}

#----------------------------------------------------------------------------
sub x_mknod {
#----------------------------------------------------------------------------
# update db only
   debug("CALLBACK: x_mknod(@_)");
	my ($file, $mode, $dev) = @_;

   err("Node name is too long: $file") if too_long($file);
   if ( $file eq '/' ) {
      db_execute('mknod_tree', '/', undef);
   } else {
      # get basepath
      my $parentpath = dirname($file);
      my ( $parent ) = path2inode($parentpath);
      db_execute('mknod_tree', basename($file), $parent );
      my $inode = db_retrieve('last_id', 1);
      my ( $uid, $gid ) = get_current_user();
      db_execute('mknod_inode', $inode, $mode, $uid, $gid  );

      # why am i calling this when I'm not returning anything????
      my( $cachefile, $inod2, $cachetime, $dirty, $current ) = path2cache($file);
      return 0;
   }
   return 0;
}

# kludge - TODO
#----------------------------------------------------------------------------
sub x_statfs {
   debug("CALLBACK: x_statfs()");
   #$namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize
   my $used = db_retrieve('statfs', 4 );
   my $used_blocks = int(($used->{size}+BLOCK-1)/BLOCK);

   my $max_blocks = 262144000; # 1 Terabyte
   my $max_inodes = 1000000000;
   #my $max_inodes = 18446744073709551615; # max bigint value
   my @out = (
      1024,                         # namelen
      $max_inodes,
      $max_inodes - $used->{inodes}, # available inodes
      $max_blocks,
      $max_blocks - $used_blocks,   # available blocks
      BLOCK,                        # blocksize
   );
   return @out;
}

#----------------------------------------------------------------------------


#----------------------------------------------------------------------------
sub db_execute {
#----------------------------------------------------------------------------
   #debug("INTERNAL: db_execute(@_)");
   my $statement = shift;
   my @bindings  = @_;
   my $dbh = $Muck::FS::fuse_self->{dbh};
   my $sth = $Muck::FS::fuse_self->{sth}->{$statement};
   if ( ! sth_execute( $dbh, $sth, @bindings ) ) {
      warn "update problem: " . $sth->errstr;
      $dbh->rollback || err($dbh->errstr);
      return 0;
   }
   if ( ! $dbh->commit ) {
      warn "ERROR: commit problem: ", $sth->errstr;
      $dbh->rollback || err($dbh->errstr);
      return 0;
   }
   #debug("DB SUCCESS: $statement( @bindings )");
   return 1;
}

#----------------------------------------------------------------------------
sub db_retrieve {
#----------------------------------------------------------------------------
   debug("INTERNAL: db_retrieve(@_)");
   my $statement = shift;
   my $rtn_type = shift;
   my $dbh = $Muck::FS::fuse_self->{dbh};
   my $sth = $Muck::FS::fuse_self->{sth}->{$statement};
   my $rv;
   if ( ! sth_execute( $dbh, $sth, @_) ) {
      err("db read problem: " . $sth->errstr);
      return 0;
   } 
   if ( $rtn_type == 1 ) { # scalar - first field from first row
      ( $rv ) = $sth->fetchrow_array; 
   } elsif ( $rtn_type == 2 ) { # array of fields from first row
      $rv = $sth->fetchrow_arrayref; 
   } elsif ( $rtn_type == 3 ) { # array of rows (assuming one field per row)
      $rv = [];
      while ( my ( $value ) = $sth->fetchrow_array ) {
         push( @$rv, $value );
      }
      #$rv = $sth->fetchall_arrayref([0]);
   } elsif ( $rtn_type == 4 ) { # hash of fields from first row
      $rv = $sth->fetchrow_hashref; 
   }
   $sth->finish;
   debug("RETURN: " . Dumper $rv);
   return $rv;
}

sub sth_execute {
   my $dbh = shift;
   my $sth = shift;
   my @bindings = @_;
   for my $attempt ( 0..3 ) {
      if ( ! $sth->execute(@bindings) ) {
         # Our attempt failed, so lets try and wake it up with a ping
         if ( ! $dbh->ping() ) {
            # ping failed, so lets try to reconnect from scratch
            sleep 1;
            #eval {
               # reconnect to DB
               # TODO $dbh = DBI->connect( stuff );
            #}
            # TODO $sth = $self->pre-prepare();
            next; # do another attempt with our new connection
         } # if here, our ping succeeded, so our next attempt should work
      } # if here, our execute succeeded, so return true
      return 1;
   } # if here, we failed after multiple attempts
   err("ERROR: UNABLE TO CONNECT TO MYSQL - $DBI::errstr");
}

sub path2inode {
   debug("INTERNAL: path2inode(@_)");
   my $path = shift;
   my $NOCACHE = shift;
   my $memcache = $Muck::FS::fuse_self->{memcached};
   my $rv = $memcache->get( $path );
   debug("MEMCACHE: " . Dumper $rv) unless $NOCACHE;
   if ( ! $rv or $NOCACHE ) {
      my $dbh = $Muck::FS::fuse_self->{dbh};
      my ( @from, @where, @sql, $sth );
      my $depth = 0;
   
      push( @from, "tree AS t0" );
      push( @where, "t0.parent IS NULL");
      foreach my $name ( split (/\//, $path ) ) {
         next unless $name;
         debug("SPLIT: name = $name");
         $depth++;
         my $p = my $d = $depth;
         $p--;
         push(@from, "LEFT JOIN tree AS t$d ON t$p.inode = t$d.parent");
         push(@where, "AND t$d.name = '$name'");
      }
      my $n = my $d = $depth;
      $n++;
      push(@sql, "SELECT t$d.inode, t$d.name, t$d.parent,");
      push(@sql, "(SELECT COUNT(inode) FROM tree AS t$n " .
                 "WHERE t$n.inode=t$d.inode)");
      push(@sql, "AS nlinks");
   
      push(@sql, "FROM", @from);
      push(@sql, "WHERE", @where);
      my $sql = join(" ", @sql);
   
      debug("SQL: $sql");
      $sth = $dbh->prepare($sql) or warn "db prepare problem: " . $sth->errstr;
      $sth->execute or warn "db read problem: " . $sth->errstr;
      my ( $inode, $name, $parent, $nlinks ) = $sth->fetchrow_array;
      $sth->finish;
      $rv = [ $inode, $name, $parent, $nlinks ];

      # if we are unlinking, we really don;t want to cache this and confuse
      # subsequent path2inode requests since this is going away, so don't
      # cache if NOCACHE
      $memcache->set( $path, $rv ) if $inode and ! $NOCACHE;
   }
 
   debug("RETURN: " . Dumper $rv );
   return @{ $rv };
}

sub path2cache {
   debug("INTERNAL: path2cache(@_)");
   my $path = shift;
   my $cachepath = $Muck::FS::fuse_self->{cachedir};
   my ( $inode ) = path2inode( $path );
   my $i = db_retrieve('getattr', 4,  $inode);
   my $istamp = inode_timestamp($inode, $i->{cachetime} );
   my $cachefile = $cachepath . $istamp;
   my $current = ( -e $cachefile ? 1 : 0 ); # TODO - handle empty files
   return $cachefile, $i->{inode}, $i->{cachetime}, $i->{dirty}, $current;
}

sub fetchS3 {
   debug("INTERNAL: fetchS3(@_)");
   my $inode = shift;
   my $timestamp = shift;

   my $cachepath = $Muck::FS::fuse_self->{cachedir};
   my $bucket    = $Muck::FS::fuse_self->{s3_bucket};
   my $istamp = inode_timestamp($inode, $timestamp);
   my $cachefile  = $cachepath . $istamp;
   my $conn = $Muck::FS::fuse_self->{S3conn};

   my $response = $conn->get( $bucket, $istamp );
   my $rc = $response->http_response->code;
   debug("fetchS3 RC: $rc");
   # TODO - add auto retry?
   if ( $rc == 200 ) {
      open ( my $out, '>', $cachefile ) or warn "Unable to open cachefile";
      print $out $response->object->data;
      close $out;
   } else {
      # TODO - error reading from S3!!!
   }
}

sub storeS3 {
   debug("INTERNAL: storeS3(@_)");
   my $inode = shift;
   my $timestamp = shift;

   my $cachepath = $Muck::FS::fuse_self->{cachedir};
   my $bucket    = $Muck::FS::fuse_self->{s3_bucket};
   debug("S3 bucket: $bucket");
   debug("S3 cachedir: $cachepath");
   my $istamp = inode_timestamp($inode, $timestamp);
   my $cachefile  = $cachepath . $istamp;

   return if -z $cachefile; # no need to store an empty file

   my $muckd = create_ikc_client(
                              ip => '127.0.0.1',
                              port => 38422,
                              name => "MUCKFS-$$" );

   if ( $muckd and $muckd->ping ) {
      # if the muckd daemon is available, store to S3 asynchrnously
      $muckd->post( "MUCKD/storeS3", { cachefile => $cachefile,
                                       istamp => $istamp,
                                       inode => $inode } )
         or err( $muckd->error );

   } else {
      # otherwise fall back to doing this synchronously 

      my $conn = $Muck::FS::fuse_self->{S3conn}; 
  
      my $contents = slurp($cachefile); 
      my $try = 0;
      my $rc = 0;
      while ( $try < 5 ) {
         my $response = $conn->put( $bucket, $istamp, $contents );
         $rc = $response->http_response->code;
         debug("storeS3 RC: $rc, try: $try");
         $try++;
         last if $rc == 200;
      }
      if ( $rc == 200 ) {
         db_execute('set_clean', $inode );
      } else {
         # TODO - handle failure of write to S3!!!
      }
   }
   return;
}

sub too_long {
   my $filename = shift;
   return ( length($filename) > 1024 ? 1 : 0 );
}

sub inode_timestamp {
   my $inode = shift;
   my $epoch = shift;
   my ( $sec, $min, $hour, $day, $mon, $year ) = localtime($epoch);
   $mon++; $year+=1900;
   return sprintf("%09d", $inode) .
          '@' .
          sprintf("%04d%02d%02d%02d%02d%02d", 
                  $year, $mon, $day, $hour, $min, $sec );
}

sub slurp {
   my $path = shift;
   # TODO - get fancy and determine mime-type? do binmode? maybe ascii armor??
   open( my $in, '<', $path);
   my $contents = do { local $/; <$in> };
   close $in;
   return $contents;
}

sub get_current_user {
   my ( $uid, $gid, $pid ) = &Muck::FS::get_context();
   return ( $uid, $gid );
}

1;

__END__

=head1 ACKNOWLEDGEMENTS

Special thanks to:

Tsukasa Hamano <code@cuspy.org>
Michal Ludvig <michal@logix.cz> http://www.logix.cz/michal

for their work on mysqlfs.  Their schema and C code were the basis of the 
virtual inodes.  Thanks as well to the authors of Fuse (for the loopback
example) and Fuse::DBI.

=cut

