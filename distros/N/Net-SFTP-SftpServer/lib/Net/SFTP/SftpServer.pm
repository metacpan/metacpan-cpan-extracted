#/*
# * Based on sftp-server.c
# * Copyright (c) 2000-2004 Markus Friedl.  All rights reserved.
# *
# * Ported to Perl and extended by Simon Day
# * Copyright (c) 2009 Pirum Systems Ltd.  All rights reserved.
# *
# * Permission to use, copy, modify, and distribute this software for any
# * purpose with or without fee is hereby granted, provided that the above
# * copyright notice and this permission notice appear in all copies.
# *
# * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# */
#
package Net::SFTP::SftpServer;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
    ALL
    NET_SFTP_SYMLINKS
    NET_SFTP_RENAME_DIR
    SSH2_FXP_INIT
    SSH2_FXP_OPEN
    SSH2_FXP_CLOSE
    SSH2_FXP_READ
    SSH2_FXP_WRITE
    SSH2_FXP_LSTAT
    SSH2_FXP_STAT_VERSION_0
    SSH2_FXP_FSTAT
    SSH2_FXP_SETSTAT
    SSH2_FXP_FSETSTAT
    SSH2_FXP_OPENDIR
    SSH2_FXP_READDIR
    SSH2_FXP_REMOVE
    SSH2_FXP_MKDIR
    SSH2_FXP_RMDIR
    SSH2_FXP_REALPATH
    SSH2_FXP_STAT
    SSH2_FXP_RENAME
    SSH2_FXP_READLINK
    SSH2_FXP_SYMLINK
    logError
    logWarning
    logGeneral
    logDetail
);


%EXPORT_TAGS = (  ACTIONS => [ qw(
                              ALL
                              NET_SFTP_SYMLINKS
                              NET_SFTP_RENAME_DIR
                              SSH2_FXP_OPEN
                              SSH2_FXP_CLOSE
                              SSH2_FXP_READ
                              SSH2_FXP_WRITE
                              SSH2_FXP_LSTAT
                              SSH2_FXP_STAT_VERSION_0
                              SSH2_FXP_FSTAT
                              SSH2_FXP_SETSTAT
                              SSH2_FXP_FSETSTAT
                              SSH2_FXP_OPENDIR
                              SSH2_FXP_READDIR
                              SSH2_FXP_REMOVE
                              SSH2_FXP_MKDIR
                              SSH2_FXP_RMDIR
                              SSH2_FXP_STAT
                              SSH2_FXP_RENAME
                              SSH2_FXP_READLINK
                              SSH2_FXP_SYMLINK
                            ) ],
                  LOG  => [qw(
                              logError
                              logWarning
                              logGeneral
                              logDetail
                           )]);

use strict;
use warnings;

use version; our $VERSION = qv('1.1.0');

use Stat::lsMode;
use Fcntl qw( O_RDWR O_CREAT O_TRUNC O_EXCL O_RDONLY O_WRONLY SEEK_SET );
use POSIX qw(strftime);
use Sys::Syslog;

$SIG{__DIE__} = sub {  ## still dies upon return
		syslog 'warning', join(" : ", @_);
};

use Errno qw(:POSIX);

use constant TIMEOUT                        => 300;
use constant MAX_PACKET_SIZE                => 1024 * 1024;
use constant MAX_OPEN_HANDLES               => 512;

#/* version */
use constant SSH2_FILEXFER_VERSION          => 3;

#/* client to server */
use constant SSH2_FXP_INIT                  => 1;
use constant SSH2_FXP_OPEN                  => 3;
use constant SSH2_FXP_CLOSE                 => 4;
use constant SSH2_FXP_READ                  => 5;
use constant SSH2_FXP_WRITE                 => 6;
use constant SSH2_FXP_LSTAT                 => 7;
use constant SSH2_FXP_STAT_VERSION_0        => 7;
use constant SSH2_FXP_FSTAT                 => 8;
use constant SSH2_FXP_SETSTAT               => 9;
use constant SSH2_FXP_FSETSTAT              => 10;
use constant SSH2_FXP_OPENDIR               => 11;
use constant SSH2_FXP_READDIR               => 12;
use constant SSH2_FXP_REMOVE                => 13;
use constant SSH2_FXP_MKDIR                 => 14;
use constant SSH2_FXP_RMDIR                 => 15;
use constant SSH2_FXP_REALPATH              => 16;
use constant SSH2_FXP_STAT                  => 17;
use constant SSH2_FXP_RENAME                => 18;
use constant SSH2_FXP_READLINK              => 19;
use constant SSH2_FXP_SYMLINK               => 20;

# SFTP allow/deny actions

use constant ALL                            => 1000;
use constant NET_SFTP_RENAME_DIR            => 1001;
use constant NET_SFTP_SYMLINKS              => 1002;

#/* server to client */
use constant SSH2_FXP_VERSION               => 2;
use constant SSH2_FXP_STATUS                => 101;
use constant SSH2_FXP_HANDLE                => 102;
use constant SSH2_FXP_DATA                  => 103;
use constant SSH2_FXP_NAME                  => 104;
use constant SSH2_FXP_ATTRS                 => 105;

use constant SSH2_FXP_EXTENDED              => 200;
use constant SSH2_FXP_EXTENDED_REPLY        => 201;

#/* attributes */
use constant SSH2_FILEXFER_ATTR_SIZE        => 0x00000001;
use constant SSH2_FILEXFER_ATTR_UIDGID      => 0x00000002;
use constant SSH2_FILEXFER_ATTR_PERMISSIONS => 0x00000004;
use constant SSH2_FILEXFER_ATTR_ACMODTIME   => 0x00000008;
use constant SSH2_FILEXFER_ATTR_EXTENDED    => 0x80000000;

#/* portable open modes */
use constant SSH2_FXF_READ                  => 0x00000001;
use constant SSH2_FXF_WRITE                 => 0x00000002;
use constant SSH2_FXF_APPEND                => 0x00000004;
use constant SSH2_FXF_CREAT                 => 0x00000008;
use constant SSH2_FXF_TRUNC                 => 0x00000010;
use constant SSH2_FXF_EXCL                  => 0x00000020;

#/* status messages */
use constant SSH2_FX_OK                     => 0;
use constant SSH2_FX_EOF                    => 1;
use constant SSH2_FX_NO_SUCH_FILE           => 2;
use constant SSH2_FX_PERMISSION_DENIED      => 3;
use constant SSH2_FX_FAILURE                => 4;
use constant SSH2_FX_BAD_MESSAGE            => 5;
use constant SSH2_FX_NO_CONNECTION          => 6;
use constant SSH2_FX_CONNECTION_LOST        => 7;
use constant SSH2_FX_OP_UNSUPPORTED         => 8;
use constant SSH2_FX_MAX                    => 8;#8 is the highest that is available

use constant MESSAGE_HANDLER => {
    SSH2_FXP_INIT()        => 'processInit',
    SSH2_FXP_OPEN()        => 'processOpen',
    SSH2_FXP_CLOSE()       => 'processClose',
    SSH2_FXP_READ()        => 'processRead',
    SSH2_FXP_WRITE()       => 'processWrite',
    SSH2_FXP_LSTAT()       => 'processLstat',
    SSH2_FXP_FSTAT()       => 'processFstat',
    SSH2_FXP_SETSTAT()     => 'processSetstat',
    SSH2_FXP_FSETSTAT()    => 'processFsetstat',
    SSH2_FXP_OPENDIR()     => 'processOpendir',
    SSH2_FXP_READDIR()     => 'processReaddir',
    SSH2_FXP_REMOVE()      => 'processRemove',
    SSH2_FXP_MKDIR()       => 'processMkdir',
    SSH2_FXP_RMDIR()       => 'processRmdir',
    SSH2_FXP_REALPATH()    => 'processRealpath',
    SSH2_FXP_STAT()        => 'processStat',
    SSH2_FXP_RENAME()      => 'processRename',
    SSH2_FXP_READLINK()    => 'processReadlink',
    SSH2_FXP_SYMLINK()     => 'processSymlink',
    SSH2_FXP_EXTENDED()    => 'processExtended',
};

use constant MESSAGE_TYPES => {
    SSH2_FXP_INIT()        => 'SSH2_FXP_INIT',
    SSH2_FXP_OPEN()        => 'SSH2_FXP_OPEN',
    SSH2_FXP_CLOSE()       => 'SSH2_FXP_CLOSE',
    SSH2_FXP_READ()        => 'SSH2_FXP_READ',
    SSH2_FXP_WRITE()       => 'SSH2_FXP_WRITE',
    SSH2_FXP_LSTAT()       => 'SSH2_FXP_LSTAT',
    SSH2_FXP_FSTAT()       => 'SSH2_FXP_FSTAT',
    SSH2_FXP_SETSTAT()     => 'SSH2_FXP_SETSTAT',
    SSH2_FXP_FSETSTAT()    => 'SSH2_FXP_FSETSTAT',
    SSH2_FXP_OPENDIR()     => 'SSH2_FXP_OPENDIR',
    SSH2_FXP_READDIR()     => 'SSH2_FXP_READDIR',
    SSH2_FXP_REMOVE()      => 'SSH2_FXP_REMOVE',
    SSH2_FXP_MKDIR()       => 'SSH2_FXP_MKDIR',
    SSH2_FXP_RMDIR()       => 'SSH2_FXP_RMDIR',
    SSH2_FXP_REALPATH()    => 'SSH2_FXP_REALPATH',
    SSH2_FXP_STAT()        => 'SSH2_FXP_STAT',
    SSH2_FXP_RENAME()      => 'SSH2_FXP_RENAME',
    SSH2_FXP_READLINK()    => 'SSH2_FXP_READLINK',
    SSH2_FXP_SYMLINK()     => 'SSH2_FXP_SYMLINK',
    SSH2_FXP_EXTENDED()    => 'SSH2_FXP_EXTENDED',
    ALL()                  => 'ALL',
    NET_SFTP_SYMLINKS()    => 'NET_SFTP_SYMLINKS',
    NET_SFTP_RENAME_DIR()  => 'NET_SFTP_RENAME_DIR',
};

