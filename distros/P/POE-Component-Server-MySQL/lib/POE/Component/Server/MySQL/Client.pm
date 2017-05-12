package     # ignore CPAN ..
   POE::Component::Server::MySQL::Client;
use Moose;
use MooseX::MethodAttributes ();

my $VERSION = '0.01_01';

use POE;
use POE::Kernel;
use Module::Find;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use DBI;

has 'database' => (is => 'rw', isa => 'Any');
has 'username' => (is => 'rw', isa => 'Any');
has 'password' => (is => 'rw', isa => 'Any');

has 'wheel' => (is => 'rw', isa => 'Any');
has 'session_id' => (is => 'rw', isa => 'Any');
has 'session' => (is => 'rw', isa => 'Any');
has 'banner' => (is => 'rw', isa => 'Any');

has 'salt' => (is => 'rw', isa => 'Any');
has 'charset' => (is => 'rw', isa => 'Any');
has 'tid' => (is => 'rw', isa => 'Any');
has 'packet_count' => (is => 'rw', isa => 'Any');

has 'scramble' => (is => 'rw', isa => 'Any');
has 'authenticated' => (is => 'rw', isa => 'Any');

has 'server_class' => (is => 'rw', isa => 'Any');

has 'local_dsn' => (is => 'rw', isa => 'Str');
has 'local_user' => (is => 'rw', isa => 'Str');
has 'local_password' => (is => 'rw', isa => 'Str');

has 'local_dbh' => (is => 'rw', isa => 'Any');

has 'dispatchers' => (is => 'rw', isa => 'Any');
has 'default'     => (is => 'rw', isa => 'Any');

has 'type_info' => (is => 'rw', isa => 'Any');

has '_buffer' => (is => 'rw', isa => 'Any');
has 'buffer' => (is => 'rw', isa => 'Any');

use constant FIELD_CATALOG      => 0;
use constant FIELD_DB           => 1;
use constant FIELD_TABLE        => 2;
use constant FIELD_ORG_TABLE    => 3;
use constant FIELD_NAME         => 4;
use constant FIELD_ORG_NAME     => 5;
use constant FIELD_LENGTH       => 6;
use constant FIELD_TYPE         => 7;
use constant FIELD_FLAGS        => 8;
use constant FIELD_DECIMALS     => 9;
use constant FIELD_DEFAULT      => 10;

use constant CLIENT_LONG_PASSWORD           => 1;
use constant CLIENT_FOUND_ROWS              => 2;
use constant CLIENT_LONG_FLAG               => 4;
use constant CLIENT_CONNECT_WITH_DB         => 8;
use constant CLIENT_NO_SCHEMA               => 16;
use constant CLIENT_COMPRESS                => 32;
use constant CLIENT_ODBC                    => 64;
use constant CLIENT_LOCAL_FILES             => 128;
use constant CLIENT_IGNORE_SPACE            => 256;
use constant CLIENT_PROTOCOL_41             => 512;
use constant CLIENT_INTERACTIVE             => 1024;
use constant CLIENT_SSL                     => 2048;
use constant CLIENT_IGNORE_SIGPIPE          => 4096;
use constant CLIENT_TRANSACTIONS            => 8192;
use constant CLIENT_RESERVED                => 16384;
use constant CLIENT_SECURE_CONNECTION       => 32768;
use constant CLIENT_MULTI_STATEMENTS        => 1 << 16;
use constant CLIENT_MULTI_RESULTS           => 1 << 17;
use constant CLIENT_SSL_VERIFY_SERVER_CERT  => 1 << 30;
use constant CLIENT_REMEMBER_OPTIONS        => 1 << 31;

use constant SERVER_STATUS_IN_TRANS             => 1;
use constant SERVER_STATUS_AUTOCOMMIT           => 2;
use constant SERVER_MORE_RESULTS_EXISTS         => 8;
use constant SERVER_QUERY_NO_GOOD_INDEX_USED    => 16;
use constant SERVER_QUERY_NO_INDEX_USED         => 32;
use constant SERVER_STATUS_CURSOR_EXISTS        => 64;
use constant SERVER_STATUS_LAST_ROW_SENT        => 128;
use constant SERVER_STATUS_DB_DROPPED           => 256;
use constant SERVER_STATUS_NO_BACKSLASH_ESCAPES => 512;

