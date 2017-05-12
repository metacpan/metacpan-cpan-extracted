package Set::Files;
# Copyright (c) 2001-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# TODO
#    file locking (on a per-set basis)
#    create a set (set owner if root, otherwise use current user)

########################################################################

require 5.000;
use strict;
use warnings;
use Carp;
use IO::File;

use vars qw($VERSION);
$VERSION = "1.06";

########################################################################
# METHODS
########################################################################

my @Cache = qw(type owner dir opts ele);

# The Set::Files object:
#
#   { SET => { type  => { TYPE => 1, ... },
#              owner => USER,
#              dir   => DIR,
#              ele   => { ELE  => TRUE, ... },
#              opts  => { VAR  => VAL, ... },
#
#              incl  => { SET  => 1, ... },
#              excl  => { SET  => 1, ... },
#              omit  => { ELE  => 1, ... }
#            }
#   }
#
# The ELE => TRUE value is either 1 (if the element is explicitely
# included in the file) or 2 (if the element comes from an included
# file).

sub new {
   my($class,%opts) = @_;

   my $self = _Init(%opts);
   bless $self, $class;

   return $self;
}

sub list_sets {
   my($self,$type) = @_;
   if ($type) {
      my(@ret);
      foreach my $set (keys %{ $$self{"set"} }) {
         push(@ret,$set)  if ($$self{"set"}{$set}{"type"}{$type});
      }
      return sort @ret;
   } else {
      return sort keys %{ $$self{"set"} };
   }
}

sub owner {
   my($self,$set) = @_;
   if ($set) {
      if (exists $$self{"set"}{$set}) {
         return $$self{"set"}{$set}{"owner"};
      } else {
         carp "ERROR: Invalid set: $set\n";
         return undef;
      }

   } else {
      my %tmp;
      foreach my $set (keys %{ $$self{"set"} }) {
         $tmp{ $$self{"set"}{$set}{"owner"} } = 1;
      }
      return sort keys %tmp;
   }
}

sub owned_by {
   my($self,$uid,$type) = @_;
   if (! defined $uid) {
      carp "ERROR: Must specify a UID for 'owned_by' info.\n";
      return undef;
   }

   my(@ret);
   foreach my $set (keys %{ $$self{"set"} }) {
      push(@ret,$set)  if ($$self{"set"}{$set}{"owner"} == $uid  &&
                           (! $type  ||
                            exists $$self{"set"}{$set}{"type"}{$type}));
   }
   return sort @ret;
}

sub members {
   my($self,$set) = @_;
   if (! $set) {
      carp "ERROR: Must specify a set for 'members' info.\n";
      return undef;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set\n";
      return undef;
   }
   return sort keys %{ $$self{"set"}{$set}{"ele"} };
}

sub is_member {
   my($self,$set,$ele) = @_;
   if (! $set) {
      carp "ERROR: Must specify a set for 'is_member' info.\n";
      return undef;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set\n";
      return undef;
   }
   if (! defined $ele) {
      carp "ERROR: Must specify an element for 'is_member' info.\n";
      return undef;
   }
   return 1  if (exists $$self{"set"}{$set}{"ele"}{$ele});
   return 0;
}

sub list_types {
   my($self,$set) = @_;
   if ($set) {
      if (exists $$self{"set"}{$set}) {
         return sort keys %{ $$self{"set"}{$set}{"type"} };
      } else {
         carp "ERROR: Invalid set: $set\n";
         return undef;
      }

   } else {
      my %tmp;
      foreach my $set (keys %{ $$self{"set"} }) {
         foreach my $type (keys %{ $$self{"set"}{$set}{"type"} }) {
            $tmp{$type} = 1;
         }
      }
      return sort keys %tmp;
   }
}

