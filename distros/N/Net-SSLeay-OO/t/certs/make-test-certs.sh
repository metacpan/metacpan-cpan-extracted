#!/bin/sh

cd $(dirname $0)
set -e

touch index.txt

# create a CA request
if [ ! -s my-ca.req ]
then
  openssl req -batch -new -config ca-openssl.cnf \
    -keyout ca-key.pem -passout pass:secr1t \
    -out my-ca.req 
fi

# sign it using itself
if [ ! -s my-ca.pem ]
then
  openssl ca -create_serial  \
    -out my-ca.pem -days 365 -batch \
    -keyfile ca-key.pem -passin pass:secr1t -selfsign \
    -extensions v3_ca \
    -config ca-openssl.cnf \
    -infiles my-ca.req
fi

for which in server client;
do
  # create a $which Cert request
  if [ ! -s $which-cert.req ]
  then
    openssl req -batch -new -config $which-openssl.cnf \
      -keyout $which-key.pem -passout pass:secr1t \
      -out $which-cert.req 
  fi
  
  # sign it using CA cert
  if [ ! -s $which-cert.pem ]
  then
    openssl ca -create_serial  \
      -out $which-cert.pem -days 365 -batch \
      -keyfile ca-key.pem -passin pass:secr1t \
      -extensions ${which}_cert \
      -config ca-openssl.cnf \
      -infiles ${which}-cert.req
  fi
done

# this is like c_rehash, but we only want to mark the CA cert as
# trusted
fs=[0-9a-f]
for x in 1 2 3; do fs="$fs$fs"; done
rm $fs.[0-9] 2>/dev/null || true
ln -s my-ca.pem $(openssl x509 -hash -noout -in my-ca.pem).0

# should say "OK" for all certificates
openssl verify -CApath . my-ca.pem server-cert.pem client-cert.pem

echo "All certificates made."