use constant COM_SLEEP                  => 0;
use constant COM_QUIT                   => 1;
use constant COM_INIT_DB                => 2;
use constant COM_QUERY                  => 3;
use constant COM_FIELD_LIST             => 4;
use constant COM_CREATE_DB              => 5;
use constant COM_DROP_DB                => 6;
use constant COM_REFRESH                => 7;
use constant COM_SHUTDOWN               => 8;
use constant COM_STATISTICS             => 9;
use constant COM_PROCESS_INFO           => 10;
use constant COM_CONNECT                => 11;
use constant COM_PROCESS_KILL           => 12;
use constant COM_DEBUG                  => 13;
use constant COM_PING                   => 14;
use constant COM_TIME                   => 15;
use constant COM_DELAYED_INSERT         => 16;
use constant COM_CHANGE_USER            => 17;
use constant COM_BINLOG_DUMP            => 18;
use constant COM_TABLE_DUMP             => 19;
use constant COM_CONNECT_OUT            => 20;
use constant COM_REGISTER_SLAVE         => 21;
use constant COM_STMT_PREPARE           => 22;
use constant COM_STMT_EXECUTE           => 23;
use constant COM_STMT_SEND_LONG_DATA    => 24;
use constant COM_STMT_CLOSE             => 25;
use constant COM_STMT_RESET             => 26;
use constant COM_SET_OPTION             => 27;
use constant COM_STMT_FETCH             => 28;
use constant COM_END                    => 29;

use constant MYSQL_TYPE_DECIMAL     => 0;
use constant MYSQL_TYPE_TINY        => 1;
use constant MYSQL_TYPE_SHORT       => 2;
use constant MYSQL_TYPE_LONG        => 3;
use constant MYSQL_TYPE_FLOAT       => 4;
use constant MYSQL_TYPE_DOUBLE      => 5;
use constant MYSQL_TYPE_NULL        => 6;
use constant MYSQL_TYPE_TIMESTAMP   => 7;
use constant MYSQL_TYPE_LONGLONG    => 8;
use constant MYSQL_TYPE_INT24       => 9;
use constant MYSQL_TYPE_DATE        => 10;
use constant MYSQL_TYPE_TIME        => 11;
use constant MYSQL_TYPE_DATETIME    => 12;
use constant MYSQL_TYPE_YEAR        => 13;
use constant MYSQL_TYPE_NEWDATE     => 14;
use constant MYSQL_TYPE_VARCHAR     => 15;
use constant MYSQL_TYPE_BIT         => 16;
use constant MYSQL_TYPE_NEWDECIMAL  => 246;
use constant MYSQL_TYPE_ENUM        => 247;
use constant MYSQL_TYPE_SET         => 248;
use constant MYSQL_TYPE_TINY_BLOB	=> 249;
use constant MYSQL_TYPE_MEDIUM_BLOB => 250;
use constant MYSQL_TYPE_LONG_BLOB   => 251;
use constant MYSQL_TYPE_BLOB        => 252;
use constant MYSQL_TYPE_VAR_STRING  => 253;
use constant MYSQL_TYPE_STRING      => 254;
use constant MYSQL_TYPE_GEOMETRY    => 255;

use constant NOT_NULL_FLAG          => 1;
use constant PRI_KEY_FLAG           => 2;
use constant UNIQUE_KEY_FLAG        => 4;
use constant MULTIPLE_KEY_FLAG      => 8;
use constant BLOB_FLAG              => 16;
use constant UNSIGNED_FLAG          => 32;
use constant ZEROFILL_FLAG          => 64;
use constant BINARY_FLAG            => 128;
use constant ENUM_FLAG              => 256;
use constant AUTO_INCREMENT_FLAG    => 512;
use constant TIMESTAMP_FLAG         => 1024;
use constant SET_FLAG               => 2048;
use constant NO_DEFAULT_VALUE_FLAG  => 4096;
use constant NUM_FLAG               => 32768;


sub BUILD {
   my ($self) = @_;


   
}

