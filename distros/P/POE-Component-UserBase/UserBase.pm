# $Id: UserBase.pm,v 1.10 2000/12/14 04:15:56 jgoff Exp $
# License and documentation are after __END__.

package POE::Component::UserBase;

use strict;

use vars qw($VERSION);
$VERSION = '0.09';

use Carp qw (croak);

use POE::Session;
use Storable qw(freeze thaw);

BEGIN {
  eval 'use Digest::MD5 qw(md5 md5_hex md5_base64)';
  if(defined $@ and length $@) {
    eval 'sub HAS_MD5 () { 0 }';
  } else {
    eval 'sub HAS_MD5 () { 1 }';
  }
  eval 'use Digest::SHA1 qw(sha1 sha1_hex sha1_base64)';
  if(defined $@ and length $@) {
    eval 'sub HAS_SHA1 () { 0 }';
  } else {
    eval 'sub HAS_SHA1 () { 1 }';
  }
};

sub DEBUG () { 0 }
sub _no_undef { (defined $_[0]) ? $_[0] : '(undef)' }

sub _user_key {
  my $params = shift;
  my $domain = $params->{domain} || '';
  return $params->{user_name} . ':' . $domain;
}

# Spawn a new PoCo::UserBase session.  This basically is a
# constructor, but it isn't named "new" because it doesn't create a
# usable object.  Instead, it spawns the object off as a session.

sub spawn {
  my $type = shift;

  croak qq($type requires an even number of parameters.)
      if @_ % 2;

  my %params = @_;
  $params{Protocol} ||= 'file';  # Default to 'file' protocol
  $params{Cipher}   ||= 'crypt'; # Default to the 'crypt' method of encryption

  my @legal_protocols =
      qw(file dbi);
  my @legal_ciphers =
      qw(crypt des md5 md5_hex md5_base64 sha1 sha1_hex sha1_base64);
  croak qq($type does not understand Protocol '$params{Protocol}'.)
      unless grep { /$params{Protocol}/ } @legal_protocols;
  croak qq($type does not understand Cipher '$params{Cipher}'.)
      unless grep { /$params{Cipher}/ } @legal_ciphers;
  if(!HAS_MD5) {
    croak qq($type cannot load Digest::MD5 for Cipher '$params{Cipher}'.)
	if $params{Cipher} =~ /md5/;
  }
  if(!HAS_SHA1) {
    croak qq($type cannot load Digest::SHA1 for Cipher '$params{Cipher}'.)
	if $params{Cipher} =~ /sha1/;
  }

  my $states = { _start      => \&poco_userbase_start,
		 persist     => \&poco_userbase_persist,
		 log_on      => \&poco_userbase_log_on,
		 log_off     => \&poco_userbase_log_off,

		 create      => \&poco_userbase_create,
		 delete      => \&poco_userbase_delete,
		 update      => \&poco_userbase_update,

		 list_active => \&poco_userbase_list_active,
	       };

  $params{_type} = $type;

  for($params{Protocol}) {
    /file/ and do {
      croak qq($type requires a file name with the 'file' protocol.)
	  unless exists $params{File};
      $params{Dir} = '.persist'
	  unless exists $params{Dir};
      last;
    };
    /dbi/ and do {
      croak qq($type requires a Connection handle with the 'dbi' protocol.)
	  unless exists $params{Connection};
      croak qq($type requires a Table name whne using the 'dbi' protocol.)
	  unless exists $params{Table};
      $params{UserColumn} = 'user_name'
	  unless exists $params{UserColumn};
      $params{PasswordColumn} = 'password'
	  unless exists $params{PasswordColumn};
      $params{DomainColumn} = 'domain'
	  unless exists $params{DomainColumn};
      $params{PersistentColumn} = 'persistent'
	  unless exists $params{PersistentColumn};
      last;
    };
  }

  DEBUG and do {
    warn "\n";
    warn "/--- spawning $type component ---"                    . "\n";
    warn "| Alias      : $params{Alias}"                        . "\n";
    warn "| Protocol   : $params{Protocol}"                     . "\n";
    warn "| Cipher     : $params{Cipher}"                       . "\n";
    for($params{Protocol}) {
      /file/ and do {
	warn "| File       : " . _no_undef($params{File})       . "\n";
	warn "| Dir        : " . $params{Dir}                   . "\n";
	last;
      };
      /dbi/ and do {
	warn "| Connection : " . _no_undef($params{Connection}) . "\n";
	warn "| Table      : " . _no_undef($params{Table})      . "\n";
	last;
      };
    }
    warn "\\--------------------------------"                   . "\n";
  };

  POE::Session->create
      ( inline_states => $states,
	args          => [%params],
      );
  undef;
}

