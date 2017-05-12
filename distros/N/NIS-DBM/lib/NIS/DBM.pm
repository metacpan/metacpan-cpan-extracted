# $Id: DBM.pm,v 1.14 1999/09/24 20:31:02 jgsmith Exp $
#
# Copyright (c) 1999, Texas A&M University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTERS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package NIS::DBM;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use IniConf;
use Carp;
use NDBM_File;
use Net::NIS;
use Fcntl;
use IPC::Open3;
use LockFile::Simple qw(lock unlock);

@ISA = qw( );

$VERSION = '0.02';

sub whowasi {
  return ((caller(1))[3]);
}

sub configure {
  my $self = shift;

  my $configfile = $self->{'config_file'};
  my @sections = @{ $self->{'sections'} };
  push @sections, 'nismgmt';
  my $cfg = new IniConf(-file => $configfile);

  my %available_sections = map(($_=>1), $cfg->Sections);

  my %required = (map(($_ => 1), @{ $self->{'required_keys'} },
    qw/yp_top name_db_files uid_db_files yp_push_cmd/
  ) );

  @sections = grep $available_sections{$_}, @sections;

  foreach (map(($cfg->Parameters($_)), @sections)) {
    delete $required{$_};
  }

  foreach (keys %{ $self->{'default_keys'} }) {
    delete $required{$_};
  }
   
  if(scalar(keys(%required)) > 1) {
    croak "Required parameters missing: " . join(", ", keys %required);
  } elsif(scalar(keys(%required)) == 1) {
    croak "Required parameter missing: " . (keys %required)[0];
  } else {
    while(@sections) {
      my ($c) = shift @sections;
      foreach my $k ( $cfg->Parameters($c) ) {
        next if defined $self->{'options'}->{$k};
        $self->{'options'}->{$k} = $cfg->val($c,$k) 
      }
    }
    foreach my $k (keys %{$self->{'default_keys'}}) {
      next if defined $self->{'options'}->{$k};
      $self->{'options'}->{$k} = $self->{'default_keys'}->{$k};
    }
  }
}

sub get_options {
  my $self = shift;

  return keys(%{$self->{'options'}});
}

sub get_option {
  my $self = shift;
  my $opt  = shift;

  return $self->{'options'}->{$opt};
}

sub set_option {
  my $self = shift;

  while(@_) {
    my $k = shift;
    my $v = shift;

    $self->{'options'}->{$k} = $v;
  }
}