sub _authenticate {
   my ($self, $data) = @_;
   
   my $database;
   
   my $ptr = 0;
   my $header_flags = substr($data, $ptr, 4);
   $ptr = $ptr + 4;
   
   eval {
      my $client_flags = substr($data, $ptr, 4);
      $ptr = $ptr + 4;
      
      my $max_packet_size = substr($data, $ptr, 4);
      $ptr = $ptr + 4;
      
      my $charset_number = substr($data, $ptr, 1);
      $self->charset(ord($charset_number));
      $ptr++;
      
      my $filler1 = substr($data, $ptr, 23);
      $ptr = $ptr + 23;
      
      my $username_end = index($data, "\0", $ptr);
      my $username = substr($data, $ptr, $username_end - $ptr);
      $ptr = $username_end + 1;
      
      my $scramble_buff;
      
      my $scramble_length = ord(substr($data, $ptr, 1));
      $ptr++;
      
      if ($scramble_length > 0) {
         $self->scramble(substr($data, $ptr, $scramble_length));
         $ptr = $ptr + $scramble_length;
      }
      
      my $database_end = index( $data, "\0", $ptr);
      if ($database_end != -1 ) {
         $database = substr($data, $ptr, $database_end - $ptr);
      }
      
      $self->database($database);
      $self->username($username);
   
   };
    
   if ($@) {
      print $@;
   }
    

   if ($database) {
      $self->database($database);
   }
   else {
      $self->database('mysql');
   }

  $self->authenticated(1);
  $self->send_ok;

}


sub send_error {
   my ($self, $message, $errno, $sqlstate) = @_;
   
   $message = 'Unknown MySQL error' if not defined $message;
   $errno = 2000 if not defined $errno;
   $sqlstate = 'HY000' if not defined $sqlstate;
   
   my $payload = chr(0xff);
   $payload .= pack('v', $errno);
   $payload .= '#';
   $payload .= $sqlstate;
   $payload .= $message."\0";
   
   $self->_write_to_client( $payload, 1);
}

sub client_input {
   my ( $kernel, $session, $heap, $self ) = @_[ KERNEL, SESSION, HEAP, OBJECT];
   my $data = $_[ARG0];
   
#   print "client_input $data on $$ \n";
   
   unless ($self->local_dbh) {
      
      unless ($self->local_dsn) {
         $self->send_error('No local_dsn');
         return;
      }
      
      $self->local_dbh(
         DBI->connect($self->local_dsn, $self->local_user, $self->local_password)
      );
      
   }

   
   if (length($data) > 1) {
      $self->packet_count($self->packet_count + 1);
   }
   else {
      return;
   }

   unless ( $self->authenticated) {
      $self->_authenticate($data);
	}
	else {
      my $header_flags = substr($data, 0, 4);      
      my $command = unpack('C', substr($data, 3, 1));
      
      $data = substr($data, 4);
      
      if ($command == COM_INIT_DB) {
         $data = 'USE '.$data;
      }
      
      unless (length($data)) {
         $self->send_ok;
         return;
      }
      
      my $event;
      my @placeholders;
      
      foreach my $dispatcher (@{$self->dispatchers}) {
         if (ref($dispatcher->{regexp}) eq 'Regexp') {
            if (@placeholders = $data =~ $dispatcher->{regexp}) {
               $event = $dispatcher->{method};
               last;
            }
         }
         elsif (exists($dispatcher->{match})) {
            if ($data eq $dispatcher->{match}) {
               $event = $dispatcher->{method};
               last;
            }
         }
      }   
      
      
      unless ($event) {
         $event = $self->default->{method} if $self->default;
      }
      
      unless ($event) {
         $event = 'relay';
      }   

#      print '$event = '.$event." \n";

      if ($event) {
         $self->$event($data, @placeholders);
      }
      else {
         $self->send_error;
      }
      
#      POE::Kernel->post(
#         $self->session_id,
#         $event,
#         $data
#      );

   }
}


