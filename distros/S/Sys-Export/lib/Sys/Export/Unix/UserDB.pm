package Sys::Export::Unix::UserDB;
# ABSTRACT: Abstractions for Unix passwd/group/shadow files
our $VERSION = '0.001'; # VERSION

use v5.26;
use warnings;
use experimental qw( signatures );
use Carp ();
use File::Spec::Functions qw( catfile );
use Storable qw( dclone );
use Scalar::Util ();
use User::pwent qw( getpwnam pw_has );
use Sys::Export qw( :isa );

# making lexical subs allows these to be seen by inner packages as well
# and removes need for namespace::clean
my sub carp       { goto \&Carp::carp }
my sub croak      { goto \&Carp::croak }
my sub isa_hash   :prototype($) { ref $_[0] eq 'HASH' }
my sub isa_array  :prototype($) { ref $_[0] eq 'ARRAY' }
my sub isa_int    :prototype($) { Scalar::Util::looks_like_number($_[0]) && int($_[0]) == $_[0] }


sub new($class, %args) {
   my $self = bless {
      users  => {},
      uids   => {},
      groups => {},
      gids   => {},
   }, $class;
   # I don't want to declare this as an official attribute because a subclass might decide
   # to implement is_valid_name using something other than a regex, and then the attribute
   # would be inconsistent.
   $self->{valid_name_regex}= $args{valid_name_regex} if defined $args{valid_name_regex};
   # Extract initial user and group lists before initializing attributes, then apply afterward
   my $g= delete $args{groups};
   my $u= delete $args{users};

   # Apply writable attributes and/or initial methods
   for (keys %args) {
      croak "Unknown option '$_'" unless $self->can($_);
      $self->$_($args{$_});
   }
   if ($g) {
      if (isa_array $g) {
         $self->add_group($_) for $g->@*;
      } elsif (isa_hash $g) {
         $self->add_group($_ => $g->{$_}->%*) for keys %$g;
      } else {
         croak "Option 'groups' must be arrayref or hashref of group objects";
      }
   }
   if ($u) {
      if (isa_array $u) {
         $self->add_user($_) for $u->@*;
      } elsif (isa_hash $u) {
         $self->add_user($_ => $u->{$_}->%*) for keys %$u;
      } else {
         croak "Option 'users' must be arrayref or hashref of user objects";
      }
   }
   return bless $self, $class;
}


sub users($self) { $self->{users} }

sub uids($self) { $self->{uids} }

sub groups($self) { $self->{groups} }

sub gids($self) { $self->{gids} }


sub auto_import($self, @val) {
   # coerce anything other than a userdb into a boolean
   @val? ($self->{auto_import}= isa_userdb($val[0])? $val[0] : !!$val[0]) : $self->{auto_import}
}


sub clone($self) {
   return dclone($self);
}


sub is_valid_name($self, $name) {
   defined $self->{valid_name_regex}? scalar( $name =~ $self->{valid_name_regex} )
   : scalar( $name =~ /^[A-Za-z_][-A-Za-z0-9_.]{0,30}[-A-Za-z0-9_.\$]?\z/ )
}