###############################################################################
#
# File - Format is "user_name:password:persistent:domain"
#

sub _create_file {
  my ($heap, $href) = @_;
  open FILE,">>$heap->{File}" or
      croak qq($heap->{_type} could not open '>>$heap->{File}'.);
  binmode(FILE);
  print FILE join ':',( $href->{user_name},
		        $href->{password} || '',
		        $href->{domain}   || '',
		      );
  print FILE "\n";
  close FILE;
}

sub _read_file {
  my ($heap, $href) = @_;
  my ($line,$user_line);

  open FILE,"<$heap->{File}" or
      croak qq($heap->{_type} could not open '<$heap->{File}'.);
  binmode(FILE);
  while(defined($line=<FILE>)) {
    next unless $line=~/^$href->{user_name}/;
    next if defined $href->{domain} && $line!~/:$href->{domain}:/;
    $user_line = $line;
    last;
  }
  close FILE;
  chomp $user_line;
  return unless $user_line;
  my %foo;
  @foo{qw(user_name password domain)} = split ':',$user_line;

  if(-d $heap->{Dir} && open FILE,"< $heap->{Dir}/$href->{user_name}") {
    binmode(FILE);
    $foo{persistent} = join '',<FILE>;
    close FILE;
  } else {
    $foo{persistent} = undef;
  }
  return \%foo;
}

sub __update_line {
  my ($line,$heap,$href) = @_;
  my @rec = split ':',$line;
  
  $rec[0] = $href->{new_user_name}  if $href->{new_user_name};
  $rec[1] = $href->{new_password}   if $href->{new_password};
  $rec[3] = $href->{new_domain}     if $href->{new_domain};

  return join ':',@rec;
}

sub _update_file {
  my ($heap,$href) = @_;
  my @lines;
  open FILE,"<$heap->{File}" or
      croak qq($heap->{_type} could not open '<$heap->{File}'.);
  binmode(FILE);
  @lines=<FILE>;
  close FILE;
  open FILE,">$heap->{File}" or
      croak qq($heap->{_type} could not open '>$heap->{File}'.);
  binmode(FILE);
  for(@lines) {
    if(/^$href->{user_name}/) {
      print FILE __update_line($_,$href);
    } else {
      print FILE $_;
    }
  }
  close FILE;

  -d $heap->{Dir} || mkdir $heap->{Dir},0755;
  unlink "$heap->{Dir}/$href->{user_name}" if $href->{new_user_name};
  open FILE,">$heap->{Dir}/$href->{user_name}";
  binmode(FILE);
  if(defined $href->{persistent}) {
    print FILE $href->{persistent};
  } elsif (defined $href->{new_persistent}) {
    print FILE $href->{new_persistent};
  }
  close FILE;
}