sub dir {
   my($self,$set) = @_;
   if ($set) {
      if (exists $$self{"set"}{$set}) {
         return $$self{"set"}{$set}{"dir"};
      } else {
         carp "ERROR: Invalid set: $set\n";
         return undef;
      }

   } else {
      my %tmp;
      foreach my $set (keys %{ $$self{"set"} }) {
         $tmp{ $$self{"set"}{$set}{"dir"} } = 1;
      }
      return sort keys %tmp;
   }
}

sub opts {
   my($self,$set,$opt) = @_;
   if (! $set) {
      carp "ERROR: Must specify a set for 'opts' info.\n";
      return undef;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set\n";
      return undef;
   }

   if ($opt) {
      if (exists $$self{"set"}{$set}{"opts"}{$opt}) {
         return $$self{"set"}{$set}{"opts"}{$opt};
      } else {
         return 0;
      }
   } else {
      return %{ $$self{"set"}{$set}{"opts"} };
   }
}

sub delete {
   my($self,$set,$nobackup) = @_;
   if (! $set) {
      carp "ERROR: Set must be specified.\n";
      return;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set.\n";
      return;
   }

   my $dir = $$self{"set"}{$set}{"dir"};

   if (! -w $dir) {
      carp "ERROR: the delete method requires write access\n";
      return;
   }

   if (! -f "$dir/$set") {
      carp "ERROR: Set file nonexistant: $dir/$set\n";
      return;
   }

   if ($nobackup) {
      unlink "$dir/$set"  ||
        carp "ERROR: Unable to remove set file: $dir/$set\n";
   } else {
      rename "$dir/$set","$dir/.set_files.$set"  ||
        carp "ERROR: Unable to backup set file: $dir/$set\n";
   }
}

sub cache {
   my($self) = @_;
   if ($$self{"read"} ne "files") {
      carp "ERROR: unable to cache information: read from cache or file\n";
      return;
   }

   my($file) = $$self{"cache"} . "/.set_files.cache";
   my($out)  = new IO::File;

   if (! $out->open("$file.new",O_CREAT|O_WRONLY,0644)) {
      croak "ERROR: unable to create cache: $file.new: $!\n";
   }

   foreach my $set (sort keys %{ $$self{"set"} }) {
      print $out $set,"\n";
      foreach my $key (@Cache) {
         next  if (! exists $$self{"set"}{$set}{$key});

         if (ref $$self{"set"}{$set}{$key} eq "HASH") {
            print $out ".sf.hash\n";
            print $out $key,"\n";
            foreach my $k (sort keys %{ $$self{"set"}{$set}{$key} }) {
               print $out $k,"\n";
               print $out $$self{"set"}{$set}{$key}{$k},"\n";
            }
            print $out ".sf.end\n";
            next;
         }

         if (ref $$self{"set"}{$set}{$key} eq "ARRAY") {
            print $out ".sf.array\n";
            print $out $key,"\n";
            foreach my $k (@{ $$self{"set"}{$set}{$key} }) {
               print $out $k,"\n";
            }
            print $out ".sf.end\n";
            next;
         }

         print $out ".sf.scalar\n";
         print $out $key,"\n";
         print $out $$self{"set"}{$set}{$key},"\n";
      }
      print $out "\n";
   }
   $out->close;

   rename "$file.new",$file  ||
     croak "ERROR: unable to commit cache: $file: $!\n";
}

sub add {
   my($self,$set,$force,$commit,@ele) = @_;
   if ($$self{"read"} ne "files") {
      carp "ERROR: unable to add elements: read from cache\n";
      return;
   }

   if (! $set) {
      carp "ERROR: Must specify a set for adding elements.\n";
      return undef;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set\n";
      return undef;
   }
   if (! @ele) {
      carp "ERROR: No elements present for adding.\n";
      return undef;
   }

   my(@add);
   foreach my $ele (@ele) {
      if (! exists $$self{"set"}{$set}{"ele"}{$ele}  ||
          ($$self{"set"}{$set}{"ele"}{$ele} == 2  &&  $force)) {
         $$self{"set"}{$set}{"ele"}{$ele} = 1;
         delete $$self{"set"}{$set}{"omit0"}{$ele};
         push(@add,$ele);
      }
   }
   return 0  if (! @add);

   commit($self,$set)  if ($commit);
   return $#add+1;
}