sub load($self, $path, %options) {
   croak "Path is required" unless defined $path;
   my $passwd_file = catfile($path, 'passwd');
   my $group_file = catfile($path, 'group');
   my $shadow_file = catfile($path, 'shadow');

   unless ($options{format}) {
      # If we have passwd, group, and shadow, assume Linux.
      $options{format}= (-f $passwd_file && -f $group_file && -f $shadow_file)? 'Linux'
	: croak "Unable to detect format: passwd ".(-f $passwd_file? "[found]":"[not found]")
                ." group ".(-f $group_file? "[found]" : "[not found]")
                ." shadow ".(-f $shadow_file? "[found]" : "[not found]");
   }
   my $records;
   if ($options{format} eq 'Linux') {
      $records= $self->_parse_linux_passwd_format({
         passwd => _slurp($passwd_file),
         group  => _slurp($group_file),
         (-r $shadow_file? ( shadow => _slurp($shadow_file) ) : ()),
      });
   } else {
      croak "Unsupported format '$options{format}'";
   }

   # convert user primary gid to group name
   my (%group_by_name, %group_by_gid, %user_by_name);
   for ($records->{groups}->@*) {
      $group_by_name{$_->{name}} //= $_;
      $group_by_gid{$_->{gid}} //= $_;
   }
   for ($records->{users}->@*) {
      $user_by_name{$_->{name}} //= $_;
      my $gid= delete $_->{gid};
      if (my $primary_group= $group_by_gid{$gid}) {
         $_->{group}= $primary_group->{name};
      } else {
         carp "User '$_->{name}' references non-existent gid $gid";
         # This allows the gid to pass through for a round trip, but will generate
         # warning in various places.
         $_->{group}= $gid;
      }
   }

   # move group membership to user records
   for my $g ($records->{groups}->@*) {
      if (my $members= delete $g->{members}) {
         for (split ',', $members) {
            my $u= $user_by_name{$_}
               or do { carp "Group '$g->{name}' references non-existent user '$_'"; next; };
            push @{$u->{groups}}, $g->{name};
         }
      }
   }

   $self->_add_group_object(Sys::Export::Unix::UserDB::Group->new(%$_))
      for $records->{groups}->@*;
   $self->_add_user_object(Sys::Export::Unix::UserDB::User->new(%$_))
      for $records->{users}->@*;

   return $self;
}


sub save($self, $target, %options) {
   my $format= $options{format} // $self->{default_format} // 'Linux';
   my $data;
   if ($format eq 'Linux') {
      $data= $self->_generate_linux_passwd_format(%options);
   } else {
      croak "Unsupported format $options{format}";
   }
   if (isa_hash $target) {
      %$target= %$data;
   } else {
      croak "path does not exist: '$target'" unless -e $target;
      for (keys %$data) {
         my $public= $_ eq 'passwd' || $_ eq 'group';
         _mkfile(catfile($target, $_), $data->{$_}, $public? 0755 : 0700);
      }
   }
   return $self;
}

sub _mkfile($name, $data, $mode=undef) {
   open my $fh, '>:raw', $name or croak "open(>$name): $!";
   $fh->print($data) or croak "write($name): $!";
   $fh->close or croak "close($name): $!";
   chmod $mode, $name or croak "chmod($name, $mode): $!"
      if defined $mode;
}
sub _slurp($name) {
   open my $fh, '<:raw', $name or die "open(<$name): $!";
   local $/;
   my $ret= scalar <$fh>;
   close $fh or die "close($name): $!";
   $ret;
}

our @_linux_shadow_fields= qw( passwd pw_change_time pw_min_days pw_max_days pw_warn_days pw_inactive_days expire_time );

# Unix time ignores leap seconds, so the conversion from seconds to days is simple division
sub _time_to_days_since_1970($t) { !defined $t? undef : int($t / 86400) }
sub _days_since_1970_to_time($d) { !defined $d? undef : $d * 86400; }

