use Data::Dumper;
use Login;
use Net::FTP::Common;

our %netftp_cfg = 
    (Debug => 1, Timeout => 120);

  
$ez = Net::FTP::Common->new(\%Login::common_cfg, %netftp_config); 
$ez->delete(RemoteDir => 'tmp', RemoteFile => 'upfile');