sub remove {
   my($self,$set,$force,$commit,@ele) = @_;
   if ($$self{"read"} ne "files") {
      carp "ERROR: unable to remove elements: read from cache\n";
      return;
   }

   if (! $set) {
      carp "ERROR: Must specify a set for removing elements.\n";
      return undef;
   }
   if (! exists $$self{"set"}{$set}) {
      carp "ERROR: Invalid set: $set\n";
      return undef;
   }
   if (! @ele) {
      carp "ERROR: No elements present for removing.\n";
      return undef;
   }

   my(@rem);
   foreach my $ele (@ele) {
      if (exists $$self{"set"}{$set}{"ele"}{$ele}  ||
          ( (! exists $$self{"set"}{$set}{"omit0"}  ||
             ! exists $$self{"set"}{$set}{"omit0"}{$ele})  &&  $force )) {
         delete $$self{"set"}{$set}{"ele"}{$ele};
         $$self{"set"}{$set}{"omit0"}{$ele} = 1;
         push(@rem,$ele);
      }
   }
   return 0  if (! @rem);

   commit($self,$set)  if ($commit);
   return $#rem+1;
}

sub commit {
   my($self,@set) = @_;
   if (! @set) {
      carp "ERROR: Set must be specified.\n";
      return;
   }
   if ($$self{"read"} ne "file"  &&
       $$self{"read"} ne "files") {
      carp "ERROR: unable to commit changes: read from cache\n";
      return;
   }

   foreach my $set (@set) {
      if (! exists $$self{"set"}{$set}) {
         carp "ERROR: Invalid set: $set.\n";
         next;
      }

      # get dir and find out where to write new stuff

      my $dir = $$self{"set"}{$set}{"dir"};
      my $scr;
      my $wri;
      if (-w $dir) {
         $wri = 1;
         $scr = $dir;
      } else {
         $wri = 0;
         $scr = $$self{"scratch"};
      }

      # write the new file

      my $template  = $$self{"cache"} . "/.set_files.template";
      my $file      = "$scr/.set_files.$set.new";
      my $out       = new IO::File;
      my $in        = new IO::File;

      my @temp;
      if (-f $template) {
         if (! $in->open($template)) {
            carp "ERROR: Unable to open template: $file: $!\n";
         } else {
            @temp = <$in>;
            $in->close;
         }
      }

      if (! $out->open($file,O_CREAT|O_WRONLY,0644)) {
         carp "ERROR: Unable to write file: $file: $!\n";
         next;
      }
      foreach my $line (@temp) {
         print $out $line;
      }

      my $t = $$self{"tagchars"};

      foreach my $inc (sort keys %{ $$self{"set"}{$set}{"incl0"} }) {
         print $out $t,"INCLUDE $inc\n";
      }
      foreach my $exc (sort keys %{ $$self{"set"}{$set}{"excl0"} }) {
         print $out $t,"EXCLUDE $exc\n";
      }
      foreach my $omit (sort keys %{ $$self{"set"}{$set}{"omit0"} }) {
         print $out $t,"OMIT    $omit\n";
      }
      foreach my $type (sort keys %{ $$self{"set"}{$set}{"type0"} }) {
         print $out $t,"TYPE    $type\n";
      }
      foreach my $type (sort keys %{ $$self{"set"}{$set}{"notype0"} }) {
         print $out $t,"NOTYPE  $type\n";
      }
      foreach my $opt (sort keys %{ $$self{"set"}{$set}{"opts"} }) {
         my $val = $$self{"set"}{$set}{"opts"}{$opt};
         print $out $t,"OPTION  $opt = $val\n";
      }
      foreach my $ele (sort keys %{ $$self{"set"}{$set}{"ele"} }) {
         next  if ($$self{"set"}{$set}{"ele"}{$ele} == 2);
         print $out "$ele\n";
      }

      $out->close;

      # back up the old one

      if ($wri) {
         rename "$dir/$set","$dir/.set_files.$set"  ||  do {
            carp "ERROR: Unable to back up file: $dir/$set: $!\n";
            next;
         };
      } else {
         my @in;
         if (! $in->open("$dir/$set")) {
            carp "ERROR: Unable to read file: $dir/$set: $!\n";
            next;
         }
         @in = <$in>;
         $in->close;
         if (! $out->open("$scr/.set_files.$set",O_CREAT|O_WRONLY,0644)) {
            carp "ERROR: Unable to write file: $scr/.set_files.$set: $!\n";
            next;
         }
         foreach my $line (@in) {
            print $out $line;
         }
         $out->close;
      }

      # move the new one into place

      if ($wri) {
         rename "$dir/.set_files.$set.new","$dir/$set"  ||  do {
            carp "ERROR: Unable to commit file: $dir/$set: $!\n";
            next;
         };
      } else {
         my @in;
         if (! $in->open("$scr/.set_files.$set.new")) {
            carp "ERROR: Unable to read file: $scr/.set_files.$set.new: $!\n";
            next;
         }
         @in = <$in>;
         $in->close;
         if (! $out->open("$dir/$set",O_CREAT|O_WRONLY,0644)) {
            carp "ERROR: Unable to write file: $dir/$set: $!\n";
            next;
         }
         foreach my $line (@in) {
            print $out $line;
         }
         $out->close;
      }
   }
}

