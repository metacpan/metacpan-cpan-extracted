#!/bin/sh

plackup \
  -I "lib" \
  -s "Gepok" \
  --https_ports "5001" \
  --ssl_key_file "examples/certs/server-key-nopass.pem" \
  --ssl_cert_file "examples/certs/server-crt.pem" \
  --ssl_verify_callback "1" \
  --ssl_verify_mode "1" \
  --ssl_ca_path "/etc/pki/tls/rootcerts/" \
  examples/gepok.psgi