sub prepare {
  my $self = shift;

  my %file_types = (name_db_files => 'byname',
                    uid_db_files  => 'byuid',
                   );

  my($ypstat, $ypdom) = Net::NIS::yp_get_default_domain();
  if($ypstat) {
    carp "Unable to determine yp_domain: $!";
    return 0;
  }

  $self->{'yp_domain'} = $ypdom;

  unless(defined $self->{'options'}->{'yp_top'}) {
    carp "No path defined for the yp_top";
    return 0;
  }

  unless(chdir($self->{'options'}->{'yp_top'})) {
    carp "Unable to chdir to " . $self->{'options'}->{'yp_top'}. ": $!";
    return 0;
  }

  $self->{'yp_domain_maps'} = join('/', $self->{'options'}->{'yp_top'},
                                        $ypdom);
  
  unless(chdir($self->{'yp_domain_maps'})) {
    carp "Unable to chdir to $$self{'yp_domain_maps'}: $!";
    return 0;
  }

  foreach my $t (keys %file_types) {
    if($self->{'options'}->{$t}) {
      $self->{$t} = [ split(/\s+/, $self->{'options'}->{$t}) ];
    } else {
      carp "No $t defined";
      return 0;
    }
  }

  my $errors = 0;
  foreach my $t (keys %file_types) {
    foreach my $db (@{ $self->{$t} }) {
      if(! -f "$$self{'yp_domain_maps'}/$db.dir") {
        $errors++;
        carp "Unable to locate one of the $t: $$self{'yp_domain_maps'}/$db.dir";
      }
      if(! -f "$$self{'yp_domain_maps'}/$db.pag") {
        $errors++;
        carp "Unable to locate one of the $t: $$self{'yp_domain_maps'}/$db.pag";
      }
      if($db =~ /adjunct/) {
        $self->{'options'}->{'use_adjunct'} = 1;
      }
    }
  }
  if($errors) {
    croak "Problems with one or more of the db files";
  }

  if(! -x $self->{'options'}->{'yp_push_cmd'}) {
    croak "Unable to find executable for yp_push_cmd: " .
          $self->{'options'}->{'yp_push_cmd'};
  }

  $self->{'need_push'} = 0;

  return 0 unless($self->locked);
  
  chdir($self->{'yp_domain_maps'});

  my @db_files;
  foreach my $t (keys %file_types) {
    foreach my $file (@{ $self->{$t} }) {
      push @db_files, {};
      $db_files[-1]->{'filename'} = $file;
      $db_files[-1]->{'type'} = $file_types{$t};
      if(! tie %{$db_files[-1]->{'handle'}}, 'NDBM_File', 
                   $file, O_RDWR|O_CREAT, 0600)
      {
        croak "Unable to map ndbm file: $file: $!";
      }
      $db_files[-1]->{'open'} = 1;
      $db_files[-1]->{'need_push'} = 0;
    }
  }

  $self->{'DB_FILES'} = \@db_files;

  return 1;
}


sub TIEHASH {
  my $class = shift;
  $class = ref($class) || $class;
  my $opts;
  my $configfile;
  my @confighandlers;

  my $self = { };
  bless $self, $class;

  if(@_) {
    if(@_ == 1) {
      if(ref($_[0])) {
        $opts = $_[0];
      } else {
        $opts = { 'config_file' => shift,
                  'sections'   => [ ],
                };
      }
    } else {
      my %args = (@_);
      if(exists $args{'filename'} and exists $args{'program_tag'}) {
        # looks like ConfigHandler...
        $opts = { config_file     => $args{'filename'},
                  sections        => [$args{'program_tag'} ],
                  default_keys    => $args{'default'},
                  required_keys   => $args{'required'},
                };
      } else {
        $opts = \%args;
      }
    }
  }

  $self->{'config_file'}   = $opts->{'config_file'}   || '/etc/accounts.conf';
  $self->{'sections'}      = $opts->{'sections'}      || [ ];
  $self->{'default_keys'}  = $opts->{'default_keys'}  || { };
  $self->{'required_keys'} = $opts->{'required_keys'} || [ ];

  if($opts->{'program_name'}) {
    $self->{'program_name'} = $opts->{'program_name'};
  } else {
    ($self->{'program_name'} = $0) =~ s,.*/,,;
  }

  foreach my $k (qw/config_file sections default_keys required_keys/,
                 qw/program_name/)
  {
    delete $opts->{$k};
  }

  $self->{'options'} = { %{$opts} };

  $self->configure;

  $self->prepare;

  return $self;
}