########################################################################

sub _Init {
   my(%opts)=@_;
   my(%self) = ();

   ###########################
   # Initialization

   # path

   my(@dir,@tmp);
   if (exists $opts{"path"}) {
      my $dir = $opts{"path"};
      if (ref($dir) eq "ARRAY") {
         @tmp = @$dir;
      } elsif (ref($dir)) {
         croak "ERROR: Invalid path value\n";
      } else {
         @tmp = split(":",$dir);
      }
   } else {
      @tmp = (".");
   }

   foreach my $dir (@tmp) {
      if (-d $dir) {
         push(@dir,$dir);
      } else {
         carp "WARNING: invalid directory: $dir\n";
      }
   }

   if (! @dir) {
      croak "ERROR: no valid path elements\n";
   }

   # cache

   my($cache,$cache_opt);
   if (exists $opts{"cache"}) {
      $cache       = $opts{"cache"};
      $cache_opt   = 1;
   } else {
      $cache       = $dir[0];
      $cache_opt   = 0;
   }
   $self{"cache"} = $cache;

   if (! -d $cache) {
      croak "ERROR: invalid cache directory: $cache\n";
   }

   # scratch

   my($scratch);
   if (exists $opts{"scratch"}) {
      $scratch       = $opts{"scratch"};
   } else {
      $scratch       = (-d '/tmp' ? '/tmp' : '.');
   }
   $self{"scratch"} = $scratch;

   if (! -d $scratch  ||
       ! -w $scratch) {
      croak "ERROR: invalid scratch directory: $scratch\n";
   }

   # invalid_quiet

   my($invalid_quiet);
   if (exists $opts{"invalid_quiet"}) {
      $invalid_quiet = 1;
   } else {
      $invalid_quiet = 0;
   }

   # read

   my($read);
   if (exists $opts{"read"}) {
      $read = $opts{"read"};
      if ($read ne "cache"  &&
          $read ne "files"  &&
          $read ne "file") {
         croak "ERROR: Invalid read option: $read\n";
      }
   } else {
      if ($cache_opt) {
         $read="cache";
      } else {
         $read="files";
      }
   }
   $self{"read"} = $read;

   # set

   my($set);
   if (exists $opts{"set"}) {
      $set = $opts{"set"};
   } else {
      $set = "";
   }

   if ($read eq "file"  &&  ! $set) {
      croak "ERROR: Read file requires a set\n";
   }
   if ($set  &&  $read ne "file") {
      carp "WARNING: Set option ignored when not reading a single file\n";
      return;
   }

   # LOCK

   my($lock);
   if (exists $opts{"lock"}) {
      $lock = ($opts{"lock"} ? 1 : 0);
   } else {
      $lock = 0;
   }

   if ($lock) {
   }

   ###########################
   # Read Cache

   if ($read eq "cache") {
      my $file = "$cache/.set_files.cache";
      if (-f $file) {
         my $in = new IO::File;
         $in->open($file)  ||
           croak "ERROR: unable to read cache: $file: $!\n";
         my @in = <$in>;
         $in->close;
         chomp(@in);
         while (@in) {
            my $set = shift(@in);
            while ($in[0]) {
               my $tmp = shift(@in);
               my $key = shift(@in);
               if ($tmp eq ".sf.hash") {
                  while ($in[0] ne ".sf.end") {
                     my $k = shift(@in);
                     $self{"set"}{$set}{$key}{$k} = shift(@in);
                  }
                  shift(@in);

               } elsif ($tmp eq ".sf.array") {
                  my @tmp;
                  while ($in[0] ne ".sf.end") {
                     push(@tmp,shift(@in));
                  }
                  $self{"set"}{$set}{$key} = [ @tmp ];
                  shift(@in);

               } elsif ($tmp eq ".sf.scalar") {
                  $self{"set"}{$set}{$key} = shift(@in);
               }
            }
            shift(@in);
         }

      } else {
         $read = "files";
      }
   }

   ###########################
   # Read Files

   if ($read eq "files"  ||
       $read eq "file") {

      # valid_file

      my($valid_file,$valid_file_re,$valid_file_nre);
      if (exists $opts{"valid_file"}) {
         my $tmp = $opts{"valid_file"};
         if (ref($tmp) eq "CODE") {
            $valid_file     = $tmp;
            $valid_file_re  = "";
            $valid_file_nre = "";
         } elsif (ref($tmp)) {
            croak "ERROR: Invalid valid_file value\n";
         } elsif ($tmp =~ s,^!,,) {
            $valid_file     = "";
            $valid_file_re  = "";
            $valid_file_nre = $tmp;
         } else {
            $valid_file     = "";
            $valid_file_re  = $tmp;
            $valid_file_nre = "";
         }
      } else {
         $valid_file     = "";
         $valid_file_re  = "";
         $valid_file_nre = "";
      }

      my %dir;
      foreach my $dir (@dir) {
         if (! opendir(DIR,$dir)) {
            carp "ERROR: Can't read directory: $dir: $!\n";
            next;
         }
         my(@f) = readdir(DIR);
         closedir(DIR);
         foreach my $f (@f) {
            next  if ($f eq "."  ||
                      $f eq ".." ||
                      $f =~ /^.set_files/ ||
                      ! -f "$dir/$f");
            if (($valid_file_nre  &&  $f =~ /$valid_file_nre/)  ||
                ($valid_file_re   &&  $f !~ /$valid_file_re/)  ||
                ($valid_file      &&  ! &$valid_file($dir,$f))) {
               warn "WARNING: File fails validity test: $f\n"
                 if (! $invalid_quiet);
               next;
            }
            if (exists $dir{$f}) {
               carp "WARNING: File redefined: $f\n";
            } else {
               $dir{$f} = $dir;
            }
         }
      }

      # types

      my(@types);
      if (exists $opts{"types"}) {
         my $type = $opts{"types"};
         if (ref($type) eq "ARRAY") {
            @types = @$type;
         } elsif (ref($type)) {
            croak "ERROR: Invalid types value\n";
         } else {
            @types = ($type);
         }
      } else {
         @types = ("_");
      }

      # default_types

      my(@def_types);
      if (exists $opts{"default_types"}) {
         my $type = $opts{"default_types"};
         if (ref($type) eq "ARRAY") {
            @def_types = @$type;
         } elsif (ref($type)) {
            croak "ERROR: Invalid default_types value\n";
         } elsif ($type eq "all") {
            @def_types = (@types);
         } elsif ($type eq "none") {
            @def_types = ();
         } else {
            @def_types = ($type);
         }
      } else {
         @def_types = @types;
      }

      my %tmp = map { $_,1 } @types;
      my @tmp;
      foreach my $type (@def_types) {
         if (! exists $tmp{$type}) {
            carp "WARNING: Invalid default_types value: $type\n";
         } else {
            push(@tmp,$type);
         }
      }
      @def_types = @tmp;

      # comment

      my($comment);
      if (exists $opts{"comment"}) {
         $comment = $opts{"comment"};
      } else {
         $comment = "#.*";
      }
      $self{"comment"} = $comment;

      # tagchars

      my($tagchars);
      if (exists $opts{"tagchars"}) {
         $tagchars = $opts{"tagchars"};
      } else {
         $tagchars = '@';
      }
      $self{"tagchars"} = $tagchars;

      # valid_ele

      my($valid_ele,$valid_ele_re,$valid_ele_nre);
      if (exists $opts{"valid_ele"}) {
         my $tmp = $opts{"valid_ele"};
         if (ref($tmp) eq "CODE") {
            $valid_ele     = $tmp;
            $valid_ele_re  = "";
            $valid_ele_nre = "";
         } elsif (ref($tmp)) {
            croak "ERROR: Invalid valid_ele value\n";
         } elsif ($tmp =~ s,^!,,) {
            $valid_ele     = "";
            $valid_ele_re  = "";
            $valid_ele_nre = $tmp;
         } else {
            $valid_ele     = "";
            $valid_ele_re  = $tmp;
            $valid_ele_nre = "";
         }
      } else {
         $valid_ele     = "";
         $valid_ele_re  = "";
         $valid_ele_nre = "";
      }

      # Read File

      if ($read eq "file") {
         my(@set) = ($set);;
         while (@set) {
            $set = shift(@set);
            next  if (exists $self{"set"}{$set});

            if (! exists $dir{$set}) {
               croak "ERROR: invalid set to read: $set\n";
            }

            $self{"set"}{$set} = _ReadSet($set,$dir{$set},\@types,\@def_types,
                                          $comment,$tagchars,
                                          $valid_ele,$valid_ele_re,$valid_ele_nre,
                                          $invalid_quiet);
            push (@set,keys %{ $self{"set"}{$set}{"incl"} })
              if (exists $self{"set"}{$set}{"incl"});
            push (@set,keys %{ $self{"set"}{$set}{"excl"} })
              if (exists $self{"set"}{$set}{"excl"});
         }
      }

      # Read Files

      if ($read eq "files") {
         foreach my $set (keys %dir) {
            $self{"set"}{$set} = _ReadSet($set,$dir{$set},\@types,\@def_types,
                                          $comment,$tagchars,
                                          $valid_ele,$valid_ele_re,$valid_ele_nre,
                                          $invalid_quiet);
         }
      }

      # Includes and Excludes

      foreach my $set (keys %{ $self{"set"} }) {
         if (exists $self{"set"}{$set}{"incl"}) {
            foreach my $inc (keys %{ $self{"set"}{$set}{"incl"} }) {
               if (! exists $self{"set"}{$inc}) {
                  carp "WARNING: Invalid include [ $inc ] in set: $set\n";
                  delete $self{"set"}{$set}{"incl"}{$inc};
                  delete $self{"set"}{$set}{"incl"}
                    if (! keys %{ $self{"set"}{$set}{"incl"} });
               }
            }
         }

         if (exists $self{"set"}{$set}{"excl"}) {
            foreach my $exc (keys %{ $self{"set"}{$set}{"excl"} }) {
               if (! exists $self{"set"}{$exc}) {
                  carp "WARNING: Invalid exclude [ $exc ] in set: $set\n";
                  delete $self{"set"}{$set}{"excl"}{$exc};
                  delete $self{"set"}{$set}{"excl"}
                    if (! keys %{ $self{"set"}{$set}{"excl"} });
               }
            }
         }
      }

      while (1) {
         my $flag1 = _ExpandInclude($self{"set"});
         my $flag2 = _ExpandExclude($self{"set"});
         last  if (! $flag1  &&  ! $flag2);
      }

      foreach my $set (keys %{ $self{"set"} }) {
         if (exists $self{"set"}{$set}{"excl"}  ||
             exists $self{"set"}{$set}{"incl"}) {
            carp "ERROR: Unresolved (circular) dependancy: $set\n";
         } elsif (exists $self{"set"}{$set}{"omit"}) {
            foreach my $ele (keys %{ $self{"set"}{$set}{"omit"} }) {
               delete $self{"set"}{$set}{"ele"}{$ele};
            }
            delete $self{"set"}{$set}{"omit"};
         }
      }

      if (! keys %{ $self{"set"} }) {
         croak "ERROR: No set data read.\n";
      }
   }

   return \%self;
}

