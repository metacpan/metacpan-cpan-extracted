package Sys::Export::Unix;

# ABSTRACT: Export subsets of a UNIX system
our $VERSION = '0.001'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use Carp qw( croak carp );
use Cwd qw( abs_path );
use Fcntl qw( S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT 
              S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFMT );
use Scalar::Util qw( blessed looks_like_number );
use Sys::Export qw( :isa );
use File::Temp ();
use POSIX ();
require Sys::Export::Exporter;
our @ISA= qw( Sys::Export::Exporter );
our $have_file_map= eval { require File::Map; };
our $have_unix_mknod= eval { require Unix::Mknod; };
my sub isa_hash   :prototype($) { ref $_[0] eq 'HASH' }
my sub isa_array  :prototype($) { ref $_[0] eq 'ARRAY' }
my sub isa_int    :prototype($) { looks_like_number($_[0]) && int($_[0]) == $_[0] }

sub new {
   my $class= shift;
   my %attrs= @_ == 1 && isa_hash $_[0]? %{$_[0]}
      : !(@_ & 1)? @_
      : croak "Expected hashref or even-length list";

   defined $attrs{src} or croak "Require 'src' attribute";
   my $abs_src= abs_path($attrs{src} =~ s,(?<=[^/])$,/,r)
      or croak "src directory '$attrs{src}' does not exist";
   $attrs{src_abs}= $abs_src eq '/'? $abs_src : "$abs_src/";

   defined $attrs{dst} or croak "Require 'dst' attribute";
   if (isa_export_dst $attrs{dst}) {
      $attrs{_dst}= $attrs{dst};
   } else {
      my $dst_abs= abs_path($attrs{dst} =~ s,(?<=[^/])$,/,r)
         or croak "dst directory '$attrs{dst}' does not exist";
      length $dst_abs > 1
         or croak "cowardly refusing to export to '$dst_abs'";
      require Sys::Export::Unix::WriteFS;
      $attrs{_dst}= Sys::Export::Unix::WriteFS->new(
         dst          => $attrs{dst},
         tmp          => $attrs{tmp},
         on_collision => $attrs{on_collision},
      );
   }
   # default tmp dir to whatever dst chose, if it has a preference
   $attrs{tmp} //= $attrs{_dst}->tmp
      if $attrs{_dst}->can('tmp');
   # otherwise use system tmp dir
   $attrs{tmp} //= File::Temp->newdir;

   my $self= bless \%attrs, $class;

   $self->_build_log_fn($self->{log} //= 'info');

   for my $method (qw( rewrite_path rewrite_user rewrite_group )) {
      my $r= delete $self->{$method}
         or next;
      $self->$method($_ => $r->{$_})
         for keys %$r;
   }
   return $self;
}


sub src($self)          { $self->{src} }
sub src_abs($self)      { $self->{src_abs} }
sub dst($self)          { $self->{dst} }  # sometimes a path string
sub _dst($self)         { $self->{_dst} } # always an object
sub dst_abs($self)      { $self->{_dst}->can('dst_abs')? $self->{_dst}->dst_abs : undef }
sub tmp($self)          { $self->{tmp} }
sub src_path_set($self) { $self->{src_path_set} //= {} }
sub dst_path_set($self) { $self->{dst_path_set} //= {} }
sub dst_uid_used($self) { $self->{dst_uid_used} //= {} }
sub dst_gid_used($self) { $self->{dst_gid_used} //= {} }


sub path_rewrite_regex($self) {
   $self->{path_rewrite_regex} //= do {
      my $rw= $self->{path_rewrite_map} // {};
      !keys %$rw? qr/(*FAIL)/
      : qr/(@{[ join '|', map quotemeta, reverse sort keys %{$self->{path_rewrite_map}} ]})/;
   };
}

# a hashref tracking files with link-count higher than 1, so that hardlinks can be preserved.
# the keys are "$dev:$ino"
sub _link_map($self) { $self->{link_map} //= {} }

# a hashref listing all the interpreters that have been discovered for programs
# and scripts copied to dst.  The keys are the relative source path.
sub _elf_interpreters($self) { $self->{elf_interpreters} //= {} }

sub DESTROY($self, @) {
   $self->finish if $self->{_delayed_apply_stat};
}


sub log {
   if (@_ > 1) {
      $_[0]->_build_log_fn($_[1]);
      $_[0]{log}= $_[1];
   }
   $_[0]{log}
}

# This is a silly approximation of Log::Any to avoid having that as a dependency
our %LOG_LEVELS = (
   EMERGENCY => 0,
   ALERT     => 1,
   CRITICAL  => 2,
   ERROR     => 3,
   WARNING   => 4,
   NOTICE    => 5,
   INFO      => 6,
   DEBUG     => 7,
   TRACE     => 8,
);
sub _build_log_fn($self, $dest) {
   if (ref $dest && $dest->can('info')) {
      $self->{_log_info}=  $dest->is_info?  sub { $dest->info(@_) }  : undef;
      $self->{_log_debug}= $dest->is_debug? sub { $dest->debug(@_) } : undef;
      $self->{_log_trace}= $dest->is_trace? sub { $dest->trace(@_) } : undef;
   } elsif (my $i_lev= $LOG_LEVELS{uc $dest}) {
      $self->{_log_info}=  $LOG_LEVELS{INFO}  <= $i_lev? sub { say @_ } : undef;
      $self->{_log_debug}= $LOG_LEVELS{DEBUG} <= $i_lev? sub { say @_ } : undef;
      $self->{_log_trace}= $LOG_LEVELS{TRACE} <= $i_lev? sub { say @_ } : undef;
   } else {
      croak "Log '$dest' is not a Log::Any instance or known log level";
   }
}

sub _log_action($self, $verb, $src, $dst, @notes) {
   if ($self->{_log_info}) {
      $self->{_log_info}->(sprintf "%3s %-20s -> %s", $verb, $src, $dst);
      $self->{_log_info}->(sprintf "     %s", $_) for @notes;
   }
}


sub rewrite_path($self, $orig, $new) {
   my $rw= ($self->{path_rewrite_map} //= {});
   $orig =~ s,^/,,;
   $new =~ s,^/,,;
   $orig !~ m,^[.]+/, && $new !~ m,^[.]+/,
      or croak "Paths for rewrite_path must be logically absolute ($orig => $new)";
   croak "Conflicting rewrite supplied for '$orig'"
      if exists $rw->{$orig} && $rw->{$orig} ne $new;
   $rw->{$orig}= $new;
   delete $self->{path_rewrite_regex}; # lazy-built
   $self;
}

sub _has_rewrites($self) {
   $self->{path_rewrite_map} && %{$self->{path_rewrite_map}}
}

# Resolve symlinks in paths within $root/ treating absolute links as references to $root.
# This returns undef if:
#   * the path doesn't exist at any point during resolution
#   * 'stat' fails at any point in the path (maybe for permissions)
#   * it resolves more than 256 symlinks
#   * readlink fails
# Un-intuitively, this returns a string without a leading '/' because that's what I need below.
sub _chroot_abs_path($self, $root, $path) {
   my @base= split '/', $root;
   my @abs= @base;
   my @parts= grep length && $_ ne '.', split '/', $path;
   my $lim= 256;
   while (@parts) {
      my $part= shift @parts;
      my $abs= join '/', @abs, $part;
      my (undef, undef, $mode)= lstat $abs
         or return undef;
      if ($part eq '..') {
         # In Linux at least, ".." from root directory loops back to itself
         pop @abs if @abs > @base;
      }
      elsif (S_ISLNK($mode)) {
         return undef if --$lim <= 0;
         defined (my $newpath= readlink $abs) or return undef;
         @abs= @base if $newpath =~ m,^/,;
         unshift @parts, grep length && $_ ne '.', split '/', $newpath;
      }
      else {
         push @abs, $part;
      }
   }
   my $abs= join '/', @abs[scalar @base .. $#abs];
   $self->{log_trace}->("Absolute path of '$path' within root '$root' is '$abs'")
      if $self->{log_trace} && $abs ne $path;
   return $abs;
}

sub _src_abs_path($self, $path) {
   $self->_chroot_abs_path($self->{src_abs}, $path);
}


sub rewrite_user($self, $src, $dst) {
   croak "A rewrite already exists for $src"
      if $self->{_user_rewrite_map}{$src};

   if (!isa_int($dst)) {
      my $dst_userdb= ($self->{dst_userdb} //= $self->_build_dst_userdb);
      my $u= $dst_userdb->user($dst)
         or croak "No user '$dst' in dst_userdb";
      $dst= $u->uid;
   }
   if (!isa_int($src)) {
      # The name must exist in src userdb
      my $src_userdb= ($self->{src_userdb} //= $self->_build_src_userdb);
      my $u= $src_userdb->user($src)
         or croak "No user '$src' in src_userdb";
      $self->{_user_rewrite_map}{$src}= $dst;
      $src= $u->uid;
   }
   $self->{_user_rewrite_map}{$src}= $dst;
}

sub rewrite_group($self, $src, $dst) {
   croak "A rewrite already exists for $src"
      if $self->{_group_rewrite_map}{$src};

   if (!isa_int($dst)) {
      my $dst_userdb= ($self->{dst_userdb} //= $self->_build_dst_userdb);
      my $g= $dst_userdb->group($dst)
         or croak "No group '$dst' in dst_userdb";
      $dst= $g->gid;
   }
   if (!isa_int($src)) {
      # The name must exist in src userdb
      my $src_userdb= ($self->{src_userdb} //= $self->_build_src_userdb);
      my $g= $src_userdb->group($src)
         or croak "No group '$src' in src_userdb";
      $self->{_group_rewrite_map}{$src}= $dst;
      $src= $g->gid;
   }
   $self->{_group_rewrite_map}{$src}= $dst;
}

sub _build_src_userdb($self) {
   # The default source UserDB pulls from src/etc/passwd and auto_imports users from the host
   my $udb= Sys::Export::Unix::UserDB->new(auto_import => 1);
   $udb->load($self->src_abs . 'etc')
      if -f $self->src_abs . 'etc/passwd';
   $udb;
}

sub _build_dst_userdb($self) {
   # The default dest UserDB uses any dst/etc/passwd and auto_imports users from src_userdb
   my $udb= Sys::Export::Unix::UserDB->new(
      auto_import => ($self->{src_userdb} //= $self->_build_src_userdb)
   );
   $udb->load($self->_dst->dst_abs . 'etc')
      if defined $self->_dst->can('dst_abs') && -f $self->_dst->dst_abs . 'etc/passwd';
   # make sure the rewrite hashes exist, used as a flag that rerites need to occur.
   $self->{_user_rewrite_map} //= {};
   $self->{_group_rewrite_map} //= {};
   $udb;
}


sub add {
   my $self= shift;
   my $add= ($self->{add} //= []);
   my $dst_userdb;
   push @$add, @_;
   while (@$add) {
      my $next= shift @$add;
      my %file;
      if (ref $next eq 'HASH') {
         $self->{_log_debug}->("Exporting @{[ $next->{src_path}//'' ]} to $next->{name}")
            if $self->{_log_debug};
         %file= %$next;
      } elsif (ref $next eq 'ARRAY') {
         %file= _attrs_from_array_notation(@$next);
      } else {
         $next =~ s,^/,,;
         $self->{_log_debug}->("Exporting $next")
            if $self->{_log_debug};
         @file{qw( dev ino mode nlink uid gid rdev size atime mtime ctime )}= lstat($self->{src_abs}.$next)
            or croak "lstat '$self->{src_abs}$next': $!";
         # Remap the UID/GID if that feature was requested
         @file{'uid','gid'}= $self->get_dst_uid_gid(@file{'uid','gid'}, " in source filesystem at '$next'")
            if $self->{_user_rewrite_map} || $self->{_group_rewrite_map};
         # If $next is itself a symlink, we want to export this name, and also the thing
         # it references.
         if (S_ISLNK($file{mode})) {
            # resolve symlinks in the path leading up to this symlink
            my $parent= $next =~ s,[^/]+$,,r;
            $next= $self->_src_abs_path($parent) . ($next =~ m,(/[^/]+)$,)[0]
               if length $parent;
            # add this symlink target to the paths to be exported
            my $target= readlink($self->{src_abs}.$next);
            my $full_target= $target =~ m,^/,? $target : $parent . $target;
            $self->{_log_debug}->("Symlink to '$target', queueing '$full_target'") if $self->{_log_debug};
            unshift @$add, $full_target;
         } else {
            # Resolve symlinks within src/ to get the true identity of this file
            my $abs= $self->_src_abs_path($next);
            defined $abs or croak "Can't resolve absolute path of '$next'";
            $self->{_log_debug}->("Resolved to '$abs'") if $self->{_log_debug} && $abs ne $next;
            $next= $abs;
         }
         # ignore repeat requests
         if (exists $self->{src_path_set}{$next}) {
            $self->{_log_debug}->("  (already exported '$next')") if $self->{_log_debug};
            next;
         }
         $file{src_path}= $next;
         $file{data_path}= $self->{src_abs} . $next;
         $file{name}= $self->get_dst_for_src($next);
         $self->{src_path_set}{$next}= $file{name};
      }

      if (defined $file{user} && !defined $file{uid}) {
         $dst_userdb //= ($self->{dst_userdb} //= $self->_build_dst_userdb);
         my $u= $dst_userdb->user($file{user})
            // croak "Unknown user '$file{user}' for file '$file{name}'";
         $file{uid}= $u->uid;
      }
      ++$self->{dst_uid_used}{$file{uid}} if defined $file{uid};

      if (defined $file{group} && !defined $file{gid}) {
         $dst_userdb //= ($self->{dst_userdb} //= $self->_build_dst_userdb);
         my $g= $dst_userdb->group($file{group})
            // croak "Unknown group '$file{group}' for file '$file{name}'";
         $file{gid}= $g->gid;
      }
      ++$self->{dst_gid_used}{$file{gid}} if defined $file{gid};

      # Has this destination already been written?
      if (exists $self->{dst_path_set}{$file{name}}) {
         my $orig= $self->{dst_path_set}{$file{name}};
         # If the destination is ::WriteFS, let it handle the collision below
         unless ($self->_dst->can('dst_abs')) {
            my $action= $self->on_collision // 'ignore_if_same';
            $action= $action->($file{name}, \%file)
               if ref $action eq 'CODE';
            if ($action eq 'ignore_if_same') {
               $action= ($file{src_path}//'') eq $orig? 'ignore' : 'croak';
            }
            if ($action eq 'ignore') {
               $self->{_log_debug}->("Already exported to '$file{name}' previously from '$orig'") if $self->{_log_debug};
               next;
            } elsif ($action eq 'overwrite') {
               $self->{_log_debug}->("Overwriting '$file{name}'") if $self->{_log_debug};
               # let dst handle overwrite...
            } elsif ($action eq 'croak') {
               croak "Already exported '$file{name}'".(length $orig? " which came from $orig":"");
            } else {
               croak "unhandled on_collision action '$action'";
            }
         }
      }
      # Else make sure the parent directory *has* been written
      else {
         my $dst_parent= $file{name} =~ s,/?[^/]+$,,r;
         if (length $dst_parent && !exists $self->{dst_path_set}{$dst_parent}) {
            # if writing to a real dir, check whether it already exists by some other means
            if ($self->_dst->can('dst_abs') && -d $self->_dst->dst_abs . $dst_parent) {
               # no need to do anything, but record that we have it
               $self->{dst_path_set}{$dst_parent}= undef;
            }
            else {
               # Determine which directory to copy permissions from
               my $src_parent= !defined $file{src_path}? undef
                  : $file{src_path} =~ s,/?[^/]+$,,r;
               # If no rewrites, src_parent is the same as dst_parent
               if (!$self->_has_rewrites) {
                  $src_parent //= $dst_parent;
               }
               elsif (!defined $src_parent || $self->get_dst_for_src($src_parent) ne $dst_parent) {
                  # No src_path means we don't have an origin for this file, so no official
                  # origin for its parent directory, either.  But, maybe a directory of the
                  # same name exists in src_path.
                  # If so, use it, else create a generic directory.
                  my %dir= ( name => $dst_parent );
                  if ((@dir{qw( dev ino mode nlink uid gid rdev size atime mtime ctime )}
                     = lstat $self->{src_abs} . $dst_parent)
                     && S_ISDIR($dir{mode})
                  ) {
                     $src_parent= \%dir;
                  } else {
                     $src_parent= { name => $dst_parent, mode => (S_IFDIR | 0755) };
                  }
               }
               unshift @$add, $src_parent, \%file;
               next;
            }
         }
      }
      $self->{dst_path_set}{$file{name}}= $file{src_path};

      my $mode= $file{mode} // croak "attribute 'mode' is required, for $file{name}";
      if (S_ISREG($mode)) { $self->_export_file(\%file) }
      elsif (S_ISDIR($mode)) { $self->_export_dir(\%file) }
      elsif (S_ISLNK($mode)) { $self->_export_symlink(\%file) }
      elsif (S_ISBLK($mode) || S_ISCHR($mode)) { $self->_export_devnode(\%file) }
      elsif (S_ISFIFO($mode)) { $self->_export_fifo(\%file) }
      else {
         croak "Can't export ".(S_ISSOCK($mode)? 'sockets' : S_ISWHT($mode)? 'whiteout entries' : '(unknown)')
            .': "'.($file{src_path} // $file{data_path} // $file{name}).'"'
      }
   }
   $self;
}

our %_mode_alias= (
   file => S_IFREG,
   dir  => S_IFDIR,
   sym  => S_IFLNK,
   blk  => S_IFBLK,
   chr  => S_IFCHR,
   fifo => S_IFIFO,
   sock => S_IFSOCK,
);
sub _attrs_from_array_notation {
   my ($mode, $owner, $name)= (shift, shift, shift);
   unless (isa_int $mode) {
      $mode =~ /^(file|dir|sym|blk|chr|fifo|sock)(\d+)?\z/
         or croak "Invalid mode '$mode': expected number, or prefix file/dir/sym/blk/chr/fifo/sock followed by octal permissions";
      $mode= $_mode_alias{$1};
      $mode |= oct($2 // ($mode == S_IFDIR? 0755 : 0644));
   }
   my %attrs= ( name => $name, mode => $mode );
   my ($user,$group)= !defined $owner? (0,0) : split /:/, $owner;
   $attrs{ isa_int($user)?  'uid' : 'user'  }= $user;
   $attrs{ isa_int($group)? 'gid' : 'group' }= $group;
   if (($mode & S_IFMT) == S_IFBLK || ($mode & S_IFMT) == S_IFCHR) {
      @attrs{'major','minor'}= (shift, shift);
   }
   elsif (($mode & S_IFMT) == S_IFDIR) {
      $attrs{data}= shift;
   }
   $attrs{nlink} //= 1;
   return ( %attrs, @_ );
}


sub skip($self, $path) {
   $path =~ s,^/,,;
   $self->{src_path_set}{$path} //= undef;
   $self;
}


sub finish($self) {
   $self->_dst->finish;
   undef $self->{tmp}; # allow File::Temp to free tmp dir
}


sub get_dst_for_src($self, $path) {
   my $rre= $self->path_rewrite_regex;
   my $rewrote= $path =~ s/^$rre/$self->{path_rewrite_map}{$1}/er;
   $self->{_log_trace}->("  rewrote '$path' to '$rewrote'")
      if $self->{_log_trace} && $path ne $rewrote;
   return $rewrote;
}


sub get_dst_uid_gid($self, $uid, $gid, $context='') {
   # If dst_userdb is defined, convert these source uid/gid to names, then find the name
   # in dst_userdb, then write those uid/gid.  But, if _user_rewrite_map has an entry for
   # the UID or user, then go with that.
   my $dst_userdb= $self->{dst_userdb};
   if ($dst_userdb || $self->{_user_rewrite_map} || $self->{_group_rewrite_map}) {
      my $dst_uid= $self->{_user_rewrite_map}{$uid};
      my $dst_gid= $self->{_group_rewrite_map}{$gid};
      if ($dst_userdb && !defined $dst_uid) {
         my $src_userdb= ($self->{src_userdb} //= $self->_build_src_userdb);
         my $src_user= $src_userdb->user($uid)
            or croak "Unknown UID $uid$context";
         $dst_uid= $self->{_user_rewrite_map}{$src_user->name};
         if (!defined $dst_uid) {
            my $dst_user= $dst_userdb->user($src_user->name)
               or croak "User ".$src_user->name." not found in dst_userdb$context";
            $dst_uid= $dst_user->uid;
         }
         # cache it
         $self->{_user_rewrite_map}{$src_user->name}= $dst_uid;
         $self->{_user_rewrite_map}{$uid}= $dst_uid;
      }
      if ($dst_userdb && !defined $dst_gid) {
         my $src_userdb= ($self->{src_userdb} //= $self->_build_src_userdb);
         my $src_group= $src_userdb->group($gid)
            or croak "Unknown GID $gid$context";
         $dst_gid= $self->{_group_rewrite_map}{$src_group->name};
         if (!defined $dst_gid) {
            my $dst_group= $dst_userdb->group($src_group->name)
               or croak "Group ".$src_group->name." not found in dst_userdb$context";
            $dst_gid= $dst_group->gid;
         }
         # cache it
         $self->{_group_rewrite_map}{$src_group->name}= $dst_gid;
         $self->{_group_rewrite_map}{$gid}= $dst_gid;
      }
      return ($dst_uid, $dst_gid);
   }
   return ($uid, $gid);
}

sub _export_file($self, $file) {
   # If the file has a link count > 1, check to see if we already have it in the destination
   my $prev;
   if ($file->{nlink} > 1 && defined $file->{data_path}) {
      if (defined($prev= $self->_link_map->{"$file->{dev}:$file->{ino}"})) {
         $self->{_log_debug}->("Already exported inode $file->{dev}:$file->{ino} as '$prev'")
            if $self->{_log_debug};
         # make a link of that file instead of copying again
         $self->_log_action("LNK", $prev, $file->{name});
         # ensure the dst realizes it is a symlink by sending it without data
         delete $file->{data};
         delete $file->{data_path};
      }
      else {
         $self->_link_map->{"$file->{dev}:$file->{ino}"}= $file->{name};
      }
   }
   if (!defined $prev) {
      # Load the data, unless already provided
      unless (exists $file->{data}) {
         defined $file->{data_path}
            or croak "For regular files, must specify ->{data} or ->{data_path}";
         _load_or_map_file($file->{data}, $file->{data_path});
      }
      my @notes;
      # Check for ELF signature
      if (substr($file->{data}, 0, 4) eq "\x7fELF") {
         $self->_export_elf_file($file, \@notes);
      } elsif ($file->{data} =~ m,^#!\s*/,) {
         $self->_export_script_file($file, \@notes);
      }
      $self->_log_action("CPY", $file->{src_path} // '(data)', $file->{name}, @notes);
   }
   $self->_dst->add($file);
}

sub _resolve_src_library($self, $libname, $rpath) {
   my @paths= ((grep length, split /:/, ($rpath//'')), qw( lib lib64 usr/lib usr/lib64 ));
   for my $path (@paths) {
      $path =~ s,^/,,; # remove leading slash because src_abs ends with slash
      $path =~ s,(?<=[^/])\z,/, if length $path; # add trailing slash if it isn't the root
      if (-e $self->{src_abs} . $path . $libname) {
         $self->{_log_trace}->("  found $libname at $path$libname") if $self->{_log_trace};
         return $path . $libname;
      }
   }
   return ();
}

sub _export_elf_file($self, $file, $notes) {
   require Sys::Export::ELF;
   my $elf= Sys::Export::ELF::unpack($file->{data});
   my ($interpreter, @libs);
   if ($elf->{dynamic}) {
      $self->{_log_debug}->("Dynamic-linked ELF file: '$file->{name}' (src_path=$file->{src_path})")
         if $self->{_log_debug};
      if ($elf->{needed_libraries}) {
         for (@{$elf->{needed_libraries}}) {
            my $lib= $self->_resolve_src_library($_, $elf->{rpath}) // carp("Can't find lib $_ needed for $file->{src_path}");
            push @libs, $lib if $lib;
         }
         push @{$self->{add}}, @libs;
      }
      if (length $elf->{interpreter}) {
         $elf->{interpreter} =~ s,^/,,;
         $self->_elf_interpreters->{$elf->{interpreter}}= 1;
         $interpreter= $elf->{interpreter};
         push @{$self->{add}}, $interpreter;
      }
      $self->{_log_debug}->("  interpreter = ".($interpreter//'').", libs = @libs")
         if $self->{_log_debug};
   }
   # Is any path rewriting requested?
   if ($self->_has_rewrites && length $file->{src_path} && defined $interpreter) {
      # If any dep gets its path rewritten, need to modify interpreter and/or rpath
      my $rre= $self->path_rewrite_regex;
      if (grep m/^$rre/, $interpreter, @libs) {
         # the interpreter and rpath need to be absolute URLs, but within the logical root
         # of 'dst'.  They're already relative to 'dst', so just prefix a slash.
         $interpreter= '/'.$self->get_dst_for_src($interpreter);
         my %rpath;
         for (@libs) {
            my $dst_lib= $self->get_dst_for_src($_);
            $dst_lib =~ s,[^/]+$,,; # path of lib
            $rpath{$dst_lib}= 1;
         }
         my $rpath= join ':', map "/$_", keys %rpath;
         $self->{_log_debug}->("  rewritten interpreter = $interpreter, rpath = $rpath")
            if $self->{_log_debug};

         # Create a temporary file so we can run patchelf on it
         my $tmp= File::Temp->new(DIR => $self->tmp, UNLINK => 0);
         _syswrite_all($tmp, \$file->{data});
         my @patchelf= ( '--set-interpreter' => $interpreter );
         push @patchelf, ( '--set-rpath' => $rpath ) if length $rpath;
         $self->_patchelf($tmp, @patchelf);
         delete $file->{data};
         $file->{data_path}= $tmp;
         push @$notes, '+patchelf';
      } else {
         $self->{_log_debug}->("  no interpreter/lib paths affected by rewrites") if $self->{_log_debug};
      }
   }
}

sub _export_script_file($self, $file, $notes) {
   # Make sure the interpreter is added, and also rewrite its path
   my ($interp)= ($file->{data} =~ m,^#!\s*(/\S+),)
      or return;
   push @{$self->{add}}, $interp;

   if ($self->_has_rewrites && length $file->{src_path}) {
      # rewrite the interpreter, if needed
      my $rre= $self->path_rewrite_regex;
      if ($interp =~ s/^$rre/$self->{path_rewrite_map}{$1}/e) {
         # note file->{data} could be a read-only memory map
         my $data= delete($file->{data}) =~ s/^(#!\s*)(\S+)/$1$interp/r;
         $file->{data}= $data;
      }
      # Scan the source for paths that need rewritten
      if ($file->{data} =~ $rre) {
         # Rewrite paths in shell scripts, but only warn about others.
         # Rewriting perl scripts would basically require a perl parser...
         if ($interp =~ m,/(bash|ash|dash|sh)$,) {
            my $rewritten= $self->_rewrite_shell(delete $file->{data});
            $file->{data}= $rewritten;
            push @$notes, '+rewrite paths';
         } else {
            warn "$file->{src_path} is a script referencing a rewritten path, but don't know how to process it\n";
            push @$notes, "+can't rewrite!";
         }
      }
   }
}

sub _rewrite_shell($self, $contents) {
   my $rre= $self->path_rewrite_regex;
   # only replace path matches when following certain characters which
   # indicate the start of a path.
   $contents =~ s/(?<=[ '"><\n#])$rre/$self->{path_rewrite_map}{$1}/ger;
}

sub _export_dir($self, $dir) {
   $self->_log_action('DIR', $dir->{src_path} // '(default)', $dir->{name});
   $self->_dst->add($dir);
}

sub _export_symlink($self, $file) {
   if (!exists $file->{data}) {
      exists $file->{data_path}
         or croak "Symlink must contain 'data' or 'data_path'";
      defined( $file->{data}= readlink($file->{data_path}) )
         or croak "readlink($file->{data_path}): $!";
   }

   if ($self->_has_rewrites && length $file->{src_path}) {
      # Absolute links just need a simple rewrite on the target
      if ($file->{data} =~ m,^/,) {
         $file->{data}= $self->get_dst_for_src($file->{data});
      }
      # Relative links are tricky.  A "100%" solution might actually be impossible, because
      # users could intend for all sorts of different behavior with symlinks, but at least try
      # to DWIM here.
      else {
         # Example:  /usr/local/bin/foo -> ../../bin/bar, but both paths are being rewritten to /bin
         #   The correct symlink is then just /bin/foo -> bar
         # Example:  /usr/local/share/mydata -> ../../../opt/mydata, but /opt/mydata is a
         #   symlink to /opt/mydata-1.2.3, and /usr/local/share is getting rewritten to /share.
         #   The user may want this double redirection to remain so that mydata can be swapped
         #   for different versions, so can't just resolve everything to an absolute path.
         #   The correct symlink should probably be /share/mydata -> ../opt/mydata
         # Example:  /usr/local/share/mydata/lib -> ../../../../opt/mydata/current/../lib
         #   where /usr/local/share is getting rewritten and /opt/mydata is getting rewritten,
         #   and /opt/mydata/current is a symlink that breaks assumptions about '..'
         #   The correct symlink should probably be /share/mydata/lib -> ../../opt/mydata/current/../lib
         #   Note that /opt/mydata/current symlink might not even exist in dst yet (to be able
         #    to resolve it) and resolving the one in src might not be what the user wants.
         
         # I think the answer here is to consume all leading '..' in the symlink path
         # (src_path is already absolute, so no danger of '..' meaning something different)
         # then add all following non-'..' to arrive at a new src_target, then rewrite that to
         # the corresponding dst_target, then create a relative path from the dst symlink to
         # that dst_path, then append any additional portions of the original symlink as-is.
         my @src_parts= split '/', $file->{src_path};
         pop @src_parts; # discard name of symlink itself
         my @target_parts= grep $_ ne '.', split '/', $file->{data};
         while (@target_parts && $target_parts[0] eq '..') {
            shift @target_parts;
            pop @src_parts;
         }
         while (@target_parts && $target_parts[0] ne '..') {
            push @src_parts, shift @target_parts;
         }
         my @dst_target= split '/', $self->get_dst_for_src(join '/', @src_parts);
         # now construct a relative path from $file->{name} to $dst_target
         my @dst_parts= split '/', $file->{name};
         pop @dst_parts; # discard name of symlink itself
         # remove common prefix
         while (@dst_parts && @dst_target && $dst_parts[0] eq $dst_target[0]) {
            shift @dst_parts;
            shift @dst_target;
         }
         # assemble '..' for each remaining piece of dst_parts, then the path to dst-target,
         # then the remainder of original path components (if any)
         $file->{data}= join '/', (('..') x scalar @dst_parts), @dst_target, @target_parts;
      }
   }

   $self->_log_action('SYM', $file->{data}, $file->{name});
   $self->_dst->add($file);
}

sub _export_devnode($self, $file) {
   if (defined $file->{rdev} && (!defined $file->{rdev_major} || !defined $file->{rdev_minor})) {
      my ($major,$minor)= Sys::Export::Unix::_dev_major_minor($file->{rdev});
      $file->{rdev_major} //= $major;
      $file->{rdev_minor} //= $minor;
   }
   $self->_log_action(S_ISBLK($file->{mode})? 'BLK' : 'CHR', "$file->{rdev_major}:$file->{rdev_minor}", $file->{name});
   $self->_dst->($file);
}

sub _export_fifo($self, $file) {
   $self->_log_action("FIO", "(fifo)", $file->{name});
   $self->_dst->add($file);
}

# _load_file(my $buffer, $filenme)
sub _load_file {
   open my $fh, "<:raw", $_[1]
      or die "open($_[1]): $!";
   my $size= -s $fh;
   sysread($fh, ($_[0] //= ''), $size) == $size
      or die "sysread($_[1], $size): $!";
}

sub _syswrite_all($tmp, $content_ref) {
   my $ofs= 0;
   again:
   my $wrote= $tmp->syswrite($$content_ref, length($$content_ref) - $ofs, $ofs);
   if ($ofs+$wrote != length $$content_ref) {
      if ($wrote > 0) { $ofs += $wrote; goto again; }
      elsif ($!{EAGAIN} || $!{EINTR}) { goto again; }
      else { die "syswrite($tmp): $!" }
   }
   $tmp->close or die "close($tmp): $!";
}

if ($have_file_map) {
   eval q{
      sub _load_or_map_file { File::Map::map_file($_[0], $_[1], "<") }
      1;
   } or die "$@";
} else {
   *_load_or_map_file= *_load_file;
}

sub _linux_major_minor($dev) {
   use integer;
   ( (($dev >> 8) & 0xfff) | (($dev >> 31 >> 1) & 0xfffff000) ),
   ( ($dev & 0xff) | (($dev >> 12) & 0xffffff00) )
}
sub _system_mknod($path, $mode, $major, $minor) {
   my @args= ("mknod", "-m", sprintf("0%o", $mode & 0xFFF),
      $path, S_ISBLK($mode)? "b":"c", $major, $minor);
   system(@args) == 0
      or croak "mknod @args failed";
}

if ($have_unix_mknod) {
   eval q{
      sub _mknod_or_die { Unix::Mknod::mknod($_[0], $_[1], Unix::Mknod::makedev($_[2], $_[3])) or Carp::croak("mknod($_[0]): $!") }
      sub _dev_major_minor { Unix::Mknod::major($_[0]), Unix::Mknod::minor($_[0]) }
      1;
   } or die "$@";
} else {
   *_mknod_or_die= *_system_mknod;
   *_dev_major_minor= *_linux_major_minor;
}

sub _capture_cmd {
   require IPC::Open3;
   require Symbol;
   my $pid= IPC::Open3::open3(undef, my $out_fh, my $err_fh= Symbol::gensym(), @_)
      or die "running @_ failed";
   waitpid($pid, 0);
   my $wstat= $?;
   local $/= undef;
   my $out= <$out_fh>;
   my $err= <$err_fh>;
   return ($out, $err, $wstat);
}

our $patchelf;
sub _patchelf($self, $path, @args) {
   $self->{_log_trace}->("  patchelf @args $path") if $self->{_log_trace};
   unless ($patchelf) {
      chomp($patchelf= `which patchelf`);
      croak "Missing tool 'patchelf'"
         unless $patchelf;
   }
   my ($out, $err, $wstat)= _capture_cmd($patchelf, @args, $path);
   $wstat == 0
      or croak "patchelf '$path' failed: $err";
   1;
}

# Avoiding dependency on namespace::clean
{  no strict 'refs';
   delete @{"Sys::Export::Unix::"}{qw(
      croak carp abs_path blessed looks_like_number
      isa_export_dst isa_exporter isa_group isa_user isa_userdb
      S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT 
      S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFMT 
   )};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Unix - Export subsets of a UNIX system

=head1 SYNOPSIS

  use Sys::Export::Unix;
  my $exporter= Sys::Export::Unix->new(
    src => '/', dst => '/initrd'
    rewrite_paths => {
      'sbin'     => 'bin',
      'usr/bin'  => 'bin',
      'usr/sbin' => 'bin',
      'usr/lib'  => 'lib',
    },
  );
  $exporter->add('bin/busybox');

=head1 DESCRIPTION

This object contains the logic for exporting unix-style systems.

=head1 CONSTRUCTORS

=head2 new

  Sys::Export::Unix->new(\%attributes); # hashref
  Sys::Export::Unix->new(%attributes);  # key/value list

Required attributes:

=over

=item src

The root of the system to export from (often '/', but you must specify this)

=item dst

The root of the exported system.  This directory must exist, and should be empty unless you
specify 'on_conflict'.

It can also be an object with 'add' and 'finish' methods, which avoids the entire construction
of a staging directory, and doesn't require root permission to operate.

=back

Options:

=over

=item rewrite_path

Convenience for calling L</rewrite_path> using a hashref of C<< { src => dst } >> pairs.

=item rewrite_user

Convenience for calling L</rewrite_user> using a hashref of C<< { src => dst } >> pairs.

=item rewrite_group

Convenience for calling L</rewrite_group> using a hashref of C<< { src => dst } >> pairs.

=item src_userdb

An instance of L<Sys::Export::Unix::UserDB>, or constructor parameters for one.  The default is
to read C<< $src/etc/passwd >>, or fall back to the getpwnam function of the host.
See L</USER REMAPPING> for more details.

=item dst_userdb

An instance of L<Sys::Export::Unix::UserDB>, or constructor parameters for one.
If defined, this will trigger name-based translations of all UID/GID values written to the
destination filesystem.  See L</USER REMAPPING> for more details.

=item tmp

A temporary directory where this module can prepare temporary files.  If you are using a
filesystem destination, it will default to the same device as the staging directory.

When L<finish> is called, this is et to C<undef> so that instance of File::Temp can clean
themselves up.

=item on_collision

Specifies what to do if there is a name collision in the destination.  The default (undef)
causes an exception unless the existing file is identical to the one that would be written.

Setting this to 'overwrite' will unconditionally replace files as it runs.  Setting it to
'ignore' will silently ignore collisions and leave the existing file in place.
Setting it to a coderef will provide you with the path and content thata was about to be
written to it:

  on_collision => sub ($exporter, $fileinfo, $prev_src_path) {
    # src_path is relative to $exporter->src
    # dst_path is relative to $exporter->dst
    # content_ref is a scalar ref with the new contents of the file, possibly rewritten

=item log

This can either be a Log::Any instance, or a string specifying a log level such as "debug"
or "trace".  The default logging is on STDOUT (level 'info') and simply lists the files being
copied and whether they were patched.

=back

=head1 ATTRIBUTES

=head2 src

The root of the source filesystem.  It must be the actual root used by the symlinks and library
paths inside this filesystem, or things will break.

=head2 src_abs

The C<abs_path> of the root of the source filesystem, always ending with '/'.

=head2 src_userdb

An instance of L<Sys::Export::Unix::UserDB>.  This attribute is C<undef> until it is needed,
unless you specified it to the constructor.  See L</USER REMAPPING> for details.

=head2 dst

The root of the destination filesystem, OR a coderef which receives files which are ready to be
recorded.  This must be the logical root of your destination filesystem, which will be used when
symlinks or library paths refer to '/'.  If you want to move files into a subdirectory of the
logical destination filesystem, see L</rewrite_path>.  If you provide a coderef, the signature
is

  sub ($exporter, $file_attrs) { ... }

=head2 dst_abs

The C<abs_path> of the root of the destination filesystem, always ending with '/'.
This is only defined if L<dst> is B<not> a coderef.

=head2 dst_userdb

An instance of L<Sys::Export::Unix::UserDB>.  This attribute is C<undef> until it is needed,
unless you specified it to the constructor.  See L</USER REMAPPING> for details.

=head2 tmp

The C<abs_path> of a directory to use for temporary staging before renaming into L</dst>.
This must be in the same volume as C<dst> so that C<rename()> can be used to move temporary
files into their C<dst> location.

=head2 src_path_set

A hashref of all source paths which have been processed, and which destination path they were
written as.  All paths are logically absolute to their respective roots, but without a leading
slash.

=head2 dst_path_set

A hashref of all destination paths which have been created (as keys).  If the value of the key
is defined, it is the source path.  If not defined, it means the destination was created
without reference to a source path.

=head2 dst_uid_used

The set of numeric user IDs which have been written to dst.

=head2 dst_gid_used

The set of numeric group IDs which have been written to dst.

=head2 path_rewrite_regex

A regex that matches the longest prefix of a source path having a rewrite rule.

=head2 log

  $exporter->log('info');
  $exporter->log($logger);

Set the logging output object, or log level for 'print' output.

=head1 METHODS

=head2 rewrite_path

  $exporter->rewrite_path($src_prefix, $dst_prefix);

Add a path rewrite rule which replaces occurrences of C<$src_prefix> with C<$dst_prefix>.
Only one rewrite occurs per path; they don't cascade.  Path prefixes refer to the logical
absolute path with the source root and destination root.  You may specify these prefixes
with or without the leading implied '/'.

Returns C<$exporter> for chaining.

=head2 rewrite_user

  $exporter->rewrite_user( $src_name_or_uid => $dst_name_or_uid );

If you rewrite from a UID to a UID, this doesn't consider any names, and does an efficient
numeric remapping.

If src is a name, this instantiates L</src_userdb> if it doesn't exist, and resolves the
name (which must exist), then creates a numeric mapping.

If dst is a name, this instantiates L</dst_userdb> if it doesn't exist, and resolves the name
(which must exist, but gets auto-imported from C<src_userdb> in the default configuration)
then creates a numeric mapping.

=head2 rewrite_group

  $exporter->rewrite_group( $local_name_or_gid => $exported_name_or_gid );

Same semantics as L</rewrite_user> but for groups.

=head2 add

  $exporter->add($src_path, ...);
  $exporter->add(\%file_attrs, ...);

Add a source path (logically absolute with respect to C</src>) to the export.  This immediately
copies the file to the destination, possibly rewriting paths within it, and then triggering a
copy of any libraries or interpreters it depends on.

If specified directly, file attributes are:

  name            # destination path relative to destination root
  src_path        # source path relative to source root, no leading '/'
  data            # literal data content of file (must be bytes, not unicode)
  data_path       # absolute path of file to load 'data' from
  dev             # device, from stat
  dev_major       # major(dev), if you know it and don't know 'dev'
  dev_minor       # minor(dev), if you know it and don't know 'dev'
  ino             # inode, from stat
  mode            # permissions and type, as per stat
  nlink           # number of hard links
  uid             # user id
  gid             # group id
  rdev            # referenced device, for device nodes
  rdev_major      # major(rdev), if you know it and don't know 'rdev'
  rdev_minor      # minor(rdev), if you know it and don't know 'rdev'
  size            # size, in bytes.  Can be ommitted if 'data' is present
  mtime           # modification time, as per stat

If you don't specify src_path, path rewrites will not be applied to the contents of the file or
symlink (on the assumption that you used paths relative to the destination).

Returns C<$exporter> for chaining.

=head2 skip

  $exporter->skip($src_path);

Inform the exporter that it should *not* perform any actions for the specified source path,
presumably because you're handling that one specially in some other way.

=head2 finish

Apply any postponed changes to the destination filesystem.  For instance, this applies mtimes
to directories since writing the contents of the directory would have changed the mtime.

=head2 get_dst_for_src

  my $dst_path= $exporter->get_dst_for_src($src_path);

Returns the relative destination path for a relative source path, rewritten according to the
rewrite rules.  If no rewrites exist, this just returns C<$src_path>.

=head2 get_dst_uid_gid

  ($uid, $gid)= $exporter->get_dst_uid_gid($uid, $gid);

Given a source uid and gid, return the destination uid and gid.
See L</USER REMAPPING> for details.

This is the same routine used after every C<stat> on the source filesystem to compute the
uid/gid written to C<dst>.

=head1 USER REMAPPING

This module tries to be helpful with rewriting UID/GID from your source filesystem to the
destination filesystem, but also stay out of your way if you don't need that feature.  In the
simplest case, you are building an initrd from an environment with the same user database as
your final system image and UID/GID can be copied as-is.  In other cases, you might be pulling
files from Alpine to be used for an initrd that starts a Debian system, and need to map
ownership by name instead of number.

The basic rule is that name-based mapping is enabled or disabled by whether attribute
L</dst_userdb> is defined or not.  If you pass that as an initial constructor attribute, then
name-based mapping is enabled from the start.  If you request a destination name in a call
to L</rewrite_user> or L</rewrite_group>, they will automatically instantiate C<dst_userdb>.
However, you can also perform ID remapping without name databases.  If every call to
C<rewrite_user> and C<rewrite_group> exclusively use numbers, then the numeric mapping is
handled without triggering C<dst_userdb> to be created.

If name mapping is enabled, then L</src_userdb> must also be defined.  If you don't initialize
it, it will be automatically instantiated from C<$src/etc/passwd>, falling back to the users of
the host system via L<getpwnam> etc.

=head2 Name Mapping Behavior

Any time a new not-yet-mapped ID is encountered, it checks the C<src_userdb> to find out what
name is associated with that ID.  If not found, it may import it from C<getpwnam>/C<getgrnam>.
If still not found, it dies.  Then it checks for any name-baased rewrites to determine what
name to look for in C<dst_userdb>, defaulting to the same name as C<src_userdb>.  If
C<dst_userdb> doesn't have that name yet, the user is copied from C<src_userdb>, but croaks if
the UID/GID would conflict with another entry in C<dst_userdb>.  Once the src UID/GID and dst
UID/GID are both known, it adds those to the numeric mapping, so further name lookups are not
needed for that source ID.

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
