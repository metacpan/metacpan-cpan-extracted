#!/bin/sh
## This is what a simple SSH tunnel might look like:
USER=avenj
ENDPOINT=your.remote.server
LOCALPORT=5511
REMOTEPORT=5511
ssh -f ${USER}@${ENDPOINT} \
	-L ${LOCALPORT}:127.0.0.1:${REMOTEPORT} \
	-N
##
:<<'CMTBLK'

... then bind() tcp://127.0.0.1:REMOTEPORT on the remote side and connect()
127.0.0.1:LOCALPORT on the side running the tunnel.

SSH is a pretty convenient poor man's VPN, providing an encrypted
channel to talk to a remote ZMQ socket that is only bound to localhost.
ZeroMQ 4+ has built-in encryption support, but SSH will work for 3.x or mixed
networks using insecure transports.

This is far more useful when combined with OpenSSH's certificate support
-- see the 'CERTIFICATES' section of ssh-keygen(1):

 ## Create a CA cert ->
    $ ssh-keygen -f ca_key
 ## Trust this CA key for the server-side account:
    $ echo "cert-authority $(cat ca_key.pub)" >>~/.ssh/authorized_keys
 ## Create a user key on the client-side if one doesn't exist:
    % ssh-keygen -f some_user_key
 ## Retrieve and sign the user's pub key:
    $ ssh-keygen -s ca_key -I "Joe User" some_user_key.pub
 ## or with valid users specified:
    $ ssh-keygen -s ca_key -I "Joe User" -n joeuser some_user_key.pub

Now you can easily add workers by signing their keys and allowing them to 
tunnel in to talk to ZMQ.

CMTBLK