sub _parse_linux_passwd_format($self, $files) {
   my @users;
   my %users;
   for (split "\n", $files->{passwd}) {
      next if /^\s*(#|\z)/;
      my %r;
      @r{qw( name pw_flag uid gid gecos dir shell )}= split ':';
      delete $r{pw_flag};
      push @users, \%r;
      $users{$r{name}} //= \%r;
   }

   for (split "\n", ($files->{shadow}//'')) {
      next if /^\s*(#|\z)/;
      my ($name,@vals)= split ':';
      my $r= $users{$name}
         or do { carp "Found shadow entry for non-existent user '$name'"; next; };
      @{$r}{@_linux_shadow_fields}= @vals;
      $r->{pw_change_time}= _days_since_1970_to_time($r->{pw_change_time});
      $r->{expire_time}= _days_since_1970_to_time($r->{expire_time});
   }

   my @groups;
   for (split "\n", $files->{group}) {
      next if /^\s*(#|\z)/;
      my %r;
      @r{qw( name passwd gid members )}= split ":";
      push @groups, \%r;
   }
   return { users => \@users, groups => \@groups };
}

sub _generate_linux_passwd_format($self, %options) {
   my ($passwd, $group, $shadow)= ('','','');
   my @users= sort { $a->uid <=> $b->uid } values $self->{users}->%*;
   my @groups= sort { $a->gid <=> $b->gid } values $self->{groups}->%*;

   # Generate passwd content
   for my $user (@users) {
      my $gid;
      if ($user->group) {
         my $group= $self->group($user->group)
            or croak "User '".$user->name."' has invalid group '".$user->group."'";
         $gid= $group->gid;
      } else {
         $gid= $user->gid
            or croak "User '".$user->name."' lacks 'group' or 'gid' attribute";
      }
      # If shadow fields exist, write a 'x' in passwd, else '*'.
      my $pw_flag= '*';
      if (grep defined, @{$user}{@_linux_shadow_fields}) {
         $pw_flag= 'x';
         $shadow .= sprintf "%s:%s:%s:%s:%s:%s:%s:%s:%s\n",
            $user->name,
            $user->passwd // '*',
            _time_to_days_since_1970($user->pw_change_time) // '',
            $user->pw_min_days // '',
            $user->pw_max_days // '',
            $user->pw_warn_days // '',
            $user->pw_inactive_days // '',
            _time_to_days_since_1970($user->expire_time) // '',
            ''; # reserved field, no idea what to name it in user object...
      }
      $passwd .= sprintf "%s:%s:%d:%d:%s:%s:%s\n",
         $user->name, $pw_flag, $user->uid, $gid,
         $user->gecos//'', $user->dir//'', $user->shell//'';
   }

   # Generate group content
   for my $g (@groups) {
      my $grnam= $g->name;
      # Collect members from users who have this group, excluding users whose primary
      #  group is already the group.
      my @members= map $_->name, grep $_->groups->{$grnam} && ($_->group//'') ne $grnam, @users;
      $group .= sprintf "%s:%s:%d:%s\n",
         $grnam, $g->passwd // '*', $g->gid, join ',', sort @members;
   }

   return { passwd => $passwd, group => $group, shadow => $shadow };
}


sub import_user($self, $name_or_obj, %attrs) {
   if (ref($name_or_obj) && ref($name_or_obj)->isa('Sys::Export::Unix::UserDB::User')) {
      %attrs= ( %$name_or_obj, %attrs );
   } elsif (keys %attrs) {
      $attrs{name}= "$name_or_obj";
   } else {
      my $pw= getpwnam($name_or_obj)
         or croak "User '$name_or_obj' not found in system";
      $attrs{name}= $pw->name;
      $attrs{passwd}= $pw->passwd;
      $attrs{uid}= $pw->uid;
      $attrs{quota}= $pw->quota if pw_has('quota');  # BSD
      $attrs{class}= $pw->class if pw_has('class');  # BSD
      $attrs{comment}= $pw->comment if pw_has('comment'); # always empty on Linux and BSD...
      $attrs{gecos}= $pw->gecos if pw_has('gecos');
      $attrs{dir}= $pw->dir;
      $attrs{shell}= $pw->shell;
      # FreeBSD has expire in seconds.  Linux has an expire field of days, in /etc/shadow, but
      # pw_has('expire') is false on Linux.
      $attrs{expire}= $pw->expire if pw_has('expire');
      # convert gid to group name
      my $gid= $pw->gid;
      if (my $grnam= getgrgid($gid)) {
         $attrs{group}= $grnam;
      } elsif ($gid == $pw->uid || $pw->uid < 1000) {
         # If the group wasn't found, but the uid and gid are identical and look like system
         # accounts then assume the group will be the same name.
         $attrs{group}= $pw->name;
      } else {
         carp "User '$name_or_obj' primary group $gid doesn't exist";
         $attrs{group}= 'nogroup'; # it has to be something.  Could croak instead of this...
      }
   }
   $attrs{group} //= 'nogroup';
   $attrs{groups} //= {};

   # Check for UID collision
   defined $attrs{uid}
      or croak "Can't import user $attrs{name} without a 'uid'";
   if ($self->{uids}{$attrs{uid}}) {
      if ($attrs{uid} >= 1000) {
         ++$attrs{uid} while exists $self->{uids}{$attrs{uid}};
      } else {
         for (101..999) {
            if (!exists $self->{uids}{$_}) {
               $attrs{uid}= $_;
               last;
            }
         }
         croak "No available UIDs below 1000 for $attrs{name}"
            if $self->{uids}{$attrs{uid}};
      }
   }

   # do the groups exist?  Calling ->group will trigger auto_import if enabled.
   for my $gname (grep !$self->group($_), $attrs{group}, keys $attrs{groups}->%*) {
      # Is the group name the same as the user name? Try creating with GID = UID
      if ($gname eq $attrs{name}) {
         $self->import_group($gname, gid => $attrs{uid});
      } elsif ($gname =~ /^(nobody|nogroup)/) {
         $self->import_group($gname, gid => 65534);
      } else {
         croak "User '$attrs{name}' references non-existent group '$gname'";
      }
   }

   my $u= Sys::Export::Unix::UserDB::User->new(%attrs);
   $self->_add_user_object($u);
   return $u;
}


sub import_group($self, $name_or_obj, %attrs) {
   if (isa_hash($name_or_obj) || isa_user($name_or_obj)) {
      %attrs= ( %$name_or_obj, %attrs );
   } elsif (keys %attrs) {
      $attrs{name}= "$name_or_obj";
   } else {
      my ($grnam, $passwd, $gid, $members) = getgrnam($name_or_obj)
         or croak "Group '$name_or_obj' not found in system";
      $attrs{name}= $grnam;
      $attrs{passwd}= $passwd;
      $attrs{gid}= $gid;
      $attrs{members}= $members;
   }
   my $members= delete $attrs{members};
   my $g= Sys::Export::Unix::UserDB::Group->new(%attrs);
   $self->_add_group_object($g);

   # Can't store member list in group, so store these for later when a user gets added
   if (defined $members) {
      $self->_lazy_add_user_to_group($_, $attrs{name})
         for (isa_array $members? @$members
            : isa_hash $members? keys %$members
            : split / /, $members);
   }
   return $g;
}


sub add_user($self, $name_or_obj, %attrs) {
   if (isa_hash($name_or_obj) || isa_user($name_or_obj)) {
      %attrs= ( %$name_or_obj, %attrs );
   } else {
      my $name= "$name_or_obj";
      if (keys %attrs) {
         $attrs{name}= $name;
      }
      # trigger an import if just a name, and auto_import enabled
      elsif ($self->auto_import && !$self->{users}{$name}) {
         $self->user($name)
            or croak "Failed to import user $name";
         return $self;
      }
   }
   $self->_add_user_object(Sys::Export::Unix::UserDB::User->new(%attrs));
}


sub add_group($self, $name_or_obj, %attrs) {
   if (isa_hash($name_or_obj) || isa_group($name_or_obj)) {
      %attrs= ( %$name_or_obj, %attrs );
   } else {
      my $name= "$name_or_obj";
      if (keys %attrs) {
         $attrs{name}= $name;
      }
      # trigger an import if just a name, and auto_import enabled
      elsif ($self->auto_import && !$self->{groups}{$name}) {
         $self->group($name)
            or croak "Failed to import group $name";
         return $self;
      }
   }
   $self->_add_group_object(Sys::Export::Unix::UserDB::Group->new(%attrs));
}


sub user($self, $spec) {
   my $u= isa_int $spec? $self->{uids}{$spec} : $self->{users}{$spec};
   if (!$u && $self->auto_import) {
      if (isa_userdb $self->auto_import) {
         $u= $self->auto_import->user($spec);
         $u= eval { $self->import_user($u) } if $u;
      } else {
         my $name= isa_int $spec? getpwuid($spec) : $spec;
         $u= eval { $self->import_user($name) } || warn $@ if length $name;
      }
   }
   $u;
}

sub has_user($self, $spec) {
   defined(isa_int $spec? $self->{uids}{$spec} : $self->{users}{$spec});
}

sub group($self, $spec) {
   my $g= isa_int $spec? $self->{gids}{$spec} : $self->{groups}{$spec};
   if (!$g && $self->auto_import) {
      if (isa_userdb $self->auto_import) {
         $g= $self->auto_import->group($spec);
         $g= eval { $self->import_group($g) } if $g;
      } else {
         my $name= isa_int $spec? getgrgid($spec) : $spec;
         $g= eval { $self->import_group($name) } || warn $@ if length $name;
      }
   }
   $g;
}

sub has_group($self, $spec) {
   defined(isa_int $spec? $self->{gids}{$spec} : $self->{groups}{$spec});
}

# Private methods

# Allows adding user to group before user is defined
sub _lazy_add_user_to_group($self, $unam, $grnam) {
   if (my $u= $self->{users}{$unam}) {
      $u->add_group($grnam);
   } else {
      push $self->{_lazy_add_user_to_group}{$unam}->@*, $grnam;
   }
}

sub _add_user_object($self, $user) {
   my $name = $user->name;
   my $uid = $user->uid;
   $self->is_valid_name($name) or croak "Invalid user name '$name'";
   
   # Check for name conflicts
   croak "Username '$name' already exists"
      if defined $self->{users}{$name};
   
   # Warn about UID conflicts
   carp "UID $uid already exists for user '".$self->{uids}{$uid}->name."', now also used by '$name'"
      if defined $self->{uids}{$uid};

   # Check for references to non-existent groups
   # If auto_import is enabled, accessing ->group will trigger their creation.
   for ((isa_int $user->group? () : ($user->group)), keys $user->groups->%*) {
      $self->is_valid_name($_)
         or croak "Invalid group name '$_' for user '$name'";
      # add the user temporarily so auto_import feature can see it
      local $self->{users}{$name} = $user
         if $self->auto_import;
      croak "User '$name' references non-existent group '$_'"
         unless $self->group($_);
   }

   # Add lazy group membership from earlier
   if (my $lazy= delete $self->{_lazy_add_user_to_group}{$name}) {
      $self->{groups}{$_} && $user->add_group($_)
         for @$lazy;
   }

   $self->{uids}{$uid} //= $user;
   $self->{users}{$name} = $user;
}

sub _add_group_object($self, $group) {
   my $name = $group->name;
   my $gid = $group->gid;
   $self->is_valid_name($name) or croak "Invalid group name '$name'";
   
   # Check for name conflicts
   croak "Group name '$name' already exists"
      if defined $self->{groups}{$name};
   
   # Warn about GID conflicts
   carp "GID $gid already exists for group '".$self->{gids}{$gid}->name."', now also used by '$name'"
      if defined $self->{gids}{$gid};
   
   $self->{gids}{$gid} //= $group;
   $self->{groups}{$name} = $group;
}


package Sys::Export::Unix::UserDB::User {
   use v5.26;
   use warnings;
   use experimental qw( signatures );
   our @CARP_NOT= qw( Sys::Export::Unix::UserDB );
   our %known_attrs= map +($_ => 1), qw( name uid passwd group groups comment gecos dir shell
      quota pw_change_time pw_min_days pw_max_days pw_warn_days pw_inactive_days expire_time );
   sub new($class, %attrs) {
      my $self= bless {
            name   => delete $attrs{name},
            uid    => delete $attrs{uid},
            group  => delete $attrs{group},
            groups => {},
         }, $class;
      croak "User 'name' is required" unless defined $self->{name};
      croak "User 'uid' is required" unless defined $self->{uid};
      unless (defined $self->{group}) {
         # pull primary group from first element of list if not provided
         if (isa_array $self->{groups}) {
            $self->{group}= $self->{groups}[0];
         }
         croak "User primary 'group' is required" unless length $self->{group};
      }
      for my $key (keys %attrs) {
         carp "Unknown user attribute '$key'" unless $known_attrs{$key};
         $self->$key($attrs{$key});
      }
      return $self;
   }
   sub clone($self, %attrs) {
      return ref($self)->new( %$self, %attrs );
   }
   
   # Read-only attributes
   sub name($self) { $self->{name} }
   sub uid($self) { $self->{uid} }
   
   # Writable attributes
   sub group($self, @val) {
      @val? ($self->{group}= $val[0]) : $self->{group};
   }
   
   sub groups($self, @val) {
      if (@val) {
         if (@val > 1 || !ref $val[0]) {
            $self->{groups}= { map +($_ => 1), @val };
         } elsif (isa_array $val[0]) {
            $self->{groups}= { map +($_ => 1), @{$val[0]} };
         } elsif (isa_hash $val[0]) {
            $self->{groups}= { %{$val[0]} };
         } else {
            $self->{groups}= { $val[0] => 1 }; # just stringify it
         }
      }
      $self->{groups}
   }

   sub add_group($self, $group_name) {
      $self->{groups}{$group_name}= 1;
      return $self;
   }
   
   sub remove_group($self, $group_name) {
      delete $self->{groups}{$group_name};
      return $self;
   }

   {
      # Generate generic read/write accessors for all other known attributes
      my $pl= join "\n",
         map <<~PL, grep !__PACKAGE__->can($_), keys %known_attrs;
         sub $_(\$self, \@val) {
            \@val ? (\$self->{$_} = \$val[0]) : \$self->{$_};
         }
         PL
      eval $pl." 1" or croak $@;
   }

   # Other generic read/write accessors
   our $AUTOLOAD;
   sub AUTOLOAD {
      my $attr= substr($AUTOLOAD, rindex($AUTOLOAD, ':')+1);
      my $self= shift;
      carp "Unknown user attribute '$attr'"
         unless exists $known_attrs{$attr} || exists $self->{$attr};
      @_? ( $self->{$attr}= shift ) : $self->{$attr};
   }

   sub import {}
   sub DESTROY {}
}


package Sys::Export::Unix::UserDB::Group {
   use v5.26;
   use warnings;
   use experimental qw( signatures );
   our @CARP_NOT= qw( Sys::Export::Unix::UserDB );
   our %known_attrs= map +($_ => 1), qw( name gid passwd );

   sub new($class, %attrs) {
      my $self= bless {
            name    => delete $attrs{name},
            gid     => delete $attrs{gid},
            passwd  => delete $attrs{passwd},
         }, $class;
      croak "Group 'name' is required" unless defined $self->{name};
      croak "Group 'gid' is required" unless defined $self->{gid};
      for my $key (keys %attrs) {
         carp "Unknown group attribute: '$key'" unless $known_attrs{$key};
         $self->$key($attrs{$key});
      }
      return $self;
   }

   # Read-only attributes
   sub name($self) { $self->{name} }
   sub gid($self) { $self->{gid} }
   
   sub clone($self, %attrs) {
      return ref($self)->new( %$self, %attrs );
   }

   # Other generic read/write accessors
   our $AUTOLOAD;
   sub AUTOLOAD {
      my $attr= substr($AUTOLOAD, rindex($AUTOLOAD, ':')+1);
      my $self= shift;
      carp "Unknown group attribute '$attr'"
         unless exists $known_attrs{$attr} || exists $self->{$attr};
      @_? ( $self->{$attr}= shift ) : $self->{$attr};
   }

   sub import {}
   sub DESTROY {}
}

# Avoiding dependency on namespace::clean
{  no strict 'refs';
   delete @{"Sys::Export::Unix::"}{qw(
      croak carp catfile dclone getpwnam pw_has
      isa_export_dst isa_exporter isa_group isa_user isa_userdb
   )};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Unix::UserDB - Abstractions for Unix passwd/group/shadow files

=head1 SYNOPSIS

  use Sys::Export::Unix::UserDB;
  
  # Load from filesystem
  my $source_db = Sys::Export::Unix::UserDB->new;
  $source_db->load('/path/to/source/etc');
  
  # Create destination database and import some users/groups
  my $dest_db = Sys::Export::Unix::UserDB->new(
    auto_import => $source_db,
    users => [qw( root daemon postgres nobody )],
    groups => [qw( root wheel daemon video audio )],
  );
  
  # Add new users and groups
  $dest_db->add_group('newgroup', gid => 1001);
  $dest_db->add_user('newuser', uid => 1001, groups => [qw( audio video newgroup )]);
  
  # Save to files
  $dest_db->save('/path/to/dest/etc', format => 'Linux');

=head1 DESCRIPTION

This module provides abstractions for working with Unix 'passwd' databases, consisting of the
C</etc/passwd> and C</etc/group> files, as well as platform-specific extensions like
C</etc/shadow>. (currently only Linux is supported, but BSD C</etc/master.passwd> wouldn't be
hard to add support for)

The goal of this object is to extract user/group information from one system image and merge it
into another, with proper conflict detection and UID/GID management.  It can also import users
and groups from the host via C<getpwnam>/C<getgrnam>.

=head1 ATTRIBUTES

=head2 users

A hashref of C<< username => $user_obj >>.

=head2 uids

A convenience hashref C<< uid => $first_user_obj_having_uid >>.

=head2 groups

A hashref of C<< groupname => $group_obj >>.

=head2 gids

A convenience hashref C<< gid => $first_group_obj_having_gid >>.

=head2 auto_import

This setting causes L</user> (or L</group>) with an unknown name or ID to attempt to import the
user/group rather than returning false.  If the import fails, the L</user> / L</group> methods
return false as normal.

If the value of this attribute is an instance of L<Sys::Export::Unix::UserDB>, it imports from
that other user database.  If the value is a simple true scalar, it imports from the host via
L<getpwnam> etc.  See L</import_user> for a description of how imports work.

=head1 METHODS

=head2 clone

   my $cloned_db = $userdb->clone;

Creates a deep clone of the entire UserDB object.

=head2 is_valid_name

Return true if a name is valid for users/groups of a UserDB.  By default this uses a fairly
permissive regular expression, and future versions may become more permissive.  You can override
it with something more specific to your system by passing C<< valid_name_regex => qr/.../ >> to
the constructor.  You could also override this method in a subclass.

=head2 load

   $userdb->load($path);

Given a path like C</example/etc>, reads passwd, group, and (if readable) shadow files
from that directory.  Future versions may also support C<master.passwd> for BSD support.

=head2 save

   $userdb->save($path_or_hashref);

If given a path, saves passwd, group, and shadow files to that directory.
If given a hashref, saves the file contents into scalars named 'passwd', 'group', 'shadow'.

=head2 import_user

   $user= $userdb->import_user($name);         # attrs from getpwnam
   $user= $userdb->import_user($user_obj);     # from another userdb
   $user= $userdb->import_user($name, %attrs); # like add_user, but "DWIM"

Imports a user into this UserDB.  This differs from L</add_user> in that it will attempt to
re-number foreign UID/GIDs that conflcit with UID/GIDs that already exist in this UserDB.
UID/GID under 1000 are considered "service accounts" and remapping will choose a new number
on the same side of that divider as the old number.  You should specify a name rather than GID
for the user's primary group.  If the group name is the same as the user name, this will create
a group with GID equal to the UID.

B<Note>: B<the behavior of this function is subject to change> if I can find better ways to
I<Do What I Mean> for an import.  If you want perfect backward compatibility, you should add the
users and groups directly with the C<add_*> functions.

Returns the newly created user object, or dies.

=head2 import_group

   $group= $userdb->import_group($name);         # attrs from getgrnam
   $group= $userdb->import_group($group_obj);    # from another userdb
   $group= $userdb->import_group($name, %attrs); # like add_group, but "DWIM"

Imports a group into this UserDB.  This differs from L</add_group> in that it will attempt to
re-number foreign GIDs that conflcit with GIDs that already exist in this UserDB.
GIDs under 1000 are considered "service accounts" and remapping will choose a new number
on the same side of that divider as the old number.

Returns the newly created group object, or dies.

=head2 add_user

   $user= $userdb->add_user($name_or_user_obj, %attrs);

Creates a new user. If the first parameter is a User object, clones it. Otherwise creates 
a new user with the given name.  Duplicate names throw an exception, but duplicate UIDs only
warn.

Returns the newly created user object, or dies.

=head2 add_group

   $group= $userdb->add_group($name_or_group_obj, %attrs);

Creates a new group. If the first parameter is a Group object, clones it. Otherwise creates a
new group with the given name.  Duplicate names throw an exception, but duplicate UIDs only
warn.

Returns the newly created group object, or dies.

=head2 user

   $user = $userdb->user($name_or_uid);

Returns a user by name or UID if it exists, C<undef> otherwise.
If L</auto_import> is enabled, this may first attempt to import the requested UID/name.

=head2 has_user

Like L</user> but returns a boolean and doesn't attempt to C<auto_import>.

=head2 group

   $group = $userdb->group($name_or_uid);

Returns a group by name or GID if it exists, C<undef> otherwise.
If L</auto_import> is enabled, this may first attempt to import the requested GID/name.

=head2 has_group

Like L</group> but returns a boolean and doesn't attempt to C<auto_import>.

=head1 CONSTRUCTOR

=head2 new

  $udb= Sys::Export::Unix::UserDB->new(%options);

=over

=item auto_import

The L</auto_import> attribute, which can be another UserDB, or any "true" value meaning to
import from the host.

=item valid_name_regex

Affects the result of L</is_valid_name>, unless overridden in a subclass

=item users

Hashref of C<< { username => \%user_attrs } >> of users to be added.
An arrayref of usernames can be used if you set C<auto_import>, in which case each name will
be imported (but must exist in the auto_import source).  THis can also be an arrayref of
User objects.

=item groups

Hashref of C<< { groupname => \%group_attrs } >> of groups to be added.
An arrayref of group names can be used if you set C<auto_import>.  It can also be an arrayref
of Group objects.

=back

=head1 USER OBJECTS

The user entries in the UserDB are represented as mostly-writeable objects.  These deviate from
the normal fields of /etc/passwd by having a C<group> attribute instead of C<gid>.  The C<gid>
is resolved during export using the UserDB's group list.  Also, the supplemental groups are
stored on the user object instead of as a list of members on the group object.  There are also
attributes for the fields of the shadow file.

You may declare arbitrary attributes, but you get a warning if they aren't known.  This allows
future compatibility with formats other than Linux.

=head2 User Attributes

This object supports accessors for arbitrary attributes via AUTOLOAD, but the following are
pre-defined.  Using an unknown attribute accessor generates a warning, which you can suppress
by adding keys to the set of C<%Sys::Export::Unix::UserDB::User::known_attrs>.

=over

=item name

Required

=item uid

Required

=item group

Required, and should be a name rather than a GID.

=item groups

A set (hashref) of supplemental group names, but you may assign using an arrayref for convenience.

=item comment

General user information, usually full name

=item gecos

More specific type of comment which should be composed of Full Name, Ofice Location, Work Tel.
and Home Tel.  User-editable, so structure is not enforced.

=item dir

Home directory path

=item shell

Login shell, or program to run on login

=item passwd

The hashed password.  This field is written to the C<shadow> file.  If a shadow file entry is
required (for this or other shadow fields) then the C<passwd> file field is written as C<x>,
else C<*>.

=item expire

Unix time when account will expire (converted to epoch seconds if the field was stored as days)

=item pw_last_change

Unix time of last password change (converted to epoch seconds if the field was stored as days)

=item pw_min_age

Min days before password can be changed

=item pw_max_age

Max days before password must be changed

=item pw_warn_days

Days before max when warning is given to user

=item pw_inactive_days

Days after max when user can still log in and immediately change password

=back

=head2 User Methods

=over

=item new

=item clone

=item add_group

=item remove_group

=back

=head1 GROUP OBJECTS

While the /etc/group file normally stores a list of users belonging to a group, this UserDB
implementation stores a set of groups on the user object, so the group object is rather empty.

=head2 Group Attributes:

This object supports accessors for arbitrary attributes via AUTOLOAD, but the following are
pre-defined.  Using an unknown attribute accessor generates a warning, which you can suppress
by adding keys to the set of C<%Sys::Export::Unix::UserDB::Group::known_attrs>.

=over

=item name

Group name

=item gid

Group ID

=item passwd

Group password, which should never be used anyway.  Leave this C<undef> or C<'*'>.

=back

=head2 Group Methods:

=over

=item new

=item clone

=back

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
