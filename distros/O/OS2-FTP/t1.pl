use OS2::FTP;
$acct = new OS2::FTP "127.0.0.1", "ak", "none";
$status = $acct->dir("con");
