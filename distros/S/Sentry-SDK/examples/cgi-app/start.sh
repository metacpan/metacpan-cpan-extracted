#!/bin/sh

start_server --port 127.0.0.1:3000 -- starman --workers 1 examples/cgi-app/my-app.cgi