sub FETCH {
  my $self = shift;
  my $key  = shift;
  my $uname;
  my $uid;
  my %u;
  my(%u_byuid, %u_byname);
  my $key_set = $self->{options}->{key_set};

  if($key_set ne 'byuid' and $key_set ne 'byname') {
    $key_set = '';
  }

  if($key_set) {
    return undef if defined $self->{'DEL'}->{$key_set}->{$key};
  } else {
    return undef if(defined $self->{'DEL'}->{'byname'}->{$key} ||
                    defined $self->{'DEL'}->{'byuid'}->{$key});
  }

  if($key_set) {
    return { %{ $self->{'MODS'}->{$key_set}->{$key} } }
                  if defined $self->{'MODS'}->{$key_set}->{$key};
  } else {
    return { %{ $self->{'MODS'}->{'byname'}->{$key} } }
                  if defined $self->{'MODS'}->{'byname'}->{$key};
    return { %{ $self->{'MODS'}->{'byuid'}->{$key} } }
                  if defined $self->{'MODS'}->{'byuid'}->{$key};
  }

  if($key_set) {
    if(defined $self->{'CACHE'}->{$key_set}->{$key}) {
      return { %{ $self->{'CACHE'}->{$key_set}->{$key} } };
    }
  }

  if(!$key_set && defined $self->{'CACHE'}->{'byname'}->{$key}) {
    return { %{ $self->{'CACHE'}->{'byname'}->{$key} } };
  }
  if(!$key_set && defined $self->{'CACHE'}->{'byuid'}->{$key}) {
    return { %{ $self->{'CACHE'}->{'byuid'}->{$key} } };
  }

  if(!$key_set || $key_set ne 'byuid') {
    # assume $key is a username first
    $self->_fetch_records('byname', $key, \%u_byname);
  }

  if(scalar keys %u_byname) {
    $uname = $key;
    $uid = $u_byname{'uid'};
  } else {
    return undef if($key_set eq 'byname');
    $uid = $key;
  }

  if(defined $uid) {
    $self->_fetch_records('byuid', $uid, \%u_byuid);
  }

  unless($uname) {
    $uname = $u_byuid{'username'};
    $self->_fetch_records('byname', $uname, \%u_byname);
  }

  my($cache_byname, $cache_byuid) = ('CACHE','CACHE');
  if($self->{'options'}->{'use_adjunct'}) {
    $u_byuid{password} = $u_byname{password};
  }
  foreach my $k ((keys %u_byname), (keys %u_byuid)) {
    next if exists $u{$k};
    if($u_byname{$k} =~ /^\s*$/ && $u_byuid{$k}) {
      carp "$k defined in byuid files but not in byname files";
      if($cache_byname eq 'CACHE') {
        carp "Byname files marked for update for $uname:$uid";
        $cache_byname = 'MODS';
      }
      $u{$k} = $u_byuid{$k};
    } elsif($u_byuid{$k} =~ /^\s*$/ && $u_byname{$k}) {
      carp "$k defined in byname files but not in byuid files";
      if($cache_byuid eq 'CACHE') {
        carp "Byuid files marked for update for $uname:$uid";
        $cache_byuid = 'MODS';
      }
      $u{$k} = $u_byname{$k};
    } elsif($u_byname{$k} ne $u_byuid{$k}) {
      croak "$k inconsistant - (byname,byuid) = ('$u_byname{$k}','$u_byuid{$k}')";
    } else {
      $u{$k} = $u_byname{$k};
    }
  }

  if(scalar keys %u) {
    $u{'uid'} = $u{'uid'} + 0;
    $u{'gid'} = $u{'gid'} + 0;
    $self->{$cache_byname}->{'byname'}->{$u{username}} = { %u };
    $self->{$cache_byuid }->{'byuid'}->{$u{uid}} = { %u };
    return { %u };
  } else {
    return undef;
  }
}