sub relay {
   my ($self, $query) = @_;
   
   $self->local_dbh->{'mysql_use_result'} = 1;
   
   if ($query =~ qr{use `(.*)`}io) {
      $self->database($1);
   }
   
   my $err;
   
   my $sth = $self->local_dbh->prepare($query);
   if ($DBI::err) {
      $err = $DBI::errstr;
   }

   my $affected_rows = $sth->execute;
   if ($DBI::err) {
      $err = $DBI::errstr;
   }
	
	if (defined $err) {
		$self->send_error($err);
	} 
	elsif ((not defined $sth->{NUM_OF_FIELDS}) || ($sth->{NUM_OF_FIELDS} == 0)) {
		$self->send_ok($self->local_dbh->{'mysql_info'}, $affected_rows, $sth->{mysql_insertid}, $sth->{'mysql_warning_count'});
	} 
	else {

      unless ($self->type_info) {
  
         my $infos = ();
   
         my @type_info = @{$self->local_dbh->type_info_all()};
            
   		my $sql_col = $type_info[0]->{DATA_TYPE};
   		my $mysql_col = $type_info[0]->{mysql_native_type};
   
   		foreach my $type (@type_info[1..$#type_info]) {
   			my $sql_value = $type->[$sql_col];
   			my $mysql_value = $type->[$mysql_col];
   	
   			$infos->{$sql_value} = $mysql_value if exists $infos->{$sql_value};
   		}
   		
   		$self->type_info($infos);
   		
      }
      

		my @definitions = map {
			my $flags = 0;
			$flags = $flags | NOT_NULL_FLAG        if not $sth->{NULLABLE}->[$_];
			$flags = $flags | BLOB_FLAG            if $sth->{mysql_is_blob}->[$_];
			$flags = $flags | UNIQUE_KEY_FLAG      if $sth->{mysql_is_key}->[$_];
			$flags = $flags | PRI_KEY_FLAG         if $sth->{mysql_is_pri_key}->[$_];
			$flags = $flags | AUTO_INCREMENT_FLAG  if $sth->{mysql_is_auto_increment}->[$_];

         my $type = $self->type_info->{$sth->{TYPE}->[$_]};

         my $def_length = $sth->{mysql_length}->[$_];
         
			$self->definition({
				name     => $sth->{NAME}->[$_],
				type     => $type,
				length   => $def_length,
				flags    => $flags
			});
		} (0..$sth->{NUM_OF_FIELDS}-1);


      my @result = @{ $sth->fetchall_arrayref() };
      $affected_rows = scalar(@result);

      $self->_send_header_packet($sth->{NUM_OF_FIELDS}, $affected_rows);
      $self->_send_definitions(\@definitions);
      $self->_send_eof;
      
      my @rows;
      my $i = 1;
      foreach my $row_ref (@result) {
         my @row = @{$row_ref};
   	      	   
   	   $rows[$i] = ();
   	   @{ $rows[$i] } = @row;
   	   
   		if ($i == 10000) {
   		   $self->_send_rows(\@rows, {
   		      chunked => 1,
   		   });
   		   @rows = undef;
   		   $i = 1;
   		}
   		else {
      		$i++;
      	}
   	}
   	
      $self->_send_rows(\@rows);
      $self->_send_eof(undef,undef,1);

	}
	
	$self->local_dbh->{'mysql_use_result'} = 0;
}

sub _send_definitions {
   my ($self, $definitions, $skip_envelope) = @_;

	my $last_send_result;
	
   foreach my $definition (@{$definitions}) {
      $definition = $self->definition({ name => $definition })
         unless ref($definition) eq 'POE::Component::Server::MySQL::Definition';
      $self->_send_definition($definition);
   }

}

sub _send_definition {
   my ($self, $definition) = @_;
   
	my (
      $field_catalog, $field_db, $field_table,
      $field_org_table, $field_name, $field_org_name,
      $field_length, $field_type, $field_flags,
      $field_decimals, $field_default
	) = (
		$definition->[FIELD_CATALOG], $definition->[FIELD_DB],
		$definition->[FIELD_TABLE], $definition->[FIELD_ORG_TABLE],
		$definition->[FIELD_NAME], $definition->[FIELD_ORG_NAME],
		$definition->[FIELD_LENGTH], $definition->[FIELD_TYPE],
		$definition->[FIELD_FLAGS], $definition->[FIELD_DECIMALS],
		$definition->[FIELD_DEFAULT]
	);

	my $payload = join('', map { $self->_length_coded_string($_) } (
		$field_catalog, 
		$field_db, 
		$field_table,
		$field_org_table, 
		$field_name, 
		$field_org_name
	));
   
   $payload .= chr(0x0c);
   $payload .= pack('v', 11);
   $payload .= pack('V', $field_length);
   $payload .= chr($field_type);
   $payload .= defined $field_flags ? pack('v', $field_flags) : pack('v', 0);
   $payload .= defined $field_decimals ? chr($field_decimals) : pack('v', 0);
   $payload .= pack('v', 0);

   $self->_write_to_client($payload);
}

sub _send_eof {
    my ($self, $warning_count, $server_status, $reinit) = @_;

	my $payload;

	$server_status =  SERVER_STATUS_AUTOCOMMIT |
	                  SERVER_QUERY_NO_INDEX_USED if not defined $server_status;

   $warning_count = 0 if !defined $warning_count;

	$payload .= chr(0xfe);
	$payload .= pack('v', $warning_count) if defined $warning_count;
	$payload .= pack('v', $server_status) if defined $server_status;

   $self->_write_to_client($payload, $reinit);
}

sub send_ok {
   my ($self, $message, $affected_rows, $insert_id, $printing_count) = @_;
   
   my $data;
   
   $affected_rows = 0 if not defined $affected_rows;
   $printing_count = 0 if not defined $printing_count;
   
   $data .= "\0";
   $data .= $self->_length_coded_binary($affected_rows);
   $data .= $self->_length_coded_binary($insert_id);
   $data .= pack('v', SERVER_STATUS_AUTOCOMMIT);
   $data .= pack('v', $printing_count);
   $data .= $self->_length_coded_string($message);
   
   $self->_write_to_client( $data, 1);
}


sub _add_header {
   my ($self, $message, $reinit) = @_;
   
   my $header;
   $header .= substr(pack('V',length($message)),0,3);
   $header .= chr($self->packet_count % 256);
   
   if ($reinit) {
      $self->packet_count(0);
   }
   else {
      $self->packet_count($self->packet_count + 1);
   }
   
   return $header.$message;
}

sub _write_to_client {
   my ($self, $message, $reinit) = @_;
      
   $message = $self->_add_header($message, $reinit);
   $self->wheel->put($message);

}




sub _length_coded_string {
	my ($self, $string) = @_;
	return chr(0) if (not defined $string or $string eq '');
	return $self->_length_coded_binary(length($string)).$string;
}

sub _length_coded_binary {
	my ($self, $number) = @_;
	
	if (not defined $number) {
		return chr(251);
	}
    elsif ($number < 251) {
		return chr($number);
	}
    elsif ($number < 0x10000) {
		return chr(252).pack('v', $number);
	}
    elsif ($number < 0x1000000) {
		return chr(253).substr(pack('V', $number), 0, 3);
	}
    else {
		return chr(254).pack('V', $number >> 32).pack('V', $number & 0xffffffff);
	}
}

sub shutdown { 
   
}

sub client_error {
   my ($self) = shift;
   my ($kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP];
   my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];

}