sub _ReadSet {
   my($set,$dir,$types,$def_types,$comment,$tagchars,
      $valid_ele,$valid_ele_re,$valid_ele_nre,$invalid_quiet) = @_;
   my %set;

   $set{"dir"} = $dir;

   my $in = new IO::File;
   if (! $in->open("$dir/$set")) {
      croak "ERROR: Unable to open file: $dir/$set: $!\n";
   }
   my $uid = ( stat("$dir/$set") )[4];
   $set{"owner"} = $uid;
   _ReadSetFile($set,$in,\%set,$types,$def_types,$comment,
                $tagchars,$valid_ele,$valid_ele_re,$valid_ele_nre,
                $invalid_quiet);
   $in->close;
   return \%set;
}

sub _ReadSetFile {
   my($set,$in,$self,$types,$def_types,$comment,$tagchars,
      $valid_ele,$valid_ele_re,$valid_ele_nre,$invalid_quiet)=@_;
   my %types = map { $_,1 } @$types;
   my %def_types = map { $_,1 } @$def_types;
   $$self{"type"} = { %def_types };
   my(@in) = <$in>;
   chomp(@in);
   foreach my $line (@in) {
      $line =~ s,$comment,,;
      $line =~ s,^\s+,,;
      $line =~ s,\s+$,,;
      next  if (! $line);

      if ($line =~ s,^$tagchars,,) {
         $line =~ s,^\s+,,;
         if ($line =~ /^include\s+(.+)/i) {
            my $tmp = $1;
            my @tmp = split(/,/,$tmp);
            foreach my $tmp (@tmp) {
               $$self{"incl"}{$tmp} = 1;
               $$self{"incl0"}{$tmp} = 1;
            }

         } elsif ($line =~ /^exclude\s+(.+)/i) {
            my $tmp = $1;
            my @tmp = split(/,/,$tmp);
            foreach my $tmp (@tmp) {
               $$self{"excl"}{$tmp} = 1;
               $$self{"excl0"}{$tmp} = 1;
            }

         } elsif ($line =~ /^type\s+(.+)/i) {
            my $tmp = $1;
            my @tmp = split(/,/,$tmp);
            foreach my $tmp (@tmp) {
               if (exists $types{$tmp}) {
                  $$self{"type"}{$tmp} = 1;
                  $$self{"type0"}{$tmp} = 1;
               } else {
                  carp "ERROR: Invalid set type: $set [ $tmp ]\n";
               }
            }

         } elsif ($line =~ /^notype\s+(.+)/i) {
            my $tmp = $1;
            my @tmp = split(/,/,$tmp);
            foreach my $tmp (@tmp) {
               if (exists $types{$tmp}) {
                  delete $$self{"type"}{$tmp};
                  $$self{"notype0"}{$tmp} = 1;
               } else {
                  carp "ERROR: Invalid set type: $set [ $tmp ]\n";
               }
            }

         } elsif ($line =~ /^omit\s+(.+)/i) {
            $$self{"omit"}{$1} = 1;
            $$self{"omit0"}{$1} = 1;

         } elsif ($line =~ /^option\s+(.+?)\s*=\s*(.*)/i) {
            my($var,$val)=($1,$2);
            $val=0  if (! $val);
            $$self{"opts"}{$var} = $val;

         } elsif ($line =~ /^option\s+(.+)/i) {
            $$self{"opts"}{$1} = 1;

         } else {
            carp "ERROR: Invalid tag line: $set: $line\n";
         }

      } else {
         if (($valid_ele_nre  &&  $line =~ /$valid_ele_nre/)  ||
             ($valid_ele_re   &&  $line !~ /$valid_ele_re/)  ||
             ($valid_ele      &&  ! &$valid_ele($set,$line))) {
            warn "WARNING: Element fails validity test: $line\n"
              if (! $invalid_quiet);
            next;
         }
         $$self{"ele"}{$line} = 1;
      }
   }
}