use constant ACTIONS => [
                              ALL,
                              NET_SFTP_SYMLINKS,
                              NET_SFTP_RENAME_DIR,
                              SSH2_FXP_OPEN,
                              SSH2_FXP_CLOSE,
                              SSH2_FXP_READ,
                              SSH2_FXP_WRITE,
                              SSH2_FXP_LSTAT,
                              SSH2_FXP_STAT_VERSION_0,
                              SSH2_FXP_FSTAT,
                              SSH2_FXP_SETSTAT,
                              SSH2_FXP_FSETSTAT,
                              SSH2_FXP_OPENDIR,
                              SSH2_FXP_READDIR,
                              SSH2_FXP_REMOVE,
                              SSH2_FXP_MKDIR,
                              SSH2_FXP_RMDIR,
                              SSH2_FXP_STAT,
                              SSH2_FXP_RENAME,
                              SSH2_FXP_READLINK,
                              SSH2_FXP_SYMLINK,
                            ];

use constant STATUS_MESSAGE => [
  "Success",                #/* SSH2_FX_OK */
  "End of file",            #/* SSH2_FX_EOF */
  "No such file",           #/* SSH2_FX_NO_SUCH_FILE */
  "Permission denied",      #/* SSH2_FX_PERMISSION_DENIED */
  "Failure",                #/* SSH2_FX_FAILURE */
  "Bad message",            #/* SSH2_FX_BAD_MESSAGE */
  "No connection",          #/* SSH2_FX_NO_CONNECTION */
  "Connection lost",        #/* SSH2_FX_CONNECTION_LOST */
  "Operation unsupported",  #/* SSH2_FX_OP_UNSUPPORTED */
  "Unknown error"            #/* Others */
];