sub client_connect {
   my ( $self, $kernel, $session, $heap ) = @_[OBJECT, KERNEL, SESSION, HEAP];
   
   $self->banner("5.1.40-log\0");
   $self->salt(join('',map { chr(int(rand(255))) } (1..20)));
   $self->charset(0x21);
   $self->tid($$);
   $self->packet_count(0);

#[root@daef-0004 mysqlsniffer]# clear ; ./mysqlsniffer --port 3306 --verbose --tcp-ctrl eth0
#mysqlsniffer listening for MySQL on interface eth0 port 3306
#129.195.12.105.2908 > server: SYN
#server > 129.195.12.105.2908: SYN ACK
#129.195.12.105.2908 > server: ACK
#server > 129.195.12.105.2908: ID 0 len 56 Handshake <proto 10 ver 5.1.40-log thd 514> (Caps: Long password, Found rows, Get all column flags, Connect w/DB, No schema, Compression, ODBC client, LOAD DATA LOCAL, )
#129.195.12.105.2908 > server: ID 1 len 58 Handshake (new auth) <user root db (null) max pkt 16777216> (Caps: Long password, Get all column flags, LOAD DATA LOCAL, 4.1 protocol, Interactive, Transactions, 4.1 authentication, Multi-statements, Multi-results)
#server > 129.195.12.105.2908: ACK
#server > 129.195.12.105.2908: ID 2 len 7 OK <fields 0 affected rows 0 insert id 0 warnings 0> (Status: Auto-commit, )
#129.195.12.105.2908 > server: ID 0 len 33 COM_QUERY: select @@version_comment limit 1
#server > 129.195.12.105.2908: ID 1 len 1 1 Fields
#        ID 2 len 39 Field: ..@@version_comment <type var string (253) size 48>
#        ID 3 len 5 End <warnings 0> (Status: Auto-commit, )
#        ID 4 len 49 || build number (revision)=IB_3.4.2_r8940_9191(ice) ||
#        ID 5 len 5 End <warnings 0> (Status: Auto-commit, )
#129.195.12.105.2908 > server: ACK


   
   my $payload = chr(10);
   $payload .= $self->banner;
   $payload .= pack('V', $self->tid);
   $payload .= substr($self->salt,0,8)."\0";
   $payload .= pack('v',   CLIENT_LONG_PASSWORD | 
                           CLIENT_CONNECT_WITH_DB | 
                           CLIENT_LONG_FLAG |
                           CLIENT_PROTOCOL_41 | 
                           CLIENT_FOUND_ROWS |
                           CLIENT_NO_SCHEMA  |
                           CLIENT_MULTI_RESULTS |
                           CLIENT_ODBC |
                           CLIENT_LOCAL_FILES |
                           CLIENT_INTERACTIVE |
                           CLIENT_TRANSACTIONS |
                           CLIENT_SECURE_CONNECTION);
   $payload .= $self->charset;
   $payload .= pack('v', SERVER_STATUS_AUTOCOMMIT);
   $payload .= "\0" x 13;
   $payload .= substr($self->salt,8)."\0";
   
   $self->_write_to_client($payload);
}