sub _ExpandInclude {
   my($self)=@_;
   my $prog = 0;                # overall progress

   my %inc;
   my %exc;
   foreach my $set (keys %$self) {
      $inc{$set} = 1  if (exists $$self{$set}{"incl"});
      $exc{$set} = 1  if (exists $$self{$set}{"excl"});
   }

   while (1) {
      last  if (! keys %inc);
      my $progress = 0;         # progress this iteration

      foreach my $set (keys %inc) {
         foreach my $inc (keys %{ $$self{$set}{"incl"} }) {
            next  if (exists $inc{$inc}  ||
                      exists $exc{$inc});
            $prog = $progress = 1;

            foreach my $ele (keys %{ $$self{$inc}{"ele"} }) {
               $$self{$set}{"ele"}{$ele} = 2
                 if (! exists $$self{$set}{"ele"}{$ele});
            }

            delete $inc{$set};
            delete $$self{$set}{"incl"}{$inc};
            delete $$self{$set}{"incl"}  if (! keys %{ $$self{$set}{"incl"} });
         }
      }
      next  if ($progress);
      last;
   }
   return $prog;
}

sub _ExpandExclude {
   my($self)=@_;
   my $prog = 0;

   my %inc;
   my %exc;
   foreach my $set (keys %$self) {
      $inc{$set} = 1  if (exists $$self{$set}{"incl"});
      $exc{$set} = 1  if (exists $$self{$set}{"excl"});
   }

   while (1) {
      last  if (! keys %exc);
      my $progress = 0;         # progress this iteration

      foreach my $set (keys %exc) {
         next  if (exists $inc{$set}); # only exclude after all includes
         foreach my $exc (keys %{ $$self{$set}{"excl"} }) {
            next  if (exists $inc{$exc}  ||
                      exists $exc{$exc});
            $prog = $progress = 1;

            foreach my $ele (keys %{ $$self{$exc}{"ele"} }) {
               # We don't want to exclude elements that are explicitly included
               # in the set file.
               delete $$self{$set}{"ele"}{$ele}
                 if (exists $$self{$set}{"ele"}{$ele}  &&
                     $$self{$set}{"ele"}{$ele} == 2);
            }

            delete $exc{$set};
            delete $$self{$set}{"excl"}{$exc};
            delete $$self{$set}{"excl"}  if (! keys %{ $$self{$set}{"excl"} });
         }
      }
      next  if ($progress);
      last;
   }
   return $prog;
}

########################################################################

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
