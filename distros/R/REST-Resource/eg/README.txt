EXAMPLE CODE:

    This directory contains both server-side and client-side examples.

HIERARCHY:

    client/client.pl		- A sample RESTful client.
    cgi_server/parts.cgi	- A sample CGI RESTful server.
    fcgi_server/parts.fcgi	- A sample FCGI RESTful server.

SERVER CONFIGURATIONS:

    For CGI, read docs/INSTALL.CGI.txt.

    For FastCGI (aka CGI::Fast or FCGI), read docs/INSTALL.FASTCGI.txt

CLIENT CONFIGURATION:

    cd eg/client

    perl client.pl PUT    http://localhost/path/eg/cgi_server/parts.cgi put.inp text/plain
    perl client.pl GET    http://localhost/path/eg/cgi_server/parts.cgi text/plain

    perl client.pl POST   http://localhost/path/eg/cgi_server/parts.cgi post.inp text/plain
    perl client.pl GET    http://localhost/path/eg/cgi_server/parts.cgi text/plain

    perl client.pl DELETE http://localhost/path/eg/cgi_server/parts.cgi text/plain
    perl client.pl GET    http://localhost/path/eg/cgi_server/parts.cgi text/plain

    After each write-operation, do a read operation and verify that
    the write operation succeeded.