sub client_disconnect {
   my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP];
   
   print "handle_client_disconnect"."\n";
}

sub _send_header_packet {
   my ($self, $n_fields, $n_rows) = @_;

#   print '$n_fields = '.$n_fields."\n";

   my $packet = $self->_length_coded_binary($n_fields);
#   $packet .= $self->_length_coded_binary($n_rows);

   $self->_write_to_client($packet);   
}

sub _send_rows {
   my ($self, $rows, $opt) = @_;
#   $self->_send_eof if not defined $rows;

	foreach my $row (@$rows) {

        my $small_data;
        if (ref($row) eq 'ARRAY') {
            foreach (@$row) {
                if (not defined $_) {
                    $small_data .= chr(251);
                }
                else {
                    $small_data .= $self->_length_coded_string($_);
                }
            }
        }
        elsif (ref($row) eq 'HASH') {
            foreach (values %{ $row }) {
                if (not defined $_) {
                    $small_data .= chr(251);
                }
                else {
                    $small_data .= $self->_length_coded_string($_);
                }
            }
        }

        if (defined $small_data) {
            $self->_write_to_client($small_data);
        }
	}

#   $self->_send_eof unless $opt->{chunked};
}

sub send_results {
   my ($self, $definitions, $data, $opt) = @_;

   unless (ref($data) eq 'ARRAY') {
      $self->send_error('Internal error .. F**K !');
      return;
   }
   
   $self->_send_header_packet(scalar(@{$data}), $opt);
   $self->_send_definitions($definitions, $opt);
   $self->_send_eof;
   $self->_send_rows($data, $opt);
   $self->_send_eof(undef,undef,1);
}

sub definition {
	my ($self, $params) = @_;
#
#System.IndexOutOfRangeException
#Index was outside the bounds of the array.
#Stack Trace:
#   at Quest.FastData.FastRow.get_Item(Int32 column)
#   at Quest.Toad.MySQL.Trl.ColumnListTrl.CreateChildTrl(ITrl parent, FastRow row)
   
   no strict 'refs';
   my $definition = bless([], 'POE::Component::Server::MySQL::Definition');
   $definition->[FIELD_CATALOG]     = $params->{catalog} ? $params->{catalog} : 'def';
   $definition->[FIELD_DB]          = $params->{db} ? $params->{db} : '';
   $definition->[FIELD_TABLE]       = $params->{table} ? $params->{table} : 'COLUMNS';
   $definition->[FIELD_ORG_TABLE]   = $params->{org_table};
   $definition->[FIELD_NAME]        = $params->{name};
   $definition->[FIELD_ORG_NAME]    = $params->{org_name} ? $params->{table} : 'COLUMN_NAME';
   $definition->[FIELD_LENGTH]      = defined $params->{length} ? $params->{length} : 0;
   $definition->[FIELD_TYPE]        = defined $params->{type} ? $params->{type} : MYSQL_TYPE_STRING;
   $definition->[FIELD_FLAGS]       = defined $params->{flags} ? $params->{flags} : 0;
   $definition->[FIELD_DECIMALS]    = $params->{decimals};
   $definition->[FIELD_DEFAULT]     = $params->{default};
   return $definition;
}

1;
