#!/usr/bin/perl

no utf8;

# Net::Radius test input
# Made with $Id: rsa-ar-01.p 64 2007-01-09 20:01:04Z lem $

$VAR1 = {
          'packet' => '� %����(��Z�1���pCAccess Denied
',
          'secret' => undef,
          'description' => 'RSA ACE/Server 6.0 [020] RADIUS (on Solaris 9) - Access-Reject',
          'authenticator' => '����(��Z�1���pC',
          'identifier' => 179,
          'dictionary' => undef,
          'opts' => {
                      'output' => 'packets/rsa-ar-01',
                      'description' => 'RSA ACE/Server 6.0 [020] RADIUS (on Solaris 9) - Access-Reject',
                      'authenticator' => '����(��Z�1���pC',
                      'identifier' => 179,
                      'dont-embed-dict' => 1,
                      'dictionary' => [
                                        'dicts/dictionary'
                                      ],
                      'slots' => 1
                    },
          'slots' => 1
        };