my $USER = getpwuid($>);
my $ESCALATE_DEBUG = 0;
# --------------------------------------------------------------------
# Do evilness with symbol tables to ge
sub import{
  my $self = shift;
  my $opt = {};
  if (ref $_[0] eq 'HASH'){
    $opt = shift;
  }
  $opt->{log} ||= 'daemon';
  initLog($opt->{log});

  __PACKAGE__->export_to_level(1, $self, @_ ); # Call Exporter.
}
#-------------------------------------------------------------------------------
sub logItem {
  my ($level, $prefix, @msg) = @_;
  syslog $level, "[$USER]: $prefix" . join(" : ", @msg);
}
#-------------------------------------------------------------------------------
sub logDetail {
  logItem( $ESCALATE_DEBUG ? 'info' : 'debug', '', @_);
}
#-------------------------------------------------------------------------------
sub logGeneral {
  logItem('info', '', @_);
}
#-------------------------------------------------------------------------------
sub logWarning {
  logItem('warning', 'WARNING: ', @_);
}
#-------------------------------------------------------------------------------
sub logError {
  logItem('err', 'ERROR: ', @_);
}
#-------------------------------------------------------------------------------
sub initLog {
  my $syslog = shift;
  openlog( 'sftp', 'pid', $syslog);
  my ($remote_ip, $remote_port, $local_ip, $local_port) = split(' ', $ENV{SSH_CONNECTION});
  logGeneral "Client connected from $remote_ip:$remote_port";
  logDetail "Client connected to   $local_ip:$local_port";
}
#-------------------------------------------------------------------------------
sub getLogMsg {
  my $self = shift;
  my %arg = @_;

  my $req = $self->{_payload}->getPayloadContent();

  my $process = MESSAGE_TYPES->{$req->{message_type}};

  if ($req->{handle}){
    $req->{name} =  $self->{_payload}->getFilename() ;
  }

  my $msg = '';
  if (defined $arg{response} and $arg{response}->getType() == SSH2_FXP_STATUS ){
    $msg = 'response: ' . STATUS_MESSAGE->[$arg{response}->getStatus()] . ' ';
  }

  $msg .= "process: $process";

  if ($req->{id}){
    $msg .= " id: $req->{id}";
  }

  if ($req->{name}){
    $msg .= " filename: $req->{name}";
  }

  for my $field( qw( source_name target_name off len pflags ) ){
    if (defined $req->{$field}){
      $msg .= " $field: $req->{$field}";
    }
  }

  if ($req->{attr}){
    for my $key (keys %{$req->{attr}}){
      $msg .= " attr-$key: $req->{attr}{$key}";
    }
  }

  return $msg;
}
#-------------------------------------------------------------------------------
sub logAction {
  my $self = shift;

  my $req = $self->{_payload}->getPayloadContent();

  my $msg = $self->getLogMsg();

  if ( $self->{log_action_supress}{ $req->{message_type} } ){
    logDetail $msg;
  }
  else {
    logGeneral $msg;
  }
}
#-------------------------------------------------------------------------------
sub logStatus {
  my $self = shift;
  my $response = shift;
  my $msg = $self->getLogMsg(response => $response);
  my $req = $self->{_payload}->getPayloadContent();

  if ( $response->getType() == SSH2_FXP_STATUS
      and ( $self->{log_all_status} or ( $response->getStatus() != SSH2_FX_OK and $response->getStatus() != SSH2_FX_EOF ) )){
    logGeneral $msg;
  }
  elsif ( $response->getType() == SSH2_FXP_DATA or $req->{message_type} == SSH2_FXP_WRITE ){
    # Do nothing - otherwise we spam the syslog with every read/write packet
  }
  else {
    logDetail $msg;
  }

}
#-------------------------------------------------------------------------------
sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  Stat::lsMode->novice(0); #disable warnings from this module

  $self->{client_version} = 3; # Just in case we have a bad client that doesn't init the connection properly, treat it as latest version

  my %arg = @_;
  if (defined $arg{debug}     ){ $ESCALATE_DEBUG     = $arg{debug}  };

  $self->{home} = $arg{home} || '/home';
  $self->{home} =~ s!/$!!; # strip trailing /
  if (defined $arg{file_perms}){ $self->{file_perms} = $arg{file_perms} };
  if (defined $arg{dir_perms} ){ $self->{dir_perms}  = $arg{dir_perms}  };

  $self->{home_dir} = "$self->{home}/$USER";
  $self->{FS} = Net::SFTP::SftpServer::FS->new();
  $self->{FS}->setChrootDir( $self->{home_dir} );
  unless ( -d $self->{home_dir} ){
    logWarning "No sftp folder $self->{home_dir} found for $USER";
    exit 1;
  }
  unless ( -o $self->{home_dir} ){
    logWarning "No $self->{home_dir} is not owned by $USER";
    exit 1;
  }

  if (defined $arg{on_file_sent}){
    $self->{on_file_sent} = $arg{on_file_sent};
  }
  if (defined $arg{on_file_received}){
    $self->{on_file_received} = $arg{on_file_received};
  }
  if (defined $arg{move_on_sent}){
    $self->{move_on_sent} = $arg{move_on_sent};
  }
  if (defined $arg{move_on_received}){
    $self->{move_on_received} = $arg{move_on_received};
  }

  $self->{use_tmp_upload} = (defined $arg{use_tmp_upload} and $arg{use_tmp_upload}) ? 1 : 0;

  $self->{max_file_size}  = (defined $arg{max_file_size}) ? $arg{max_file_size} : 0;

  $self->{valid_filename_char}  = (defined $arg{valid_filename_char} and ref $arg{valid_filename_char} eq 'ARRAY') ? quotemeta join ('', @{$arg{valid_filename_char}}) : '';


  if ( (defined $arg{deny} and $arg{deny} == ALL) or
       (defined $arg{allow} and $arg{allow} != ALL and not defined $arg{deny})
       ){
    $self->{deny} = { map { $_ => 1 } @{ACTIONS()} };
  }

  $arg{deny}  = (not defined $arg{deny})     ?  []         :
                (ref $arg{deny} eq 'ARRAY')  ? $arg{deny}  : [ $arg{deny} ];
  $arg{allow} = (not defined $arg{allow})    ?  []         :
                (ref $arg{allow} eq 'ARRAY') ? $arg{allow} : [ $arg{allow} ];

  for my $deny (@{$arg{deny}}){
    $self->{deny}{$deny} = 1;
  }
  for my $allow (@{$arg{allow}}){
    $self->{deny}{$allow} = 0;
  }

  # These have not been implemented yet
  $self->{deny}{SSH2_FXP_SETSTAT()}  = 1;
  $self->{deny}{SSH2_FXP_FSETSTAT()} = 1;
  $self->{deny}{SSH2_FXP_SYMLINK()}  = 1;
  $self->{deny}{SSH2_FXP_READLINK()} = 1;

  $self->{no_symlinks} = $self->{deny}{NET_SFTP_SYMLINKS()};
  if ($self->{no_symlinks}){
    # if denying symlinks then must deny these
    $self->{deny}{SSH2_FXP_SYMLINK()}  = 1;
    $self->{deny}{SSH2_FXP_READLINK()} = 1;
  }

  $arg{fake_ok} = (not defined $arg{fake_ok})    ?  []         :
                (ref $arg{fake_ok} eq 'ARRAY') ? $arg{fake_ok} : [ $arg{fake_ok} ];
  $self->{fake_ok} = { map {$_ => 1} @{$arg{fake_ok}} };

  $self->{handles} = {};
  $self->{handle_count} = 0;
  $self->{open_handle_count} = 0;

  # Logging levels

  $self->{log_action}  = { map { $_ => 1 } @{ $arg{log_action}  } };
  $self->{log_action_supress} = { map { $_ => 1 }
                          grep { not defined $self->{log_action}{$_} }
                          @{ $arg{log_action_supress} },
                            ( SSH2_FXP_READ,
                              SSH2_FXP_READDIR,
                              SSH2_FXP_WRITE,
                              SSH2_FXP_CLOSE,
                              SSH2_FXP_OPENDIR,
                              SSH2_FXP_STAT,
                              SSH2_FXP_FSTAT,
                              SSH2_FXP_LSTAT,
                              SSH2_FXP_REALPATH,
                               ) };

  $self->{log_all_status} = defined $arg{log_all_status} ? $arg{log_all_status} : 0;

  return $self;
}
#-------------------------------------------------------------------------------
sub run {
  my $self = shift;
  while (1) {
    #/* copy stdin to iqueue */
    # Read 4 byte length of message
    # read length = payload
    my $packet_length = unpack("N", $self->readData(4));
    if ($packet_length > MAX_PACKET_SIZE){
      logError "Packet length of $packet_length received - exiting";
      exit 1;
    }

    my $req;
    eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm TIMEOUT;
      $req = $self->readData( $packet_length );
      alarm 0;
    };
    if ($@) {
      logError "Connection timed out trying to read $packet_length bytes";
      exit 1;
    }

    my $payload       = Net::SFTP::SftpServer::Buffer->new( data => $req );
    $self->{_payload} = $payload; # Keep a copy on self for debug output
    #/* process requests from client */
    # note - all send data will be called from the handler for this message type
    $self->process($payload);
  }
}
#-------------------------------------------------------------------------------
sub readData {
  my $self = shift;
  my $len = shift;
  my $req = '';
  #logDetail "Going to read $len bytes";
  while (length $req < $len){
    my $buf;
    my $read_len = sysread( STDIN, $buf, $len - length $req );
    if ($read_len == 0) {
      logGeneral("Client disconnected");
      $self->closeHandlesOnExit();
      exit 0;
    }
    elsif ($read_len < 0) {
      logWarning("read error");
      $self->closeHandlesOnExit();
      exit 1;
    }
    else {
      $req .= $buf;
    }
  }
  return $req;
}
#-------------------------------------------------------------------------------
sub closeHandlesOnExit {
  my $self = shift;
  for my $fd (values %{$self->{handles}}){
    $fd->close();
    logWarning "Handle for " . $fd->getFilename() . " still open on client exit";
  }
}
#-------------------------------------------------------------------------------
sub sendMessage {
  my $self = shift;
  my $msg = shift;
  #/* copy stdin to iqueue */
  # calc 4 byte length of message
  # put on front of message
  # send to STDOUT
  my $l = length $msg;
  #logDetail "Going to send $l bytes";
  my $len = pack('N', $l);
  my $write_len = syswrite( STDOUT, $len . $msg );
  if ($write_len < 0){
    logWarning "Write Error $!";
    $self->closeHandlesOnExit();
    exit 1;
  }
}
#-------------------------------------------------------------------------------
sub getHandle {
  my $self = shift;
  my $payload = shift;
  my $type = shift || '';
  my $req = $payload->getPayloadContent();
  my $handle_no = $req->{handle};
  if (defined $self->{handles}{$handle_no} and ($type eq '' or $type eq $self->{handles}{$handle_no}->getType())){
    my $handle = $self->{handles}{$handle_no};
    $payload->setFilename( $handle->getFilename() );
    $payload->setFileType( $handle->getType()     );
    return $handle;
  }
  return;
}
#-------------------------------------------------------------------------------
sub deleteHandle {
  my $self = shift;
  my $handle_no = shift;

  if (defined $self->{handles}{$handle_no}){
    $self->{open_handle_count}--;
    delete $self->{handles}{$handle_no};
  }
}
#-------------------------------------------------------------------------------
sub addHandle {
  my $self = shift;
  my $new_handle = shift;
  $self->{handle_count}++;
  $self->{open_handle_count}++;
  if ($self->{open_handle_count} > MAX_OPEN_HANDLES){
    logWarning "Exceeding max handle count";
    return;
  }
  $self->{handles}{$self->{handle_count}} = $new_handle;
  return $self->{handle_count};
}
#-------------------------------------------------------------------------------
sub process {
  my $self = shift;
  my $payload = shift;

  my $req = $payload->getPayloadContent(
    message_type  => 'char',
  );

  my $response = Net::SFTP::SftpServer::Response->new();

  if ($req->{message_type} != SSH2_FXP_INIT){
    # Init does not have an id - it has a client version - handled in processInit
    $req = $payload->getPayloadContent(
      id            => 'int',
    );
    $response->setId( $req->{id} )
  }

  logDetail "Got message_type " . MESSAGE_TYPES->{$req->{message_type}};

  if (defined MESSAGE_HANDLER->{$req->{message_type}}){
    my $method = MESSAGE_HANDLER->{$req->{message_type}};
    $self->$method($payload, $response);
  }
  else {
    logWarning("Unknown message $req->{message_type}");
    $response->setStatus( SSH2_FX_BAD_MESSAGE );
  }
  logWarning "Data left in buffer" unless $payload->done(); # check buffer is empty or warn

  $self->sendResponse( $response );
}
#-------------------------------------------------------------------------------
sub sendResponse {
  my $self = shift;
  my $response = shift;

  $self->logStatus( $response );

  my $msg;
  my $type = $response->getType();

  if ($type == SSH2_FXP_STATUS){
    my $status = $response->getStatus();
    $msg = pack('CNN', SSH2_FXP_STATUS, $response->getId() || 0, $status);
    if ($self->{client_version} >= 3){
      $msg .= pack('N', length STATUS_MESSAGE->[$status]) . STATUS_MESSAGE->[$status] . pack('N', 0);
    }
  }
  elsif ($type == SSH2_FXP_HANDLE){
    my $handle = $response->getHandle();
    $msg = pack('CNN', SSH2_FXP_HANDLE, $response->getId(), length $handle) . $handle;
  }
  elsif ($type == SSH2_FXP_DATA){
    $msg = pack('CNN', SSH2_FXP_DATA, $response->getId(), $response->getDataLength() )  . $response->getData();
  }
  elsif ($type == SSH2_FXP_VERSION){
    $msg = pack('CN', SSH2_FXP_VERSION, $response->getVersion());
  }
  elsif ($type == SSH2_FXP_ATTRS){
    $msg = pack('CN', SSH2_FXP_ATTRS, $response->getId() ) . $self->encodeAttrib( $response->getAttrs() );
  }
  elsif ($type == SSH2_FXP_NAME){
    my $files = $response->getNames();
    $msg = pack('CNN', SSH2_FXP_NAME, $response->getId(), scalar @$files );
    for my $file (@$files) {
      $msg .= pack('N', length $file->{name})      . $file->{name};
      $msg .= pack('N', length $file->{long_name}) . $file->{long_name};
      $msg .= $self->encodeAttrib($file->{attrib});
    }
  }
  else {
    logError "Unhandled response type: $type";
    # Make sure we send something back
    $msg = pack('CNN', SSH2_FXP_STATUS, $response->getId() || 0, SSH2_FX_BAD_MESSAGE );
    if ($self->{client_version} >= 3){
      $msg .= pack('N', length STATUS_MESSAGE->[SSH2_FX_BAD_MESSAGE]) . STATUS_MESSAGE->[SSH2_FX_BAD_MESSAGE] . pack('N', 0);
    }
  }
  $self->sendMessage( $msg );
}
#-------------------------------------------------------------------------------
sub processInit {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent( client_version => 'int' );
  $self->{client_version} = $req->{client_version};
  logGeneral sprintf("Connection accepted, client version: %d", $self->{client_version});

  $response->setInitVersion( SSH2_FILEXFER_VERSION );
}
#-------------------------------------------------------------------------------
sub processOpen {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name    => 'string',
    pflags  => 'int',         #/* portable flags */
    attr    => 'attrib',
  );

  my $flags  = $self->flagsFromPortable($req->{pflags});
  my $perm = defined $self->{file_perms}                              ? $self->{file_perms}  :
             ($req->{attr}{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS)  ? $req->{attr}{perm}        : 0666;

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_OPEN, $response);

  my $filename = $self->makeSafeFileName($req->{name});

  if ((not defined $filename) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $filename ))){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }
  # is this an upload
  # We use a tmp file if:
  # We have specified use tmp upload
  # And we have asked to create the file
  # And we are opening for writing
  # And we have either said to truncate the file on opening, or the file does not exist or is empty
  my $use_temp = ($self->{use_tmp_upload}  and
                  $req->{pflags} & SSH2_FXF_CREAT and
                  $req->{pflags} & SSH2_FXF_WRITE and
                  ( $req->{pflags} & SSH2_FXF_TRUNC or $self->{FS}->ZeroSize( $filename ) ) )    ? 1 : 0;

  my $fd = Net::SFTP::SftpServer::File->new( $filename, $flags, $req->{perm}, $use_temp);
  if (not defined $fd) {
    $response->setStatus( $self->errnoToPortable($! + 0) );
  } else {
    my $handle = $self->addHandle($fd);
    if (defined $handle){
      $response->setHandle( $handle );
      logDetail "Opened handle $handle for file $filename";
    }
    else {
      $response->setStatus( SSH2_FX_FAILURE );
    }
  }
}
#-------------------------------------------------------------------------------
sub processClose {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    handle  => 'string',
  );

  $self->logAction();

  my $ret = -1;
  my $status;
  my $fd = $self->getHandle($payload);
  if (defined $fd){
    $ret = $fd->close();
    $response->setStatus( $ret ? SSH2_FX_OK : $self->errnoToPortable($fd->err()) );
    if( $fd->getType() eq 'file'){
      #log file transmission stats
      logGeneral $fd->getStats();
      if (defined $self->{move_on_sent} and $fd->wasSent()){
        $fd->moveToProcessed( %{$self->{move_on_sent}} );
      }
      elsif (defined $self->{move_on_received} and $fd->wasReceived()){
        $fd->moveToProcessed( %{$self->{move_on_received}} );
      }
      if (defined $self->{on_file_sent} and $fd->wasSent()){
        $fd->setCallback();
        eval { $self->{on_file_sent}($fd) };
        if ($@){
          logError "on_file_sent Handler died with $@";
        }
      }
      elsif (defined $self->{on_file_received} and $fd->wasReceived()){
        $fd->setCallback();
        eval { $self->{on_file_received}($fd) };
        if ($@){
          logError "on_file_received Handler died with $@";
        }
      }
    }
  }
  else {
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
  }

  $self->deleteHandle($req->{handle});
}
#-------------------------------------------------------------------------------
sub processRead {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    handle  => 'string',
    off     => 'int64',
    len     => 'int',
  );

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_READ, $response);

  my $fd = $self->getHandle($payload, 'file');
  if (defined $fd) {
    if ($fd->sysseek($req->{off}, SEEK_SET) < 0) {
      my $errno = $!+0;
      logWarning "processRead: seek failed $!";
      $response->setStatus( $self->errnoToPortable($errno) );
    } else {
      my $buf;
      my $ret = $fd->sysread( $buf, $req->{len} );
      if ($ret < 0) {
        $response->setStatus( $self->errnoToPortable($!+0) );
      }
      elsif ($ret == 0) {
        $response->setStatus( SSH2_FX_EOF );
      } else {
        $response->setData( $ret, $buf );
        $fd->readBytes( $ret ) if $fd->getReadBytes() eq $req->{off}; #Only log sequential reads
      }
    }
  }
  else {
    $response->setStatus( SSH2_FX_FAILURE );
  }
}
#-------------------------------------------------------------------------------
sub processWrite {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    handle  => 'string',
    off     => 'int64',
    data    => 'string',
  );

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_WRITE, $response);


  my $fd = $self->getHandle($payload, 'file');
  if (defined $fd) {
    if ($self->{max_file_size} and $req->{off} + length $req->{data} > $self->{max_file_size}){
      logError "Attempt to write greater than Max file size, offset: $req->{off}, data length:" .  length $req->{data} . " on file ". $fd->getFilename();
      $response->setStatus( SSH2_FX_PERMISSION_DENIED );
      return;
    }
    elsif ($self->{max_file_size} and $req->{off} + length $req->{data} > 0.75 * $self->{max_file_size}){
      logWarning "Writing greater than 75% of Max file size, offset: $req->{off}, data length:" .  length $req->{data} . " on file ". $fd->getFilename();
    }
    if ($fd->sysseek($req->{off}, SEEK_SET) < 0) {
      my $errno = $!+0;
      logWarning "processRead: seek failed $!";
      $response->setStatus( $self->errnoToPortable($errno) );
    } else {
      my $len = length $req->{data};
      my $ret = $fd->syswrite($req->{data}, $len);
      if ($ret < 0) {
        logWarning "process_write: write failed";
        $response->setStatus( $self->errnoToPrtable($!+0) );
      }
      elsif ($ret == $len) {
        $fd->wroteBytes( $ret ) if $fd->getWrittenBytes() eq $req->{off}; #Only log sequential writes;
        $response->setStatus( SSH2_FX_OK );
      } else {
        logGeneral("nothing at all written");
      }
    }
  }
}
#-------------------------------------------------------------------------------
sub processDoStat{
  my $self = shift;
  my $mode    = shift;
  my $payload = shift;
  my $response = shift;


  my $req = $payload->getPayloadContent(
    name    => 'string',
  );

  my $filename = $self->makeSafeFileName($req->{name});

  $self->logAction();
  return if $self->denyOperation(($mode ? SSH2_FXP_LSTAT : SSH2_FXP_STAT), $response);

  if ((not defined $filename) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $filename ))){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }
  my @st = $mode ? $self->{FS}->LStat($filename) : $self->{FS}->Stat($filename);
  if (scalar @st == 0) {
    $response->setStatus( $self->errnoToPortable($!+0) );
  }
  else {
    $response->setAttrs( $self->statToAttrib(@st) );
  }
}
#-------------------------------------------------------------------------------
sub processStat {
  my $self = shift;
  my $payload = shift;
  my $response = shift;
  $self->processDoStat(0, $payload, $response);
}
#-------------------------------------------------------------------------------
sub processLstat {
  my $self = shift;
  my $payload = shift;
  my $response = shift;
  $self->processDoStat(1, $payload, $response);
}
#-------------------------------------------------------------------------------
sub processFstat {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $status = SSH2_FX_FAILURE;

  my $req = $payload->getPayloadContent(
    handle  => 'string',
  );

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_FSTAT, $response);

  my $fd = $self->getHandle($payload);
  if (defined $fd) {
    my @st = stat($fd);
    if (scalar @st == 0) {
      $response->setStatus( $self->errnoToPortable($!+0) );
    } else {
      $response->setAttrs(  $self->statToAttrib(@st) );
    }
  }
  else {
    $response->setStatus( SSH2_FX_FAILURE );
  }
}
#-------------------------------------------------------------------------------
sub processSetstat {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  #We choose not to allow any setting of stats

  my $req = $payload->getPayloadContent(
    name    => 'string',
    attr    => 'attrib',
  );

  $self->logAction();

  my $filename = $self->makeSafeFileName($req->{name});

  if ((not defined $filename) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $filename ))){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  return if $self->denyOperation(SSH2_FXP_SETSTAT, $response);

  logError "processSetstat not implemented";
}
#-------------------------------------------------------------------------------
sub processFsetstat {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  #We choose not to allow any setting of stats

  my $req = $payload->getPayloadContent(
    handle  => 'string',
    attr    => 'attrib',
  );

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_FSETSTAT, $response);

  logError "processFsetstat not implemented";
}
#-------------------------------------------------------------------------------
sub processOpendir {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name    => 'string',
  );

  $self->logAction();

  my $pathname = $self->makeSafeFileName($req->{name});

  return if $self->denyOperation(SSH2_FXP_OPENDIR, $response);

  if ((not defined $pathname) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $pathname ))){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  my $dirp = Net::SFTP::SftpServer::Dir->new($pathname);
  if (!defined $dirp) {
    $response->setStatus( $self->errnoToPortable($!+0) );
  } else {
    my $handle = $self->addHandle($dirp);
    if (defined $handle){
      $response->setHandle( $handle );
    }
    else {
      $response->setStatus( SSH2_FX_FAILURE );
    }
  }
}
#-------------------------------------------------------------------------------
sub processReaddir {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    handle  => 'string',
  );

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_READDIR, $response);

  my $dirp = $self->getHandle($payload, 'dir');
  if (not defined $dirp) {
    $response->setStatus( SSH2_FX_FAILURE );
  }
  else {
    my $fullpath = $dirp->getPath();
    my $stats = [];
    my $count = 0;
    while (my $dp = $dirp->readdir()) {
      my $pathname = $fullpath . $dp;
      next if ( $self->{no_symlinks} and $self->{FS}->IsSymlink( $pathname ) ); # we only inform the user about files and directories
    my @st = $self->{FS}->LStat($pathname);
      next unless scalar @st;
      my $file = {};
      $file->{attrib} = $self->statToAttrib(@st);
      $file->{name} = $dp;
      $file->{long_name} = $self->lsFile($dp, \@st);
      $count++;
      push @{$stats}, $file;
      #/* send up to 100 entries in one message */
      #/* XXX check packet size instead */
      last if $count == 100;
    }
    if ($count > 0) {
      $response->setNames($stats);
    }
    else {
      $response->setStatus( SSH2_FX_EOF );
    }
  }
}
#-------------------------------------------------------------------------------
sub processRemove {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name    => 'string',
  );

  $self->logAction();

  my $filename = $self->makeSafeFileName($req->{name});

  logDetail sprintf("processRemove: remove id %u name %s", $req->{id}, $req->{name});

  return if $self->denyOperation(SSH2_FXP_REMOVE, $response);

  if ((not defined $filename) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $filename ))){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  my $ret = $self->{FS}->Unlink($filename);
  my $status = $ret ?  SSH2_FX_OK : $self->errnoToPortable($!+0);
  if ( $status == SSH2_FX_OK ){
    logGeneral "Removed $filename";
  }
  $response->setStatus( $status );
}
#-------------------------------------------------------------------------------
sub processMkdir {
  my $self = shift;
  my $payload = shift;
  my $response = shift;


  my $req = $payload->getPayloadContent(
    name    => 'string',
    attr    => 'attrib',
  );

  my $filename = $self->makeSafeFileName($req->{name});

  my $mode = defined $self->{dir_perms}                              ? $self->{dir_perms}        :
             ($req->{attr}{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS)  ? $req->{attr}{perm} & 0777 : 0777;

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_MKDIR, $response);

  if (not defined $filename){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  my $ret = $self->{FS}->Mkdir($filename, $mode);
  $response->setStatus( $ret ? SSH2_FX_OK : $self->errnoToPortable($!+0) );
}
#-------------------------------------------------------------------------------
sub processRmdir {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name    => 'string',
  );

  my $filename = $self->makeSafeFileName($req->{name});

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_RMDIR, $response);

  if (not defined $filename){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  my $ret = $self->{FS}->Rmdir($filename);
  $response->setStatus( $ret ? SSH2_FX_OK : $self->errnoToPortable($!+0) );
}
#-------------------------------------------------------------------------------
sub processRealpath {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name    => 'string',
  );

  $self->logAction();

  my $path     = $self->makeSafeFileName($req->{name});

  logDetail sprintf("processRealpath: realpath id %u path %s", $req->{id}, $req->{name});

  my $file = { name => $path, long_name => $path, attrib => { flags => 0 } };

  $response->setNames( $file );
}
#-------------------------------------------------------------------------------
sub processRename {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    source_name  => 'string',
    target_name  => 'string',
  );

  my $oldpath  = $self->makeSafeFileName($req->{source_name});
  my $newpath  = $self->makeSafeFileName($req->{target_name});

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_RENAME, $response);

  if ((not defined $oldpath or not defined $newpath) or ($self->{no_symlinks} and $self->{FS}->IsSymlink( $oldpath ) )){
    $response->setStatus( SSH2_FX_NO_SUCH_FILE );
    return;
  }

  return if $self->{FS}->IsDir( $oldpath ) and $self->denyOperation(NET_SFTP_RENAME_DIR, $response);

  if ( $self->{FS}->IsFile( $oldpath )) {
    #/* Race-free rename of regular files */
    if (! $self->{FS}->Link( $oldpath,  $newpath)) {#FIXME test all codepaths
      # link method failed - try just a rename
      if (! $self->{FS}->Rename($oldpath, $newpath)){
        $response->setStatus($self->errnoToPortable($!+0));
      }
      else {
        $response->setStatus(SSH2_FX_OK);
      }
    }
    elsif (! $self->{FS}->Unlink($oldpath)) {
      $response->setStatus( $self->errnoToPortable($!+0) );
      #/* clean spare link */
      $self->{FS}->Unlink($newpath);
    }
    else {
      $response->setStatus(SSH2_FX_OK);
    }
  }
  elsif ( $self->{FS}->IsDir( $oldpath ) ) {
    if (! $self->{FS}->Rename($oldpath, $newpath)){
      $response->setStatus($self->errnoToPortable($!+0));
    }
    else {
      $response->setStatus(SSH2_FX_OK);
    }
  }
  else {
    # File does not exist or is a symlink - deny all knowlege
    $response->setStatus(SSH2_FX_NO_SUCH_FILE);
  }
}
#-------------------------------------------------------------------------------
sub processReadlink {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    name     => 'string',
  );

  $self->logAction();

  $response->setStatus(SSH2_FX_NO_SUCH_FILE); # all symlinks hidden
}
#-------------------------------------------------------------------------------
sub processSymlink {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    source_name  => 'string',
    target_name  => 'string',
  );

  my $oldpath  = $self->makeSafeFileName($req->{source_name});
  my $newpath  = $self->makeSafeFileName($req->{target_name});

  $self->logAction();

  return if $self->denyOperation(SSH2_FXP_SYMLINK, $response);

  logError "processSymlink not implemented";
}
#-------------------------------------------------------------------------------
sub processExtended {
  my $self = shift;
  my $payload = shift;
  my $response = shift;

  my $req = $payload->getPayloadContent(
    request  => 'string',
  );

  $self->logAction();

  $response->setStatus( SSH2_FX_OP_UNSUPPORTED );    #/* MUST */
}
#-------------------------------------------------------------------------------
sub denyOperation {
  my $self = shift;
  my ($op, $response) = @_;
  if (defined $self->{deny}{$op} and $self->{deny}{$op}){
    logWarning "Denying request operation: " . MESSAGE_TYPES->{$op} . ", id: " . $response->getId();
    if (defined $self->{fake_ok}{$op} and $self->{fake_ok}{$op}){
      $response->setStatus( SSH2_FX_OK );
    }
    else {
      $response->setStatus( SSH2_FX_PERMISSION_DENIED );
    }
    return 1;
  }
  return;
}
#-------------------------------------------------------------------------------
sub lsFile {
  my $self = shift;
  my $name = shift;
  my $st = shift;
  my @ltime = localtime($st->[9]);
  my $mode = format_mode($st->[2]);

  my $user  = getpwuid($st->[4]);
  my $group = getgrgid($st->[5]);
  my $sz;
  if (scalar @ltime) {
    if (time() - $st->[9] < (365*24*60*60)/2){
      $sz = strftime "%b %e %H:%M", @ltime;
    }
    else {
      $sz = strftime "%b %e  %Y",   @ltime;
    }
  }

  my $ulen = length $user  > 8 ? length $user  : 8;
  my $glen = length $group > 8 ? length $group : 8;
  return sprintf("%s %3u %-*s %-*s %8llu %s %s", $mode, $st->[3], $ulen, $user, $glen, $group, $st->[7], $sz, $name);
}
#-------------------------------------------------------------------------------
sub makeSafeFileName {
  my $self = shift;
  # We force all file names to be treated as from / which we treat as the users home directory
  my $name = shift;

  $name = "/$name";
  while ($name =~ s!/\./!/!g)   {}
  $name =~ s!//+!/!g;

  my @path = split('/', $name);
  my @newpath;
  for my $d (@path){
    if ($d eq  '..'){
      pop @newpath;
    }
    elsif ($d ne '.') {
      if ($self->{valid_filename_char}){
        if ($d !~ /^[$self->{valid_filename_char}]*$/){
          logError "Invalid characters in $name";
          return;
        }
      }
      push @newpath, $d;
    }
    if ($self->{no_symlinks}){
      if ( $self->{FS}->IsSymlink( join('/', @newpath) ) ){
        return; # no symlinks
      }
    }
  }

  $name = join('/', @newpath) || '/';
  $name =~ s!/\.$!/!;
  return $name;
}
#-------------------------------------------------------------------------------
sub encodeAttrib {
  my $self = shift;
  my $attr = shift;
  $attr->{flags} ||= 0;
  my $msg = pack('N', $attr->{flags});
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_SIZE){
    my $h = int($attr->{size} / (1 << 32));
    my $l =     $attr->{size} % (1 << 32);
    $msg .= pack('NN', $h, $l );
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_UIDGID) {
    $msg .= pack('N', $attr->{uid});
    $msg .= pack('N', $attr->{gid});
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS){
    $msg .= pack('N', $attr->{perm});
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_ACMODTIME) {
    $msg .= pack('N', $attr->{atime});
    $msg .= pack('N', $attr->{mtime});
  }
  return $msg;
}
#-------------------------------------------------------------------------------
sub statToAttrib {
  my $self = shift;
  my @stats = @_;
  #/* Convert from struct stat to filexfer attribs */
  my $attr = {};
  $attr->{flags} = 0;
  $attr->{flags} |= SSH2_FILEXFER_ATTR_SIZE;
  $attr->{size} = $stats[7];
  $attr->{flags} |= SSH2_FILEXFER_ATTR_UIDGID;
  $attr->{uid} = $stats[4];
  $attr->{gid} = $stats[5];
  $attr->{flags} |= SSH2_FILEXFER_ATTR_PERMISSIONS;
  $attr->{perm} = $stats[2];
  $attr->{flags} |= SSH2_FILEXFER_ATTR_ACMODTIME;
  $attr->{atime} = $stats[8];
  $attr->{mtime} = $stats[9];

  return $attr;
}
#-------------------------------------------------------------------------------
sub flagsFromPortable{
  my $self = shift;
  my $pflags = shift;
  my $flags = 0;

  if (($pflags & SSH2_FXF_READ) &&
      ($pflags & SSH2_FXF_WRITE)) {
    $flags = O_RDWR;
  }
  elsif ($pflags & SSH2_FXF_READ) {
    $flags = O_RDONLY;
  }
  elsif ($pflags & SSH2_FXF_WRITE) {
    $flags = O_WRONLY;
  }
  if ($pflags & SSH2_FXF_CREAT){
    $flags |= O_CREAT;
  }
  if ($pflags & SSH2_FXF_TRUNC){
    $flags |= O_TRUNC;
  }
  if ($pflags & SSH2_FXF_EXCL){
    $flags |= O_EXCL;
  }
  return $flags;
}
#-------------------------------------------------------------------------------
sub errnoToPortable {
  my $self = shift;
  my $errno = shift;

  if ($errno == 0){
    logWarning "Good error code received by errnoToPortable";
    return SSH2_FX_OK;
  }
  elsif ( $errno ==  ENOENT or
          $errno ==  ENOTDIR or
          $errno ==  EBADF or
          $errno ==  ELOOP ){
    return SSH2_FX_NO_SUCH_FILE;
  }
  elsif ( $errno ==   EPERM or
          $errno ==   EACCES or
          $errno ==   EFAULT ){
    return SSH2_FX_PERMISSION_DENIED;
  }
  elsif ( $errno == ENAMETOOLONG or
          $errno ==   EINVAL){
    return SSH2_FX_BAD_MESSAGE;
  }
  else {
    return SSH2_FX_FAILURE;
  }
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
package Net::SFTP::SftpServer::Buffer;
use strict;
use warnings;

#/* attributes */
use constant SSH2_FILEXFER_ATTR_SIZE        => 0x00000001;
use constant SSH2_FILEXFER_ATTR_UIDGID      => 0x00000002;
use constant SSH2_FILEXFER_ATTR_PERMISSIONS => 0x00000004;
use constant SSH2_FILEXFER_ATTR_ACMODTIME   => 0x00000008;
use constant SSH2_FILEXFER_ATTR_EXTENDED    => 0x80000000;

1;
#-------------------------------------------------------------------------------
sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  my %arg = @_;
  $self->{data} = $arg{data};
  return $self;
}
#-------------------------------------------------------------------------------
sub asString {
  my $self = shift;

  my @strings;
  push @strings, length $self->{data} . " bytes left to decode";
  push @strings, "Decoded: ";
  for my $key ( sort keys %{$self->{_decoded_data}} ){
    if ($key eq 'data' and $self->{_decoded_data}{data} !~ /^[\s\w]*$/){
      push @strings, "$key\t\t=><Binary data>";
    }
    else {
      push @strings, "$key\t\t=>$self->{_decoded_data}{$key}";
    }
  }

  return join("\n", @strings)
}
# ------------------------------------------------------------------------------
sub getPayloadContent {
  my $self = shift;

  while ( my $name = shift and my $type = shift ){
    if ($type eq 'int'){
      $self->{_decoded_data}{$name} = $self->getInt();
    }
    elsif ($type eq 'int64'){
      $self->{_decoded_data}{$name} = $self->getInt64();
    }
    elsif ($type eq 'char'){
      $self->{_decoded_data}{$name} = $self->getChar();
    }
    elsif ($type eq 'string'){
      $self->{_decoded_data}{$name} = $self->getString();
    }
    elsif ($type eq 'attrib'){
      $self->{_decoded_data}{$name} = $self->getAttrib();
    }
  }

  return $self->{_decoded_data};
}
# ------------------------------------------------------------------------------
sub getInt {
  my $self = shift;
  my $i = substr($self->{data}, 0, 4);
  $self->{data} = substr($self->{data}, 4);
  return unpack("N", $i);
}
# ------------------------------------------------------------------------------
sub getInt64 {
  my $self = shift;
  my $i = substr($self->{data}, 0, 8);
  $self->{data} = substr($self->{data}, 8);
  my ($h, $l) = unpack("NN", $i);
  return ($h << 32) + $l;
}
# ------------------------------------------------------------------------------
sub getChar {
  my $self = shift;
  my $c = substr($self->{data}, 0, 1);
  $self->{data} = substr($self->{data}, 1);
  return unpack("C", $c);
}
# ------------------------------------------------------------------------------
sub getString {
  my $self = shift;
  my $len = $self->getInt();
  my $str = substr($self->{data}, 0, $len);
  $self->{data} = substr($self->{data}, $len);
  return $str;
}
#-------------------------------------------------------------------------------
sub getAttrib {
  my $self = shift;
  #/* Decode attributes in buffer */

  my $attr = {};

  $attr->{flags} = $self->getInt();
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_SIZE){
    $attr->{size} = $self->getInt64();
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_UIDGID) {
    $attr->{uid} = $self->getInt();
    $attr->{gid} = $self->getInt();
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS){
    $attr->{perm} = $self->getInt();
  }
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_ACMODTIME) {
    $attr->{atime} = $self->getInt();
    $attr->{mtime} = $self->getInt();
  }

  #/* vendor-specific extensions */
  if ($attr->{flags} & SSH2_FILEXFER_ATTR_EXTENDED) {
    my $count = $self->getInt();
    for (my $i = 0; $i < $count; $i++) {
      my $type = $self->getString();
      my $req = $self->getString();
      logDetail("Got file attribute \"%s\"", $type);
    }
  }
  return $attr;
}
# ------------------------------------------------------------------------------
sub done {
  my $self = shift;
  return 1 if length $self->{data} eq 0;
  return;
}
#-------------------------------------------------------------------------------
sub setFileType {
  my $self = shift;
  $self->{file_type} = shift;
}
#-------------------------------------------------------------------------------
sub getFileType {
  my $self = shift;
  return $self->{file_type};
}
#-------------------------------------------------------------------------------
sub setFilename {
  my $self = shift;
  $self->{filename} = shift;
}
#-------------------------------------------------------------------------------
sub getFilename {
  my $self = shift;
  return $self->{filename};
}
1;
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
package Net::SFTP::SftpServer::Response;
use strict;
use warnings;

