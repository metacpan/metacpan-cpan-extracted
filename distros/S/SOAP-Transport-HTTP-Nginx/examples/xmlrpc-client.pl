use XMLRPC::Lite;

$service	= XMLRPC::Lite->proxy('http://localhost/');
$res		= $service->test();
$res->fault ? print STDERR $res->faultstring : print "test result: '",$res->result,"'\n";
$str		= "asdf русский текст 1242";
$res		= $service->echo($str);
$res->fault ? print STDERR $res->faultstring : print "echo result ('$str'): '",$res->result,"'\n";
