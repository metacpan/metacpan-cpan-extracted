use Net::FTP::Common;

our %netftp_cfg = 
    (Debug => 1, Timeout => 120);

our %common_cfg =    
    (
     # 
     # The first 2 options, if not present, 
     # lead to relying on .netrc for login
     #
     User => 'bongo',           
     Pass => 'mongo',      

     #
     # Other options
     #

     LocalDir  => "$ENV{HOME}/Documents/Chess/Games",   
     LocalFile => 'sicilian-defense.pgn',
     Host => 'urth.org',          
     RemoteDir  => '/WWW/domains/semantic-elements.com/chess/club/shaitan'
     );

$ez = Net::FTP::Common->new(\%common_cfg, %netftp_config); 
$ez->send;