#/* server to client */
use constant SSH2_FXP_VERSION               => 2;
use constant SSH2_FXP_STATUS                => 101;
use constant SSH2_FXP_HANDLE                => 102;
use constant SSH2_FXP_DATA                  => 103;
use constant SSH2_FXP_NAME                  => 104;
use constant SSH2_FXP_ATTRS                 => 105;

1;
#-------------------------------------------------------------------------------
sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self;
}
#-------------------------------------------------------------------------------
sub asString {
  my $self = shift;

  my @strings;
  for my $key ( sort keys %$self ){
    if ($key eq 'data' and $self->{data} !~ /^[\s\w]*$/){
      push @strings, "$key\t\t=><Binary data>";
    }
    else {
      push @strings, "$key\t\t=>$self->{$key}";
    }
  }

  return join("\n", @strings)
}
#-------------------------------------------------------------------------------
sub setId {
  my $self = shift;
  $self->{id} = shift;
}
#-------------------------------------------------------------------------------
sub getId {
  my $self = shift;
  return $self->{id};
}
#-------------------------------------------------------------------------------
sub getType {
  my $self = shift;
  return $self->{type};
}
#-------------------------------------------------------------------------------
sub setStatus {
  my $self = shift;
  $self->{status} = shift;
  $self->{type} = SSH2_FXP_STATUS;
}
#-------------------------------------------------------------------------------
sub getStatus {
  my $self = shift;
  return $self->{status};
}
#-------------------------------------------------------------------------------
sub setData {
  my $self = shift;
  $self->{data_length} = shift;
  $self->{data} = shift;
  $self->{type} = SSH2_FXP_DATA;
}
#-------------------------------------------------------------------------------
sub getData {
  my $self = shift;
  return $self->{data};
}
#-------------------------------------------------------------------------------
sub getDataLength {
  my $self = shift;
  return $self->{data_length};
}
#-------------------------------------------------------------------------------
sub setHandle {
  my $self = shift;
  $self->{handle} = shift;
  $self->{type} = SSH2_FXP_HANDLE;
}
#-------------------------------------------------------------------------------
sub getHandle {
  my $self = shift;
  return $self->{handle};
}
#-------------------------------------------------------------------------------
sub setNames {
  my $self = shift;
  $self->{names} = shift;
  $self->{names} = [ $self->{names} ] unless ref $self->{names} eq 'ARRAY';
  $self->{type} = SSH2_FXP_NAME;
}
#-------------------------------------------------------------------------------
sub getNames {
  my $self = shift;
  return $self->{names};
}
#-------------------------------------------------------------------------------
sub setInitVersion {
  my $self = shift;
  $self->{version} = shift;
  $self->{type} = SSH2_FXP_VERSION;
}
#-------------------------------------------------------------------------------
sub getVersion {
  my $self = shift;
  return $self->{version};
}
#-------------------------------------------------------------------------------
sub setAttrs {
  my $self = shift;
  $self->{attr} = shift;
  $self->{type} = SSH2_FXP_ATTRS;
}
#-------------------------------------------------------------------------------
sub getAttrs {
  my $self = shift;
  return $self->{attr};
}
1;
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
package Net::SFTP::SftpServer::FS;