sub _fetch_records {
  my $self = shift;
  my $type = shift;
  my $key  = shift;
  my $u    = shift;
  my @dbfiles = grep { $_->{'type'} eq $type } @{$self->{'DB_FILES'}};
  my %tu;
  my %u;
  my $cache = 'CACHE';

  foreach my $i (0..$#dbfiles)
  { 
    my $db = $dbfiles[$i];
    my $dbinfo = $db->{'handle'}->{$key};
    my $dbname = $db->{'filename'};
    if(defined $dbinfo) {  
      my @dbinfo = split(/:/, $dbinfo);
      # do consistancy/sanity checks...
      if($self->{'options'}->{'use_adjunct'}) {
        if($db->{'filename'} !~ /adjunct/ and $dbinfo[1] ne "##$dbinfo[0]") 
        {
          carp "Invalid data in passwd file ($dbname), passwd field != ##$dbinfo[0]";
        }
      }
      $tu{'username'} = $dbinfo[0];
      $tu{'uid'     } = $dbinfo[2];
      $tu{'gid'     } = $dbinfo[3];
      $tu{'gecos'   } = $dbinfo[4];
      $tu{'home'    } = $dbinfo[5];
      $tu{'shell'   } = $dbinfo[6];

      delete $tu{'uid'} if($tu{'uid'} =~ /^\s*$/);
      delete $tu{'gid'} if($tu{'gid'} =~ /^\s*$/);

      $tu{'uid'} .= 'E0' if(exists $tu{'uid'} && !$tu{'uid'});
      $tu{'gid'} .= 'E0' if(exists $tu{'gid'} && !$tu{'gid'});

      if($self->{'options'}->{'use_adjunct'}) {
        if($db->{'filename'} =~ /adjunct/) {
          $tu{'password'} = $dbinfo[1];
          $u{password} = $tu{password} if $u{password} =~ /^(##\Q$u{username}\E|\s*)$/;
          $tu{password} = $u{password} if $u{password} !~ /^(##\Q$u{username}\E|\s*)$/;
        }
      } else {
        $tu{'password'} = $dbinfo[1];
      }
      if($i) {
        foreach my $k ((keys %tu), (keys %u)) {
          next if exists $u{$k};
          if($tu{$k} =~ /^\s*$/ && $u{$k}) {
            carp "$k defined in $type files but not in $dbname";
            if($cache eq 'CACHE') {
              carp "$type files marked for update for $key";
              $cache = 'MODS';
            }
            #$u{$k} = $tu{$k};
          } elsif($u{$k} =~ /^\s*$/ && $tu{$k}) {
            carp "$k defined in $dbname but not in $type files";
            if($cache eq 'CACHE') {
              carp "\U$type\E files marked for update for $key";
              $cache = 'MODS';
            }
            $u{$k} = $tu{$k};
          } elsif($tu{$k} ne $u{$k}) {
            croak "$k inconsistant - ($type,$dbname) = ('$u{$k}','$tu{$k}')";
          } else {
            $u{$k} = $tu{$k};
          }
        }
      } else {
        %u = %tu;
      }
    }

    foreach my $k (keys %u) {
      delete $u{$k} if $u{$k} =~ /^\s*$/;
    }
  }
  %{$u} = %u;
  if($cache ne 'CACHE') {
    $self->{'MODS'}->{$cache}->{'MODS'}->{$key} = { %u };
  }
}

sub STORE {
  my $self = shift;
  my $key  = shift;
  my $value;
  my $key_set = $self->{options}->{key_set} || '';

  if($key_set ne 'byuid' and $key_set ne 'byname') {
    $key_set = '';
  }

  croak "@{[&whowasi]}: $key not clobberable" unless $self->{'options'}->{'CLOBBER'};

  if(ref($_[0]) eq 'HASH') {
    $value = $_[0];
  } else {
    $value = { @_ };
  }

  if($self->EXISTS($key)) {
    # we are modifying
    my $oldvalue = $self->FETCH($key);

    my $changed = '';
    foreach my $k (keys %{$oldvalue}) {
      $changed .= $k if $$oldvalue{$k} ne $$value{$k};
    }
    return if $changed =~ /^\s*$/;
    $$value{password_only} = 1 if $changed eq 'password';

    delete $self->{DEL}->{byuid} ->{$$value{uid}};
    delete $self->{DEL}->{byname}->{$$value{username}};
  }

  $self->{MODS}->{byuid} ->{$$value{uid}}      = $value;
  $self->{MODS}->{byname}->{$$value{username}} = $value;
  
  delete $self->{CACHE}->{byname}->{$$value{username}};
  delete $self->{CACHE}->{byuid} ->{$$value{uid}};
}
  
sub EXISTS {
  my $self = shift;
  my $key  = shift;
  my $key_set = $self->{options}->{key_set} || '';

  if($key_set ne 'byuid' and $key_set ne 'byname') {
    $key_set = '';
  }

  if($key_set) {
    return 0 if $self->{'DEL'}->{$key_set}->{$key};
    return 1 if exists $self->{'CACHE'}->{$key_set}->{$key};
    return 1 if exists $self->{'MODS'}->{$key_set}->{$key};

    foreach my $db (grep {$_->{type} eq $key_set} @{$self->{'DB_FILES'}})
    {
      my $dbinfo = $db->{'handle'}->{$key};
      if(defined $dbinfo) {
        $self->{'CACHE'}->{$key} = undef;
        return 1;
      }
    }
  } else {
    return 0 if($self->{'DEL'}->{'byuid'}->{$key} || $self->{'DEL'}->{'byname'}->{$key});
    return 1 if exists $self->{CACHE}->{byuid} ->{$key};
    return 1 if exists $self->{CACHE}->{byname}->{$key};
    return 1 if exists $self->{MODS} ->{byuid} ->{$key};
    return 1 if exists $self->{MODS} ->{byname}->{$key};

    foreach my $db (@{$self->{'DB_FILES'}})
    {
      my $dbinfo = $db->{'handle'}->{$key};
      if(defined $dbinfo) {
        $self->{'CACHE'}->{$key} = undef;
        return 1;
      }
    }
  }

  return 0;
}

sub CLEAR {
  # we really don't want to remove the DB files...
  carp "@{[&whowasi]}: Database not clobberable";
}

sub FIRSTKEY {
  my $self = shift;
  my @keys;

  $self->{'KEYS'} = { };

  if($self->{options}->{key_set} eq 'byuid' ||
     $self->{options}->{key_set} eq 'byname') {
    @keys = grep {$_->{type} eq $self->{options}->{key_set}} @{$self->{'DB_FILES'}};
  } else {
    @keys = @{$self->{'DB_FILES'}};
  }

  foreach my $db (@keys) {
    foreach my $k (keys %{$db->{'handle'}}) {
      $self->{'KEYS'}->{$k}++;
    }
  }

  if($self->{options}->{key_set} eq 'byuid') {
    @keys = grep {$_ = $self->{'DEL'}->{$_}->{uid}} keys %{$self->{'DEL'}};
  } elsif($self->{options}->{key_set} eq 'byname') {
    @keys = grep {$_ eq $self->{'DEL'}->{$_}->{username}} keys %{$self->{'DEL'}};
  } else {
    @keys = keys %{$self->{'DEL'}};
  }

  foreach my $k (@keys) {
    delete $self->{'KEYS'}->{$k};
  }

  if($self->{options}->{key_set} eq 'byuid') {
    @keys = grep {$_ = $self->{'MODS'}->{$_}->{uid}} keys %{$self->{'MODS'}};
  } elsif($self->{options}->{key_set} eq 'byname') {
    @keys = grep {$_ eq $self->{'MODS'}->{$_}->{username}} keys %{$self->{'MODS'}}; 
  } else {
    @keys = keys %{$self->{'MODS'}};
  }

  foreach my $k (@keys) {
    $self->{'KEYS'}->{$k}++;
  }

  delete $self->{KEYS}->{YP_LAST_MODIFIED};

  $self->{'KEYS'} = [ keys %{$self->{'KEYS'}} ];

  return shift @{$self->{'KEYS'}};
}

sub NEXTKEY {
  my $self = shift;

  if($self && $self->{'KEYS'} && ref($self->{'KEYS'}) eq 'ARRAY') {
    return shift @{$self->{'KEYS'}};
  } else {
    return undef;
  }
}

sub DELETE {
  my $self = shift;
  my $key  = shift;
  my $key_set = $self->{options}->{key_set} || '';

  if($key_set ne 'byuid' and $key_set ne 'byname') {
    $key_set = '';
  }

  croak "@{[&whowasi]}: $key not clobberable" unless $self->{'options'}->{'CLOBBER'} > 1;

  if($key_set) {
    delete $self->{CACHE}->{$key_set}->{$key};
    delete $self->{MODS} ->{$key_set}->{$key};
    $self->{DEL}->{$key_set}->{$key}++;
  } else {
    delete $self->{CACHE}->{byname}->{$key};
    delete $self->{MODS} ->{byname}->{$key};
    $self->{DEL}->{byname}->{$key}++;
    if($key =~ /^\d+$/) {
      delete $self->{CACHE}->{byuid}->{$key};
      delete $self->{MODS} ->{byuid}->{$key};
      $self->{DEL}->{byuid}->{$key}++;
    }
  }
}
  
sub flush {
  my $self = shift;
  my $needs_push = 0;
  my $key;

  return unless $self->{'options'}->{'FLUSH'};

  foreach my $key_set (qw/byuid byname/) {
    foreach my $d (keys %{$self->{'DEL'}->{$key_set}}) {
      foreach my $db (@{$self->{'DB_FILES'}}) {
        if($db->{'open'}) {
          if($db->{'type'} eq 'byuid' && $d =~ /^\d+$/) {
            delete($db->{'handle'}->{$d});
            $db->{'need_push'} = 1;
          } elsif($db->{'type'} eq 'byname' && $d !~ /^\d+$/) {
            delete($db->{'handle'}->{$d});
            $db->{'need_push'} = 1;
          }
        }
      }
    }
  }

  my $keys = {};
  my($uadj, $u);
  foreach my $key_set (qw/byuid byname/) {
    foreach my $k (keys %{$self->{'MODS'}->{$key_set}}) {
      my $a = $self->{'MODS'}->{$key_set}->{$k};
      next unless $k eq $$a{username} || $k == $$a{uid};
      next if $keys->{byname}->{$$a{username}} || $keys->{byuid}->{$$a{uid}};
      $keys->{byname}->{$$a{username}}++;
      $keys->{byuid}->{$$a{uid}}++;

      $uadj = "$$a{username}:$$a{password}:$$a{uid}:$$a{gid}:$$a{gecos}:$$a{home}:$$a{shell}";
      if($self->{'options'}->{'use_adjunct'}) {
        $u = "$$a{username}:##$$a{username}:$$a{uid}:$$a{gid}:$$a{gecos}:$$a{home}:$$a{shell}";
      } else {
        $u = $uadj;
      }
  
      foreach my $db (@{$self->{'DB_FILES'}}) {
        my $newkey;
        my $newvalue;
        if($db->{open}) {
          if($db->{type} eq 'byuid') {
            $newkey = $a->{uid};
          } elsif($db->{type} eq 'byname') {
            $newkey = $a->{username};
          } else {
            carp "Unknown filetype, please check config file ($$db{filename})";
            next;
          }
          if($self->{options}->{use_adjunct} &&
             $db->{filename} !~ /adjunct/) 
          {
            if($$a{password_only}) {
              $newvalue = undef;
            } else {
              $newvalue = $u;
            }
          } else {
            $newvalue = $uadj;
          }
          
          if(defined $newvalue) {
            $db->{'handle'}->{$newkey} = $newvalue;
            $db->{'need_push'} = 1;
          }
        }
      }
    }
  }
  # clear caches...
  $self->{'DEL'} = {};
  $self->{'MODS'} = {};
}

sub push_db {
  my $self = shift;
  my %opts = (@_);
 
  foreach my $db (@{$self->{'DB_FILES'}}) {
    next unless $db->{'need_push'};
    if($db->{'open'} && $db->{'handle'}) {
      $db->{handle}->{YP_LAST_MODIFIED} = sprintf("%010d",time());
      untie(%{$db->{'handle'}});
    }
    next unless $self->{'options'}->{'PUSH'};

    my($pid, @out, @err) = 0;
    $pid = open3( \*Wpush, \*Rpush, \*Epush,
                  $self->{'options'}->{'yp_push_cmd'}, '-d', 
                    $self->{'yp_domain'}, $db->{'filename'});
    close(Wpush);
    @out=<Rpush>; @err=<Epush>;
    close(Rpush); close(Epush);
   
    if(!$opts{'no_reopen'} && $db->{'open'}) {
      if(! tie %{$db->{'handle'}}, 'NDBM_File', $db->{'filename'}, 
                                   O_RDWR|O_CREAT, 0600)
      {
        $db->{'open'} = 0;
        carp "Unable to remap ndbm file: $$db{'filename'}: $!";
      }
    }
    
    foreach (grep !/^\s*$/, @out) {
      $self->error(msg => $_);
    }
    $db->{'need_push'} = 0;
  }
}

sub finish {
  my $self = shift;

  foreach my $db (@{$self->{'DB_FILES'}}) {
    if($db->{'open'} && $db->{'handle'}) {
      untie %{$db->{'handle'}};
      $db->{'open'} = 0;
    }
  }

  $self->unlocked;
}

sub DESTROY {
  my $self = shift;

  if($self->{'options'}->{'FLUSH'}) {
    $self->flush;
  }

  # push_db handles the case of PUSH => 0
  $self->push_db(no_reopen => 1);

  $self->finish;
}

sub locked {
  my $self = shift;

  return 1 if $self->{'locked'};

  if(lock($self->{'options'}->{'yp_lock_file'})) {
    $self->{'locked'} = 1;
  } else {
    $self->{'locked'} = 0;
    carp "Unable to lock yp files: $!";
  }
  return $self->{'locked'};
}

sub unlocked {
  my $self = shift;

  return 1 unless $self->{'locked'};

  if(unlock($self->{'options'}->{'yp_lock_file'})) {
    $self->{'locked'} = 0;
  } else {
    $self->{'locked'} = 1;
    carp "Unable to unlock yp files: $!";
  }
  return $self->{'locked'};
}
  
1;
__END__

=head1 NAME

NIS::DBM - Perl module implementing a NIS daemon.

=head1 SYNOPSIS

  use NIS::DBM;

=head1 DESCRIPTION

NIS::DBM trivializes the implementation of daemons and other scripts
which maintain the NIS databases by presenting them as a hash keyed by
both username and user id.  If a numeric username exists in the byname
databases, the number associated with that username will be used as the
user id.  This is the same behavior as B<chown> and B<chgrp>.

NIS::DBM maintains three caches of information to construct an accurate
view of the NIS databases as modified by the program.  The caches are
for actual records from the database, modifications to the database, and 
deletions from the database.  The caches have the following precedence: 
deletions, modifications, and general cache.  The caches may be flushed to 
the database files at any time or upon object destruction.

=head1 NIS::DBM API

=over 4

=item NIS::DBM constructor

This will construct a new NIS::DBM object.  The arguments may be given
in a variaty of ways:

    tie %nis, NIS::DBM, ( 'config filename' );
    tie %nis, NIS::DBM, ( { config_file => 'filename',
                            sections   => [ 'sec1', ... ],
                            default_keys => { keys1 => value1, ... },
                            required_keys => [ key1, key2, ... ]
                          } );
    tie %nis, NIS::DBM, ( config_file => 'filename',
                          sections   => [ 'sec1', ... ],
                          default_keys => { keys1 => value1, ... },
                          required_keys => [ key1, key2, ... ]
                          );
    tie %nis, NIS::DBM, ( filename => '/path/to/conf/file'
                          program_tag => 'string'
                          defaults => { keys1 => value1, ... },
                          required => [ key1, key2, ... ]
                          );

=item FETCH

Given a username or user id, B<FETCH> will return the NIS record as a
hash reference.  B<FETCH> will first consult any caches maintained by the
tied object to provide current information that may not be available in the
database files.

=item STORE

Given a username or user id, B<STORE> will make any modifications to the
caches necessary for the databases to reflect the changes when flushed.  These
same chaches are consulted by B<FETCH>.

=item DELETE

Given a username or user id, B<DELETE> marks the record for deletion.  The
record is not available for B<FETCH>ing or testing for B<EXIST>ance.

=item CLEAR

This is called when the hash is assigned an empty hash or array.  This
function is not implemented.  You cannot remove the NIS user databases
using this module.

=item EXISTS

Given a username or user id, will return true if the key exists in the
modification, addition, or general cache or in the actual database.  Will
return false regardless of the existance in any database or cache if the
record is marked for deletion.

=item FIRSTKEY

This function will initialize an array of keys and return the first.
The keys are unordered.

=item NEXTKEY

This function will return the next key in the array of keys.

=item DESTROY

Flushes any changes in the chaches to the database files and closes them.
This behavior may be overridden by the B<set_option(FLUSH=>0)> method.

=item get_options

Returns a list of options currently set for the object.

=item get_option

Given a key, returns the value of the option.

=item set_option

Given a key/value pair, sets the option to the value.  The following options
are currently used:

=item flush

If FLUSH is set, any changes in the caches will be written out to the database
files.  The caches will be cleared after a flush if data is actually written.

=head1 OPTIONS

=item CLOBBER   

 0 -> databases are read only
 1 -> STORE but not DELETE
 2 -> STORE and DELETE enabled

=item FLUSH

 0 -> do not flush changes from the caches to the databases
 1 -> flush changes from the caches to the databases 
      (by either the flush or DESTROY methods)

=item PUSH

 0 -> do not push changes to other machines
 1 -> push changes if needed to other machines

=item key_set

If this is set to either B<byuid> or B<byname> then only the keys in the
respective files (i.e., uids or usernames) are available as keys.  Otherwise,
the default behavior is to assume username first and uid last.

=item name_db_files

=item uid_db_files

=item use_adjunct

If this is set, the difference between adjunct and non-adjunct files is
recognized.  Otherwise, the normal NIS behavior is used.  If a file is in the
list of dbm files with the string `adjunct' in the name, then the preparation
phase of tieing the hash to the dbm files will set this flag.

=item yp_top

=item yp_src

=item yp_push_cmd

=over 4

=head1 IDIOMS

The following are some idioms using the NIS::DBM tied hash.  The username
and user id are available via $username and $uid respectively.

=item Delete User

    my $userinfo = $nishash{$username || $uid};
    delete $nishash{$$userinfo{'username'}};
    delete $nishash{$$userinfo{'uid'}};

=item Change User's Username

    my $userinfo = $nishash{$username || $uid};
    delete $nishash{$$userinfo{'username'}};
    $$userinfo{'username'} = $new_username;
    $$nishash{$new_username} = $userinfo;
    $$nishash{$$userinfo{'uid'}} = $userinfo;

=item Change User's UID

    my $userinfo = $nishash{$username || $uid};
    delete $nishash{$$userinfo{'uid'}};
    $$userinfo{'username'} = $new_uid;
    $$nishash{$new_uid} = $userinfo;  
    $$nishash{$$userinfo{'username'}} = $userinfo;

=item Add New User

    my $userinfo = { username => $username,
                     uid      => $uid,
                     gid      => $gid,
                     gecos    => $gecos,
                     home     => $home,
                     shell    => $shell,
                     password => crypt($password, $salt)
                   };
    $nishash{$username} = $userinfo;
    $nishash{$uid} = $userinfo;

=head1 AUTHORS

James G. Smith, <jgsmith@tamu.edu>
Philip C. Kizer, <pckizer@tamu.edu>

=head1 COPYRIGHT

Copyright (c) 1999, Texas A&M University.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 3. Neither the name of the University nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTERS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO

perl(1), Net::NIS(3).

=cut
