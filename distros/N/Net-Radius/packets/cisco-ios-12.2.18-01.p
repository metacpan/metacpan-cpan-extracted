#!/usr/bin/perl

no utf8;

# Net::Radius test input
# Made with $Id: cisco-ios-12.2.18-01.p 64 2007-01-09 20:01:04Z lem $

$VAR1 = {
          'packet' => '� 4���� ��nÚ7z(�mbejar��E����my���m��',
          'secret' => undef,
          'description' => 'Cisco IOS 12.2(18)SXF3 - Access-Request',
          'authenticator' => '���� ��nÚ7z(�',
          'identifier' => 139,
          'dictionary' => undef,
          'opts' => {
                      'secret' => undef,
                      'output' => 'packets/cisco-ios-12.2.18-01',
                      'description' => 'Cisco IOS 12.2(18)SXF3 - Access-Request',
                      'authenticator' => '���� ��nÚ7z(�',
                      'identifier' => 139,
                      'dictionary' => [
                                        'dicts/dictionary'
                                      ],
                      'dont-embed-dict' => 1,
                      'noprompt' => 1,
                      'slots' => 3
                    },
          'slots' => 3
        };