no strict;

use Exporter qw( import );

@EXPORT = qw(
  setChrootDir
);

use strict;
use warnings;

{
  my %callback_of;

  my $chroot_dir = '';

  #-------------------------------------------------------------------------------
  sub new {
    my $class = shift;
    my $self  = bless \do{my $anon}, $class;
    return unless $self->initialise( @_ ); # Dont keep the object unless we initialise sucessfully

    my $ident = scalar $self;

    $callback_of{$ident} = 0;

    return $self;
  }
  #-------------------------------------------------------------------------------
  sub initialise {
    return 1;
  }
  #-------------------------------------------------------------------------------
  sub setChrootDir {
    my $self = shift;
    $chroot_dir = shift;
  }
  #-------------------------------------------------------------------------------
  sub IsSymlink {
    my $self = shift;
    return -l $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Exists {
    my $self = shift;
    return -e $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub IsFile {
    my $self = shift;
    return -f $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub IsDir {
    my $self = shift;
    return -d $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub ZeroSize {
    my $self = shift;
    return -z $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Link {
    my $self = shift;
    return link( $chroot_dir . shift, $chroot_dir . shift);
  }
  #-------------------------------------------------------------------------------
  sub LStat {
    my $self = shift;
    return lstat $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Stat {
    my $self = shift;
    return stat $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Size {
    my $self = shift;
    return -s $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Unlink {
    my $self = shift;
    return unlink $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Mkdir {
    my $self = shift;
    return mkdir( $chroot_dir . shift, shift);
  }
  #-------------------------------------------------------------------------------
  sub Rmdir {
    my $self = shift;
    return rmdir $chroot_dir . shift;
  }
  #-------------------------------------------------------------------------------
  sub Rename {
    my $self = shift;
    my ($old, $new) = @_;
    return rename( $chroot_dir . $old, $chroot_dir . $new);
  }
  #-------------------------------------------------------------------------------
  sub chrootDir {
    my $self = shift;
    return $chroot_dir;
  }
  #-------------------------------------------------------------------------------
  sub setCallback {
    my $self = shift;
    my $ident = scalar($self);
    $callback_of{$ident} = 1;
  }
  #-------------------------------------------------------------------------------
  sub callback {
    my $self = shift;
    my $ident = scalar($self);
    return $callback_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub DESTROY {
    my $self = shift;
    my $ident = scalar($self);
    delete $callback_of{$ident};
  }
}
1;
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
package Net::SFTP::SftpServer::FileChrootBroken;

use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
  my $self = shift;

  my $method = $AUTOLOAD;
  $method =~ m/.+::(.+)(?!::)/;
  $method = $1 if $1;

  Net::SFTP::SftpServer::logError "$method is not supported after chroot is broken";

  return;
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
package Net::SFTP::SftpServer::File;
use strict;
use warnings;

use IO::File;
use File::Basename;
use Fcntl qw( O_RDWR O_CREAT O_TRUNC O_EXCL O_RDONLY O_WRONLY SEEK_SET );

use base qw( Net::SFTP::SftpServer::FS );

{
  my $TMP_EXT = ".SftpXFR.$$";

  my %fh_of;
  my %filename_of;
  my %mode_of;
  my %perm_of;
  my %write_of;
  my %read_of;
  my %opentime_of;
  my %use_temp_of;
  my %err_of;
  my %state_of;

  #-------------------------------------------------------------------------------
  sub initialise {
    my $self = shift;

    my ($filename, $mode, $perm, $use_tmp) = @_;

    $use_tmp ||= 0;
    my $realfile = $filename;
    if ($use_tmp){
      $filename .= $TMP_EXT;
    }

    my $fd = IO::File->new($self->chrootDir . $filename, $mode, $perm);

    return unless defined $fd;

    my $ident = scalar($self);
    $filename_of{$ident} = $realfile;
    $fh_of{$ident}       = $fd;
    $mode_of{$ident}     = $mode;
    $perm_of{$ident}     = $perm;
    $write_of{$ident}    = 0;
    $read_of{$ident}     = 0;
    $opentime_of{$ident} = time();
    $use_temp_of{$ident} = $use_tmp;
    $state_of{$ident}    = 'open';

    return 1;
  }
  #-------------------------------------------------------------------------------
  sub err {
    my $self = shift;
    my $ident = scalar($self);

    return $err_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub close {
    my $self = shift;
    my $ident = scalar($self);
    my $ret = $fh_of{$ident}->close();
    unless ($ret){
      $err_of{$ident} = $!+0;
    }

    if ($use_temp_of{$ident}){
      $self->Rename( $filename_of{$ident} . $TMP_EXT, $filename_of{$ident} );
      $use_temp_of{$ident} = 0;
    }

    $state_of{$ident}    = 'closed';
    return $ret;
  }
  #-------------------------------------------------------------------------------
  sub getFilename {
    my $self = shift;
    my $ident = scalar($self);
    return $filename_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub getMode {
    my $self = shift;
    my $ident = scalar($self);
    return $mode_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub getPerm {
    my $self = shift;
    my $ident = scalar($self);
    return $perm_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub wroteBytes {
    my $self = shift;
    my $ident = scalar($self);
    my $size = shift;
    $write_of{$ident} += $size;
  }
  #-------------------------------------------------------------------------------
  sub readBytes {
    my $self = shift;
    my $ident = scalar($self);
    my $size = shift;
    $read_of{$ident} += $size;
  }
  #-------------------------------------------------------------------------------
  sub getWrittenBytes {
    my $self = shift;
    my $ident = scalar($self);
    return $write_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub getReadBytes {
    my $self = shift;
    my $ident = scalar($self);
    $read_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub getStats {
    my $self = shift;
    my $ident = scalar($self);
    my $stats = "Filename: $filename_of{$ident} ";
    my $dtime = (time() - $opentime_of{$ident}) || 1;
    if ($write_of{$ident} and $read_of{$ident}){
      ## reads and writes
      my $speed = int(($write_of{$ident} + $read_of{$ident}) / (1024 * $dtime));
      $stats .= "Received: $write_of{$ident} bytes Sent: $read_of{$ident} in $dtime seconds Speed: $speed K/s";
    }
    elsif ($write_of{$ident}){
      # File received
      my $speed = int($write_of{$ident} / (1024 * $dtime));
      $stats .= "Received: $write_of{$ident} bytes in $dtime seconds Speed: $speed K/s";
    }
    elsif ($read_of{$ident}){
      # File Sent
      my $speed = int($read_of{$ident} / (1024 * $dtime));
      $stats .= "Sent: $read_of{$ident} bytes in $dtime seconds Speed: $speed K/s";
    }
    else {
      $stats .= "No data sent or received";
    }
    return $stats;
  }
  #-------------------------------------------------------------------------------
  sub wasReceived {
    my $self = shift;
    my $ident = scalar($self);
    if ($write_of{$ident} and ! $read_of{$ident} and $self->Size( $filename_of{$ident} ) eq $write_of{$ident}){
      return 1;
    }
    return;
  }
  #-------------------------------------------------------------------------------
  sub wasSent {
    my $self = shift;
    my $ident = scalar($self);
    if ($read_of{$ident} and ! $write_of{$ident} and $self->Size( $filename_of{$ident} ) eq $read_of{$ident}){
      return 1;
    }
    return;
  }
  #-------------------------------------------------------------------------------
  sub getType {
    my $self = shift;
    return 'file';
  }
  #-------------------------------------------------------------------------------
  sub sysread {
    my $self = shift;
    my $ident = scalar($self);
    return $fh_of{$ident}->sysread( @_ );
  }
  #-------------------------------------------------------------------------------
  sub syswrite {
    my $self = shift;
    my $ident = scalar($self);
    return $fh_of{$ident}->syswrite( @_ );
  }
  #-------------------------------------------------------------------------------
  sub sysseek {
    my $self = shift;
    my $ident = scalar($self);
    return $fh_of{$ident}->sysseek( @_ );
  }
  #-------------------------------------------------------------------------------
  sub read {
    my $self = shift;
    my $ident = scalar($self);
    unless ( $self->callback ){
      Net::SFTP::SftpServer::logError "read method called outside from callback";
      return;
    }

    if ($state_of{$ident} ne 'open'){
      $fh_of{$ident}->open( $self->chrootDir . $filename_of{$ident}, '<' );
      $state_of{$ident} = 'open';
    }
    return $fh_of{$ident}->read( @_ );
  }
  #-------------------------------------------------------------------------------
  sub open {
    my $self = shift;
    my $ident = scalar($self);
    unless ( $self->callback ){
      Net::SFTP::SftpServer::logError "open method called outside from callback";
      return;
    }

    if ($state_of{$ident} ne 'open'){
      my $ret = $fh_of{$ident}->open( $self->chrootDir . $filename_of{$ident}, @_ );
      $state_of{$ident} = 'open';
      return $ret;
    }
  }
  #-------------------------------------------------------------------------------
  sub moveToProcessed {
    my $self = shift;
    my %arg = @_;

    my $ident = scalar $self;

    if ($arg{BREAKCHROOT}){
      return $self->moveToProcessedBREAKCHROOT( @_ );
    }

    $arg{dst}         ||= 'processed';
    $arg{dir_perms}   ||= 0770;

    unless ($self->Exists($filename_of{$ident})){
      Net::SFTP::SftpServer::logWarning "moveToProcessed: File $filename_of{$ident} does not exist";
      return;
    }


    if ($filename_of{$ident} =~ m!/$arg{dst}/!){
      # file is already in a processed directory
      return;
    }

    if ($arg{filename_condition}){
      return unless ($filename_of{$ident} =~ m/$arg{filename_condition}/ );
    }

    my $dir = dirname($filename_of{$ident});
    if (! $self->Exists( "$dir/processed" )){
      unless ($self->Mkdir( "$dir/processed", $arg{dir_perms} )){
        Net::SFTP::SftpServer::logWarning "moveToProcessed: failed to mkdir $dir/processed";
        return;
      }
    }
    elsif (! $self->IsDir( "$dir/processed") ){
      Net::SFTP::SftpServer::logWarning "moveToProcessed: $dir/processed exists but is not a directory";
      return;
    }

    my $name = fileparse($filename_of{$ident});
    if ( $self->Exists( "$dir/processed/$name" ) ){
      Net::SFTP::SftpServer::logWarning "moveToProcessed: cannot move $filename_of{$ident} - $dir/processed/$name already exists";
      return;
    }

    unless ($self->Rename( $filename_of{$ident}, "$dir/processed/$name" )){
      Net::SFTP::SftpServer::logWarning "moveToProcessed: failed to rename $filename_of{$ident} to $dir/processed/$name";
      return;
    }

    $filename_of{$ident} = "$dir/processed/$name";

    Net::SFTP::SftpServer::logGeneral "moveToProcessed: moved $filename_of{$ident} to $dir/processed/$name";
  }
  #-------------------------------------------------------------------------------
  sub moveToProcessedBREAKCHROOT {
    my $self = shift;
    my %arg = @_;

    my $ident = scalar $self;

    unless ( -d $arg{dst} and -w $arg{dst} ){
      Net::SFTP::SftpServer::logWarning "Cannot write to target directory $arg{dst}";
      return;
    }

    unless ($self->Exists($filename_of{$ident})){
      Net::SFTP::SftpServer::logWarning "moveToProcessed: File $filename_of{$ident} does not exist";
      return;
    }

    if ($arg{filename_condition}){
      return unless ($filename_of{$ident} =~ m/$arg{filename_condition}/ );
    }

    my $name = fileparse($filename_of{$ident});

    bless $self, 'Net::SFTP::SftpServer::FileChrootBroken';

    $self->renameBREADCHROOT( $arg{dst} . "/$name" );

    Net::SFTP::SftpServer::logGeneral "moveToProcessed: moved $filename_of{$ident} to $arg{dst}/$name";
  }
  #-------------------------------------------------------------------------------
  sub getFullFilenameBREAKCHROOT {
    my $self = shift;
    my $ident = scalar $self;

    my $chroot_dir = $self->chrootDir;

    bless $self, 'Net::SFTP::SftpServer::FileChrootBroken';

    return $chroot_dir . $filename_of{$ident}
  }
  #-------------------------------------------------------------------------------
  sub renameBREAKCHROOT {
    my $self = shift;
    my $ident = scalar $self;

    my $newname = shift;

    my $chroot_dir = $self->chrootDir;

    bless $self, 'Net::SFTP::SftpServer::FileChrootBroken';

    return rename $chroot_dir . $filename_of{$ident}, $newname;
  }
  #-------------------------------------------------------------------------------
  sub DESTROY {
    my $self = shift;
    my $ident = scalar($self);

    $fh_of{$ident}->close() if defined $fh_of{$ident} and $fh_of{$ident}->opened;
    delete $fh_of{$ident};
    delete $filename_of{$ident};
    delete $mode_of{$ident};
    delete $perm_of{$ident};
    delete $write_of{$ident};
    delete $read_of{$ident};
    delete $opentime_of{$ident};
    delete $use_temp_of{$ident};
    delete $err_of{$ident};
    delete $state_of{$ident};

    $self->SUPER::DESTROY()
  }
}
1;
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
package Net::SFTP::SftpServer::Dir;
use strict;
use warnings;

use IO::Dir;

use base qw( Net::SFTP::SftpServer::FS  );

{
  my %fd_of;
  my %path_of;
  my %dir_err_of;
  #-------------------------------------------------------------------------------
  sub initialise {
    my $self = shift;

    my ($path) = @_;

    my $fd = IO::Dir->new($self->chrootDir() . $path);

    return unless defined $fd;

    $path .= '/';
    $path =~ s!//$!/!; # make sure we have a trailing /
    my $ident = scalar($self);
    $path_of{$ident} = $path;
    $fd_of{$ident}   = $fd;

    return 1;
  }
  #-------------------------------------------------------------------------------
  sub err {
    my $self = shift;
    my $ident = scalar($self);

    return $dir_err_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub close {
    my $self = shift;
    my $ident = scalar($self);

    my $ret = $fd_of{$ident}->close();
    unless ($ret){
      $dir_err_of{$ident} = $!+0;
    }

    return $ret;
  }
  #-------------------------------------------------------------------------------
  sub getFilename {
    my $self = shift;
    my $ident = scalar($self);
    return "$path_of{$ident}";
  }
  #-------------------------------------------------------------------------------
  sub getPath {
    my $self = shift;
    my $ident = scalar($self);
    return $path_of{$ident};
  }
  #-------------------------------------------------------------------------------
  sub getType {
    my $self = shift;
    return 'dir';
  }
  #-------------------------------------------------------------------------------
  sub readdir {
    my $self = shift;
    my $ident = scalar $self;
    return $fd_of{$ident}->read();
  }
  #-------------------------------------------------------------------------------
  sub DESTROY {
    my $self = shift;
    my $ident = scalar($self);

    delete $fd_of{$ident};
    delete $path_of{$ident};
    delete $dir_err_of{$ident};

    $self->SUPER::DESTROY()
  }
}
1;
#-------------------------------------------------------------------------------
__END__
#-------------------------------------------------------------------------------
=head1 NAME

Net::SFTP::SftpServer - A Perl implementation of the SFTP subsystem with user access controls

=head1 SYNOPSIS

  use Net::SFTP::SftpServer;

  my $sftp = Net::SFTP::SftpServer->new();

  $sftp->run();

=head1 DESCRIPTION


A Perl port of sftp-server from openssh providing access control on a per user per command basis and improved logging via syslog

The limitations compared with the openssh implementation are as follows:

=over

=item *

Only files and directories are dealt with - other types are not returned on readdir

=item *

a virtual chroot is performed - / is treated as the users home directory from the
client perspective and all file access to / will be in /<home_path>/<username>
home_path is defined on object initialisation not accessed from /etc/passwd
The script DOES NOT run under chroot - this prevents it needing SUID to start.
The virtual chroot is enforced by the objects and prevent opperations outside the
home area

=item *

all sym linked files or directories are hidden and not accessible on request

=item *

symlink returns permission denied. Please contact me if you need this functionaility implementing

=item *

readlink returns file does not exist. Please contact me if you need this functionaility implementing

=item *

setting of stats (set_stat or set_fstat) is disabled - client will receive permission denied.
Please contact me if you need this functionaility implementing

=item *

permissions for file or dir is defaulted - default set on object initialisation

=back

=head1 USAGE

Basic usage:

  use Net::SFTP::SftpServer;

Import options:

  :LOG    - Import logging functions for use in callbacks
  :ACTION - Import constants for Allow/Deny of actions

Configuring syslog:

Syslog output mode must be configured in the use statement of the module as follows:

  use Net::SFTP::SftpServer ( { log => 'local5' }, qw ( :LOG :ACTIONS ) );

Net::SFTP::SftpServer will default to using C<daemon> see your system's syslog documentation for more details


Options for object initialisation:

=over

=item

debug

Log debug level information. Deault=0 (note this will create very large log files - use with caution)

=item

home

Filesystem location of user home directories. default=/home

=item

file_perms

Octal file permissions to force on creation of files. Default=0666 or permissions specified by file open command from client

=item

dir_perms

Octal dir permissions to force on creation of directories. Default=0777 or permissions specified by mkdir command from client

=item

on_file_sent, on_file_received

References to callback functions to be called on complete file sent or received. Function will be passed the full path and filename on the filesystem as a single argument

=item

use_tmp_upload

Use temporary upload filenames while a file is being uploaded - this allows a monitoring script to know which files are in transit without having to watch file size.
Will be done transparantly to the user, the file will be renamed to the original file name when close. The temportary extension is ".SftpXFR.$$". Default=0

=item

max_file_size

Maximum file size (in bytes) which can be uploaded. Default=0 (no limit)

=item

valid_filename_char

Array of valid characters for filenames

=item

allow, deny

Actions allowed or denied - see L</PERMISSIONS> for details, Default is to allow ALL.

=item

fake_ok

Array of actions (see action contants in L</PERMISSIONS>) which will be given response SSH2_FX_OK instead of SSH2_FX_PERMISSION_DENIED when denied by above deny options. Default=[]

=item

log_action_supress

Array of actions to log quietly (logDetail - syslog debug level), logs messages whenever this action is performed. Default is quiet for SSH2_FXP_READ, SSH2_FXP_WRITE, SSH2_FX_OPENDIR, SSH2_FXP_READDIR, SSH2_FXP_CLOSE, SSH2_FXP_STAT SSH2_FXP_FSTAT and SSH2_FXP_LSTAT override with log_action, see below.

=item

log_action

Array of actions to log loudly (logGeneral - syslog info level), logs messages whenever this action is performed.

=item

log_all_status

Log all status messages at info level. By default SSH2_FX_OK and SSH2_FX_EOF will be logged at debug level.

=back

=head1 PERMISSIONS

  ALL                      - All actions
  NET_SFTP_SYMLINKS        - Symlinks in paths to files (recommended deny to enforce chroot)
  NET_SFTP_RENAME_DIR      - Rename directories (recommended deny if also denying SSH2_FXP_MKDIR)
  SSH2_FXP_OPEN
  SSH2_FXP_CLOSE
  SSH2_FXP_READ
  SSH2_FXP_WRITE
  SSH2_FXP_LSTAT
  SSH2_FXP_STAT_VERSION_0
  SSH2_FXP_FSTAT
  SSH2_FXP_SETSTAT         - Automatically denied, not implemented in module
  SSH2_FXP_FSETSTAT        - Automatically denied, not implemented in module
  SSH2_FXP_OPENDIR
  SSH2_FXP_READDIR
  SSH2_FXP_REMOVE
  SSH2_FXP_MKDIR
  SSH2_FXP_RMDIR
  SSH2_FXP_STAT
  SSH2_FXP_RENAME
  SSH2_FXP_READLINK        - Automatically denied, not implemented in module
  SSH2_FXP_SYMLINK         - Automatically denied, not implemented in module

=head1 CALLBACKS

Callback functions can be used to perform actions when files are sent or received, for example move a fully downloaded file to a processed directory or move a received file into an input directory.
The callback is proided with a Net::SFTP::SftpServer::File object. This object allows access to the file within the virtual chroot environment. It will also return the full filename, or move the file to an explicit location on the full filesystem. Either of these actions will break the chroot and the methods on the object will no longer be available.

The following methods are provided

=over

=item

read

Read the data from the file - as the IO::File->read. Will open the file for reading if it is not already open and read back the data.

=item

open

Will open the file - as IO::File->open but the filename is not supplied.

=item

getFilename

Will return the filename as within the virtual chroot

=item

getFullFilenameBREAKCHROOT

Will return the full filename on the real file system and break the virtual chroot

=item

renameBREAKCHROOT

Takes a single argument of the new filename, will rename the file to that location and break the virtual chroot

=back

=head1 LOGGING

If :LOG is used when including Net::SFTP::SftpServer the following logging functions will be available:

  logError    - syslog with a log level of error
  logWarning  - syslog with a log level of warning
  logGeneral  - syslog with a log level of info
  logDetail   - syslog with a log level of debug, unless object was created with debug=>1 then syslog with a level of info

=head1 HARDENED EXAMPLE SCRIPT

The following example script shows how this module can be used to give far greater control over what is allowed on your SFTP server.

This setup is aimed at admins which want to user SFTP uploads but do not wish to grant users a system account.
You will also need to set both the SFTP subsystem and the user's shell to the sftp script, eg /usr/local/bin/sftp-server.pl

This configuration:

=over

=item * Enforces that users can only access the sftp script, not an ssh shell.

=item * Chroots them into their home directory in /var/upload/sftp

=item * Sets all file permissions to 0660 and does not permit users to change them.

=item * Does not allow symlinks, making directories or renaming directories, but allows all other normal actions.

=item * Has a max upload filesize of 200Mb

=item * Has a script memory limit of 100Mb for safety

=item * Will log actions by user sftptest in debug mode

=item * Will only allow alphanumeric plus _ . and - in filenames

=item * Will call ActionOnSent and ActionOnReceived respectively when files have been sent or received.

=back

  #!/usr/local/bin/perl

  use strict;
  use warnings;
  use Net::SFTP::SftpServer ( { log => 'local5' }, qw ( :LOG :ACTIONS ) );
  use BSD::Resource;        # for setrlimit

  use constant DEBUG_USER => {
    SFTPTEST => 1,
  };


  # Security - make sure we have started this as sftp not ssh
  unless ( scalar @ARGV == 2 and
           $ARGV[0] eq '-c'  and
           ($ARGV[1] eq '/usr/local/bin/sftp-server.pl') ){

         logError "SFTP connection attempted for application $ARGV[0] - exiting";
         print "\n\rYou do not have permission to login interactively to this host.\n\r\n\rPlease contact the system administrator if you believe this to be a configuration error.\n\r";
         exit 1;
  }

  my $MEMLIMIT = 100 * 1024 * 1024; # 100 Mb

  # hard limits on process memory usage;
  setrlimit( RLIMIT_RSS,  $MEMLIMIT, $MEMLIMIT );
  setrlimit( RLIMIT_VMEM, $MEMLIMIT, $MEMLIMIT );

  my $debug = (defined DEBUG_USER->{uc(getpwuid($>))} and DEBUG_USER->{uc(getpwuid($>))}) ? 1 : 0;

  my $sftp = Net::SFTP::SftpServer->new(
    debug               => $debug,
    home                => '/var/upload/sftp',
    file_perms          => 0660,
    on_file_sent        => \&ActionOnSent,
    on_file_received    => \&ActionOnReceived,
    use_tmp_upload      => 1,
    max_file_size       => 200 * 1024 * 1024,
    valid_filename_char => [ 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '.', '-' ],
    deny                => ALL,
    allow               => [ (
                                SSH2_FXP_OPEN,
                                SSH2_FXP_CLOSE,
                                SSH2_FXP_READ,
                                SSH2_FXP_WRITE,
                                SSH2_FXP_LSTAT,
                                SSH2_FXP_STAT_VERSION_0,
                                SSH2_FXP_FSTAT,
                                SSH2_FXP_OPENDIR,
                                SSH2_FXP_READDIR,
                                SSH2_FXP_REMOVE,
                                SSH2_FXP_STAT,
                                SSH2_FXP_RENAME,
                             )],
    fake_ok             => [ (
                                SSH2_FXP_SETSTAT,
                                SSH2_FXP_FSETSTAT,
                             )],
  );

  $sftp->run();

  sub ActionOnSent {
    my $fileObject = shift;
     ## Do Stuff
  }

  sub ActionOnReceived {
    my $fileObject = shift;
     ## Do Stuff
  }

=head1 DEPENDENCIES

  Stat::lsMode
  Fcntl
  POSIX
  Sys::Syslog
  Errno

=head1 SEE ALSO

Sftp protocol L<http://www.openssh.org/txt/draft-ietf-secsh-filexfer-02.txt>

=head1 AUTHOR

  Simon Day, Pirum Systems Ltd
  cpan <at> simonday.info

=head1 COPYRIGHT AND LICENSE

Based on sftp-server.c
Copyright (c) 2000-2004 Markus Friedl.  All rights reserved.

Ported to Perl and extended by Simon Day
Copyright (c) 2009 Pirum Systems Ltd.  All rights reserved.

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


=cut

