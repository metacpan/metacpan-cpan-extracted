#! /bin/bash

# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

cd ../examples
SERVER_NAME=quimby-lx.cs.cornell.edu \
SERVER_PORT=80 \
SERVER_PROTOCOL=HTTP/1.1 \
REQUEST_URI=/cgi-bin/stodghil/printenv.cgi \
REQUEST_METHOD=GET \
QUERY_STRING=wsdl \
VERBOSE_SERVER=10 \
perl soap-server.cgi