sub _delete_file {
  my ($heap,$href) = @_;
  my @lines;
  open FILE,"<$heap->{File}" or
      croak qq($heap->{_type} could not open '<$heap->{File}'.);
  binmode(FILE);
  @lines=<FILE>;
  close FILE;
  open FILE,">$heap->{File}" or
      croak qq($heap->{_type} could not open '>$heap->{File}'.);
  binmode(FILE);
  for(@lines) {
    print FILE $_ unless /^$href->{user_name}/;
    print FILE $_ if defined $href->{domain} && $_!~/:$href->{domain}:/;
  }
  close FILE;
  unlink "$heap->{Dir}/$href->{user_name}"
      if -e "$href->{Dir}/$href->{user_name}";
}

###############################################################################
#
# Database - uncomment the Pg lines to handle raw Postgres drivers
# or for that matter hack your own database in.
#

sub _create_dbi {
  my ($heap,$href) = @_;
  my $stm = <<_EOSTM_;
insert into $heap->{Table} ($heap->{UserColumn},
			    $heap->{DomainColumn},
			    $heap->{PasswordColumn},
			    $heap->{PersistentColumn}
			   )
values('$heap->{user_name}',
       '$heap->{domain}',
       '$heap->{password}',
       '$heap->{persistent}')
_EOSTM_

  my $sth = $heap->{Connection}->prepare($stm);
  my $rv  = $sth->execute();
  $sth->finish();
}

sub _read_dbi {
  my ($heap,$href) = @_;
  my @fields = qw(user_name domain password persistent);
  my $field_list = join ',',@fields;
  my $stm = <<_EOSTM_;
select $field_list
from $heap->{Table}
where $heap->{UserColumn} like '$href->{user_name}'
_EOSTM_

  $stm .= qq[and $heap->{DomainColumn} like '$href->{domain}'] if
      $href->{domain};

  my $sth = $heap->{Connection}->prepare($stm);
  my $rv  = $sth->execute();
  my $foo = $sth->fetchrow_hashref();
  $sth->finish();
  return $foo;
}

sub _update_dbi {
  my ($heap,$href) = @_;
  $href->{new_user_name}  ||= $href->{user_name};
  $href->{new_domain}     ||= $href->{domain}     || '';
  $href->{new_password}   ||= $href->{password}   || '';
  $href->{new_persistent} ||= $href->{persistent} || '';
  my $stm = <<_EOSTM_;
update $heap->{Table}
set $heap->{UserColumn}       = '$href->{new_user_name}',
    $heap->{DomainColumn}     = '$href->{new_domain}',
    $heap->{PasswordColumn}   = '$href->{new_password}',
    $heap->{PersistentColumn} = '$href->{new_persistent}'
where user_name like '$href->{user_name}'
_EOSTM_

  $stm .= qq[ and $heap->{DomainColumn} like '$href->{domain}'] if
      $href->{domain};
  my $sth = $heap->{Connection}->prepare($stm);
  my $rv  = $sth->execute();
  $sth->finish();
}

sub delete_dbi {
  my ($heap,$href) = @_;
  my $stm = <<_EOSTM_;
delete from $heap->{Table}
where $heap->{UserColumn} = '$href->{user_name}'
_EOSTM_

  $stm .= qq[ and $heap->{DomainColumn} = '$href->{domain}'] if
      $href->{domain};
  my $sth = $heap->{Connection}->prepare($stm);
  my $rv  = $sth->execute();
  $sth->finish();
}

###############################################################################
#
# The main UserBase states
#

sub poco_userbase_start {
  my ($kernel,$heap) =
      @_[KERNEL, HEAP];
  for(my $i=ARG0;$i<@_;$i+=2) { $heap->{$_[$i]}=$_[$i+1]; }
  $kernel->alias_set($heap->{Alias});
}

