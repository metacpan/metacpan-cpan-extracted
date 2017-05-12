package Net::SSH::Any::Constants;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

my %error = ( SSHA_OK                  =>  0,
              SSHA_CONNECTION_ERROR    =>  1,
              SSHA_CHANNEL_ERROR       =>  2,

              SSHA_TIMEOUT_ERROR       =>  4,
              SSHA_REMOTE_CMD_ERROR    =>  5,

              SSHA_ENCODING_ERROR      =>  7,
              SSHA_LOCAL_IO_ERROR      =>  8,

              SSHA_SCP_ERROR           =>  9,
              SSHA_SFTP_ERROR          => 10,

              SSHA_NO_BACKEND_ERROR    => 20,
              SSHA_BACKEND_ERROR       => 21,
              SSHA_UNIMPLEMENTED_ERROR => 22,
              SSHA_PROTOCOL_ERROR      => 23,

              SSHA_EAGAIN              => 30,
            );

for my $key (keys %error) {
    no strict 'refs';
    my $value = $error{$key};
    *{$key} = sub () { $value };
}

our %EXPORT_TAGS = (error => [keys %error]);
our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

1;
