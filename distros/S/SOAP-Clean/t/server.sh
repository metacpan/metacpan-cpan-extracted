#! /bin/bash

# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

cd ../examples ; perl -w soap-server.cgi --soap --verbose=10<<EOF
<?xml version="1.0" encoding="utf-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:server="cgifile:./soap-server.cgi">
  <SOAP-ENV:Header/>
  <SOAP-ENV:Body>
    <server:Call>
      <server:w><a>123</a></server:w>
      <server:sleep_for xsi:type="xsd:int">0</server:sleep_for>
      <server:y xsi:type="xsd:string">2</server:y>
      <server:x xsi:type="xsd:base64Binary">MQ==</server:x>
    </server:Call>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