sub poco_userbase_log_on {
  my $heap   = $_[HEAP];
  my %params = splice @_,ARG0;

  croak qq($heap->{_type} requires a user_name to log on.)
      unless exists $params{user_name};
  croak qq($heap->{_type} requires a response state to return to.)
      unless exists $params{response};
  
  DEBUG and do {
    warn "\n";
    warn "/--- $heap->{_type} logging in ---"                . "\n";
    warn "| user_name  : $params{user_name}"                 . "\n";
    warn "| password   : " . _no_undef($params{password})    . "\n";
    warn "| persistent : " . _no_undef($params{persistent})  . "\n";
    warn "| domain     : " . _no_undef($params{domain})      . "\n";
    warn "| response   : $params{response}"                  . "\n";
    warn "\\-------------------"                             . "\n";
  };

  my $uref;
  for($heap->{Protocol}) {
    /file/ && do { $uref = _read_file($heap,\%params); last; };
    /dbi/  && do { $uref = _read_dbi($heap,\%params);  last; };
  }
  my $auth = 0;

  if($uref->{user_name}) {
    warn qq(Found user_name $uref->{user_name}) if DEBUG;
    if($uref->{password}) {
      warn qq(Found password $uref->{password}, trying to match) if DEBUG;
      for($heap->{Cipher}) {
	/crypt/ && do {
	  $auth = 1 if
	      crypt($params{password},$uref->{password}) eq $uref->{password};
	  last;
	};
	/md5$/ && do {
	  $auth = 1 if md5($params{password}) eq $uref->{password};
	  last;
	};
	/md5_hex$/ && do {
	  $auth = 1 if md5_hex($params{password}) eq $uref->{password};
	  last;
	};
	/md5_base64$/ && do {
	  $auth = 1 if md5_base64($params{password}) eq $uref->{password};
	  last;
	};
	/sha1$/ && do {
	  $auth = 1 if
	      sha1($params{password}) eq $uref->{password};
	  last;
	};
	/sha1_hex$/ && do {
	  $auth = 1 if sha1_hex($params{password}) eq $uref->{password};
	  last;
	};
	/sha1_base64$/ && do {
	  $auth = 1 if sha1_base64($params{password}) eq $uref->{password};
	  last;
	};
      }
      if($auth) {
	warn qq(Found matching password) if DEBUG;
      } else {
	warn qq(Did not find matching password) if DEBUG;
      }
    } else {
      warn qq(No password to match, assuming that it's authorized) if DEBUG;
      $auth = 1;
    }
  } else {
    warn qq(Failed to authorize $params{user_name}) if DEBUG;
  }

  if($auth) {
    $heap->{Users}{_user_key(\%params)} = { logged_in  => 1,
					    persistent => $params{persistent},
					  };
    $params{persistent}{_persistent} = thaw($uref->{persistent})
      if $uref->{persistent} && $uref->{persistent} ne '';
  }

  $_[SENDER]->postback($params{response})->($auth,
					    $params{user_name},
					    $params{domain},
					    $params{password} );
}

sub poco_userbase_log_off {
  my $heap   = $_[HEAP];
  my %params = splice @_,ARG0;

  croak qq($heap->{user_name} requires a user_name to log on.)
      unless exists $params{user_name};
  
  DEBUG and do {
    warn "\n";
    warn "/--- $heap->{_type} logging out ---"         . "\n";
    warn "| user_name : $params{user_name}"            . "\n";
    warn "| domain    : " . _no_undef($params{domain}) . "\n";
    warn "\\--------------------"                      . "\n";
  };

  my $persist_ref =
      $heap->{Users}{_user_key(\%params)}{persistent}{_persistent};
  $persist_ref = freeze($persist_ref) if defined $persist_ref;
  my $rec = { user_name      => $params{user_name},
	      domain         => $params{domain},
	      new_persistent => $persist_ref,
	    };

  for($heap->{Protocol}) {
    /file/ and do { _update_file($heap,$rec); last; };
    /dbi/  and do { _update_dbi($heap,$rec);  last; };
  }

  delete $heap->{Users}{_user_key(\%params)};
}

###############################################################################

sub poco_userbase_create {
  my $heap     = $_[HEAP];
  my $protocol = $heap->{Protocol};
  my %params   = splice @_,ARG0;

  croak qq($heap->{_type} could not create user without valid username.)
      unless exists $params{user_name};

  DEBUG and do {
    warn "\n";
    warn "/--- $heap->{_type} creating user ---"         . "\n";
    warn "| user_name : $params{user_name}"              . "\n";
    warn "| domain    : " . _no_undef($params{domain})   . "\n";
    warn "| password  : " . _no_undef($params{password}) . "\n";
    warn "\\-------------------"                         . "\n";
  };

  if($params{password}) {
    for($heap->{Cipher}) {
      /crypt/ && do {
	my $salt =
	    join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
	$params{password} = crypt($params{password},$salt);
	last;
      };
      /md5$/ && do {
	$params{password} = md5($params{password});
	last;
      };
      /md5_hex$/ && do {
	$params{password} = md5_hex($params{password});
	last;
      };
      /md5_base64$/ && do {
	$params{password} = md5_base64($params{password});
	last;
      };
      /sha1$/ && do {
	$params{password} = sha1($params{password});
	last;
      };
      /sha1_hex$/ && do {
	$params{password} = sha1_hex($params{password});
	last;
      };
      /sha1_base64$/ && do {
	$params{password} = sha1_base64($params{password});
	last;
      };
    }
  }

  for($heap->{Protocol}) {
    /file/ and do { _create_file($heap,\%params); last; };
    /dbi/  and do { _create_dbi($heap,\%params);  last; };
  }
}

sub poco_userbase_delete {
  my $heap     = $_[HEAP];
  my $protocol = $heap->{Protocol};
  my %params   = splice @_,ARG0;

  croak qq($heap->{_type} could not delete a user without a user_name.)
      unless exists $params{user_name};
  
  DEBUG and do {
    warn "\n";
    warn "/--- logging in ---"                           . "\n";
    warn "| user_name : $params{user_name}"              . "\n";
    warn "| domain    : " . _no_undef($params{domain})   . "\n";
    warn "| password  : " . _no_undef($params{password}) . "\n";
    warn "\\-------------------"                         . "\n";
  };

  for($heap->{Protocol}) {
    /file/ and do { _delete_file($heap,\%params); last; };
    /dbi/  and do { _delete_dbi($heap,\%params);  last; };
  }
}

sub poco_userbase_update {
  my $heap     = $_[HEAP];
  my $protocol = $heap->{Protocol};
  my %params   = splice @_,ARG0;
  
  DEBUG and do {
    warn "\n";
    warn "/--- $heap->{_type} updating  ---"             . "\n";
    warn "| user_name : $params{user_name}"              . "\n";
    warn "| domain    : " . _no_undef($params{domain})   . "\n";
    warn "| password  : " . _no_undef($params{password}) . "\n";
    warn "\\-------------------"                         . "\n";
  };

  for($heap->{Cipher}) {
    /crypt/ && do {
      my $salt =
	  join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
      $params{password} = crypt($params{password},$salt);
      last;
    };
    /md5$/ && do {
      $params{password} = md5($params{password});
      last;
    };
    /md5_hex$/ && do {
      $params{password} = md5_hex($params{password});
      last;
    };
    /md5_base64$/ && do {
      $params{password} = md5_base64($params{password});
	last;
    };
    /sha1$/ && do {
      $params{password} = sha1($params{password});
      last;
    };
    /sha1_hex$/ && do {
      $params{password} = sha1_hex($params{password});
      last;
    };
    /sha1_base64$/ && do {
      $params{password} = sha1_base64($params{password});
      last;
    };
  }
  
  for($heap->{Protocol}) {
    /file/ and do { _update_file($heap,\%params); last; };
    /dbi/  and do { _update_dbi($heap,\%params);  last; };
  }
}

###############################################################################

sub poco_userbase_list_active {
  my $heap   = $_[HEAP];
  my %params = splice @_,ARG0;
  
  DEBUG and do {
    warn "\n";
    warn "/--- $heap->{_type} listing active users ---" . "\n";
    warn "| response  : $params{response}"              . "\n";
    warn "\\-------------------"                        . "\n";
  };

  my $users = [map { [split ':'] } keys %{$heap->{Users}} ];
  $_[SENDER]->postback($params{response})->($users);
}

###############################################################################

1;

__END__

=head1 NAME

POE::Component::UserBase - a component to manage user authentication

=head1 SYNOPSIS

  use POE qw(Component::UserBase);

  # The UserBase can deal with many types of repositories.
  # The first kind is a simple file.
  POE::Component::UserBase->spawn
    ( Alias    => 'userbase', # defaults to 'userbase'.
      Protocol => 'file',     # The repository type.
      Cipher   => 'md5',      # defaults to 'crypt'.

      File     => '/home/jgoff/passwd',   # The path to the repository
      Dir      => '/home/jgoff/.persist', # Directory to store persistent
                                          # information.
    );

  POE::Component::UserBase->spawn
    ( Alias         => 'userbase',   # defaults to 'userbase'.
      Protocol      => 'dbi',        # The repository type.
      Cipher        => 'sha1',       # defaults to 'crypt'.

      DBHandle      => $dbh,         # Required, connected to a handle.
      Table         => 'auth',
      UserColumn    => 'user_name',  # defaults to 'username'.
      PassColumn    => 'password',   # defaults to 'password'.
      PersistColumn => 'persistent', # defaults to 'data'. This is our
                                     # persistent data storage.
    );

  # PoCo::UserBase provides generic user-management services to multiple
  # sessions.

  $kernel->post
    ( user_base => log_on => user_name  => $user_name,
                             domain     => $domain,       # optional
		             password   => $password,     # optional
		             persistent => $persistent_reference,
		             response   => $authorized_state,
    );

  $kernel->post
    ( user_base => log_off => user_name => $user_name,
                              password  => $password,    # optional
    );

  $kernel->post
    ( user_base => create => user_name => $user_name,
                             domain    => $domain,       # optional
		             password  => $password,     # optional
    );

  $kernel->post
    ( user_base => delete => user_name => $user_name,
                             domain    => $domain,       # optional
                             password  => $password,     # optional
    );

  $kernel->post
    ( user_base => update => user_name     => $user_name,
	                     domain        => $domain,   # optional
                             password      => $password, # optional
                             new_user_name => $new_name, # optional
		             new_domain    => $new_dom,  # optional
		             new_password  => $new_pass, # optional
    );

=head1 DESCRIPTION

POE::Component::UserBase handles basic user authentication and management tasks
for a POE server. It can authenticate from sources such as a .htaccess file,
database, DBM files, and flat files.

PoCo::UserBase communicates with the client through a previously created
SocketFactory. After a client is has connected, PoCo::UserBase interrogates
the client for its username and password, and returns the connection data from
the socket along with the username and password authenticated.

POE::Component::UserBase's C<spawn> method takes a few parameters to describe
the depository of user names. I'd recommend that you not use any crucial system
files until you assure yourself that it's indeed safe.

The C<spawn> method has several common parameters. These are listed below.

=over 2

=item Alias => $session_alias

C<Alias> sets the name by which the session will be known.  If no
alias is given, the component defaults to "userbase".  The alias lets
several sessions interact with the user manager without keeping (or even
knowing) hard references to them.

=item Cipher => $cipher_type

C<Cipher> sets the cipher that will be used to encrypt the password entries.
If no cipher is given, the component defaults to "crypt". This uses the
native crypt() function. Other cipher choices include 'md5', 'sha1',
'md5_hex', 'sha1_hex', 'md5_base64', and 'sha1_base64'. The 'md5' and 'sha1'
cipher types are documented in the L<Digest::MD5> and L<Digest::SHA1> class.
They're simply different output formats of the original hash.

=back

These parameters are unique to the B<file> Protocol type.

=over 2

=item File => $filename

C<File> sets the file name that is used to store user data. This parameter is
required.

=item Dir => $path_to_persistent_directory

C<Dir> Sets the directory that is used to hold the persistence information.
This directory holds the frozen persistent data, indexed by the user_name.

=back

These parameters are unique to the B<dbi> Protocol type.

=over 2

=item Connection => $dbh_connection

C<Connection> stores a handle to a DBI connection. The database must contain a
table which will hold the username, password, and persistent data.

=item PersistentColumn => $persistent_data_column_name

C<PersistentColumn> specifies the column name used to hold the persistent
data. If you can't allocate enough space to hold your persistent data in the
database, then you can use the C<DataFile> parameter to define a MLDBM file
that will be used to hold this persistent data. The MLDBM data file will be
keyed by the username.

=item DataFile => $data_file_name

C<DataFile> specifies the filename of the MLDBM file used to hold the
persistent data store. Use of this parameter is incompatible with C<Data>.

=item DomainColumn => $domain_column_name

C<DomainColumn> specifies the column used to store the C<domain> column.
It defaults to C<domain>.

=item PasswordColumn => $password_column_name

C<PasswordColumn> specifies the column used to store the C<password> column.
It defaults to C<password>.

=item Table => $dbi_table

C<Table> specifies the table name used to store username, password, and maybe
the persistent data stored along with each user.

=item UserColumn => $user_column_name

C<UserColumn> specifies the column used to store the C<username> column. It
defaults to C<username>. In the event that you use the C<DataFile> parameter,
this column will be kept in sync with the MLDBM file.

=back

Sessions communicate asynchronously with passive UserBase components.
They post their requests through several internal states, and receive data through a state that you specify.

Requests are posted to one of the states below:

=over 2

=item log_on

C<log_on> is to be called when a client wants to authenticate a user.

  $kernel->post
    ( user_base => log_on => user_name  => $user_name,
                             domain     => $domain,       # optional
		             password   => $password,     # optional
		             persistent => $persistent_reference,
		             response   => $authorized_state,
    );

=item log_off

C<log_off> is to be called when a client is finished with a user.

  $kernel->post
    ( user_base => log_off => user_name => $user_name,
                              password  => $password,    # optional
    );

=item create

C<create> lets you create a new user.

  $kernel->post
    ( user_base => create => user_name => $user_name,
                             domain    => $domain,       # optional
		             password  => $password,     # optional
    );

=item delete

C<delete> lets you delete a user.

  $kernel->post
    ( user_base => delete => user_name => $user_name,
                             domain    => $domain,       # optional
                             password  => $password,     # optional
    );

=item update

C<update> lets you update a user.

  $kernel->post
    ( user_base => update => user_name     => $user_name,
	                     domain        => $domain,   # optional
                             password      => $password, # optional
                             new_user_name => $new_name, # optional
		             new_domain    => $new_dom,  # optional
		             new_password  => $new_pass, # optional
    );

=back

For example, authenticating a user is simply a matter of posting a request to
the C<userBase> alias (or whatever you named it). It posts responses back to
either the 'authorization accepted' or 'authorizaton failed' state. If it
successfully authenticates the user, it then fills the alias referenced in the
C<Persistence> parameter with the user data it stored in the database when the
user logged out.

=head1 SEE ALSO

This component is built upon L<POE>.  Please see its source code and
the documentation for its foundation modules to learn more.

Also see the test programs in the t/ directory, and the samples in the
samples/ directory in the POE/Component/UserBase directory.

=head1 BUGS

None currently known.

=head1 AUTHOR & COPYRIGHTS

POE::Component::UserBase is Copyright 1999-2000 by Jeff Goff.  All
rights are reserved.  POE::Component::UserBase is free software; you
may redistribute it and/or modify it under the same terms as Perl
itself.

=cut
