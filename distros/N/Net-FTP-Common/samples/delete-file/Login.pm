package Login;

our %common_cfg =  (
  # 
  # The first 2 options, if not present, 
  # lead to relying on .netrc for login
  #
  User => 'bran',           
  Pass => 'Dong',      

  #
  # Other options
  #

  LocalFile => 'upfile',
  Host => 'lnc.usc.edu',          
  RemoteDir  => 'tmp'
 );


1;
