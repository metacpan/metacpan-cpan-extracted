package TestConfig;

our %netftp_cfg = 
    (Debug => 1, Timeout => 120);

our %common_cfg =    
    (
     User => 'anonymous',           # overwrite anonymous USER default
     Host => 'ftp.us.debian.org',   # overwrite ftp.microsoft.com HOST default
     Pass => 'tbone@cpan.org',      # overwrite list@rebol.com PASS default
     RemoteDir  => '/debian',       # overwrite slash DIR default
     Type => 'I'                    # (binary) TYPE default
     );


our %xemacs_cfg =    
    (
     User => 'anonymous',           # overwrite anonymous USER default
     Host => 'ftp.xemacs.org',      # overwrite ftp.microsoft.com HOST default
     Pass => 'tbone@cpan.org',      # overwrite list@rebol.com PASS default
     RemoteDir  => '/pub',                   # overwrite slash DIR default
     Type => 'I'                    # (binary) TYPE default
     );

our %x_cfg =     # no more non-secure FTP allowed! shucks...
    (
     User => 'anonymous',           # overwrite anonymous USER default
     Host => 'ftp.x.org',      # overwrite ftp.microsoft.com HOST default
     Pass => 'tbone@cpan.org',      # overwrite list@rebol.com PASS default
     RemoteDir  => '/pub',                   # overwrite slash DIR default
     Type => 'I'                    # (binary) TYPE default
     );

our %wu_cfg =    
    (
     User => 'anonymous',           # overwrite anonymous USER default
     Host => 'ftp.wu-ftpd.org',     # overwrite ftp.microsoft.com HOST default
     Pass => 'tbone@cpan.org',      # overwrite list@rebol.com PASS default
     RemoteDir  => '/pub/software', # overwrite slash DIR default
     Type => 'I'                    # (binary) TYPE default
     );


1;
