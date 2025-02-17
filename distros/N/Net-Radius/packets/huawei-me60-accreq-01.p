#!/usr/bin/perl

no utf8;

# Net::Radius test input
# Made with $Id: bin2packet 67 2007-01-14 18:51:42Z lem $

$VAR1 = {
          'packet' => 'BYS�\'Ve�B>�M/Z5CNT-BRAS-02-172.16.74.2 eth 0/2/2/2:260.11@dinamico��]�L���g��/>�y  �J      00:17:08:2f:2c:c9 CNT-BRAS-02-172.16.74.2=   W,CNT-BRAS-02-172.16.74.2 eth 0/2/2/2:260.11,#CNT-BRA0220202600001163f37c002614M1000000000/256000R  �;J�p7<#255.255.255.255 00:17:08:2f:2c:c9  
6�Huawei ME60�ME60�
dinamico',
          'secret' => 'br@5hu',
          'description' => 'Huawei Quidway® ME60 - Access-Request',
          'authenticator' => 'S�\'Ve�B>�M/Z',
          'identifier' => 66,
          'dictionary' => bless( {
                                   'packet' => undef,
                                   'vsattr' => {
                                                 '2011' => {
                                                             'Version' => [
                                                                            '254',
                                                                            'string'
                                                                          ],
                                                             'Product-ID' => [
                                                                               '255',
                                                                               'string'
                                                                             ],
                                                             'Connect-ID' => [
                                                                               '26',
                                                                               'integer'
                                                                             ],
                                                             'Domain-Name' => [
                                                                                '138',
                                                                                'string'
                                                                              ],
                                                             'Startup-Stamp' => [
                                                                                  '59',
                                                                                  'integer'
                                                                                ],
                                                             'Ip-Host-Addr' => [
                                                                                 '60',
                                                                                 'string'
                                                                               ]
                                                           }
                                               },
                                   'rattr' => {
                                                '6' => [
                                                         'Service-Type',
                                                         'integer'
                                                       ],
                                                '32' => [
                                                          'NAS-Identifier',
                                                          'string'
                                                        ],
                                                '61' => [
                                                          'NAS-Port-Type',
                                                          'integer'
                                                        ],
                                                '7' => [
                                                         'Framed-Protocol',
                                                         'integer'
                                                       ],
                                                '2' => [
                                                         'User-Password',
                                                         'string'
                                                       ],
                                                '87' => [
                                                          'NAS-Port-Id',
                                                          'string'
                                                        ],
                                                '1' => [
                                                         'User-Name',
                                                         'string'
                                                       ],
                                                '4' => [
                                                         'NAS-IP-Address',
                                                         'ipaddr'
                                                       ],
                                                '77' => [
                                                          'Connect-Info',
                                                          'string'
                                                        ],
                                                '44' => [
                                                          'Acct-Session-Id',
                                                          'string'
                                                        ],
                                                '31' => [
                                                          'Calling-Station-Id',
                                                          'string'
                                                        ],
                                                '5' => [
                                                         'NAS-Port',
                                                         'integer'
                                                       ]
                                              },
                                   'vendors' => {
                                                  'Huawei' => '2011'
                                                },
                                   'rpacket' => undef,
                                   'val' => {
                                              '6' => {
                                                       'Framed-User' => '2'
                                                     },
                                              '61' => {
                                                        'Ethernet' => '15'
                                                      },
                                              '7' => {
                                                       'PPP' => '1'
                                                     }
                                            },
                                   'rvsaval' => {
                                                  '2011' => {}
                                                },
                                   'attr' => {
                                               'NAS-Port-Type' => [
                                                                    '61',
                                                                    'integer'
                                                                  ],
                                               'Acct-Session-Id' => [
                                                                      '44',
                                                                      'string'
                                                                    ],
                                               'Service-Type' => [
                                                                   '6',
                                                                   'integer'
                                                                 ],
                                               'Calling-Station-Id' => [
                                                                         '31',
                                                                         'string'
                                                                       ],
                                               'Framed-Protocol' => [
                                                                      '7',
                                                                      'integer'
                                                                    ],
                                               'User-Name' => [
                                                                '1',
                                                                'string'
                                                              ],
                                               'User-Password' => [
                                                                    '2',
                                                                    'string'
                                                                  ],
                                               'NAS-Identifier' => [
                                                                     '32',
                                                                     'string'
                                                                   ],
                                               'Connect-Info' => [
                                                                   '77',
                                                                   'string'
                                                                 ],
                                               'NAS-IP-Address' => [
                                                                     '4',
                                                                     'ipaddr'
                                                                   ],
                                               'NAS-Port' => [
                                                               '5',
                                                               'integer'
                                                             ],
                                               'NAS-Port-Id' => [
                                                                  '87',
                                                                  'string'
                                                                ]
                                             },
                                   'rvsattr' => {
                                                  '2011' => {
                                                              '59' => [
                                                                        'Startup-Stamp',
                                                                        'integer'
                                                                      ],
                                                              '254' => [
                                                                         'Version',
                                                                         'string'
                                                                       ],
                                                              '60' => [
                                                                        'Ip-Host-Addr',
                                                                        'string'
                                                                      ],
                                                              '138' => [
                                                                         'Domain-Name',
                                                                         'string'
                                                                       ],
                                                              '255' => [
                                                                         'Product-ID',
                                                                         'string'
                                                                       ],
                                                              '26' => [
                                                                        'Connect-ID',
                                                                        'integer'
                                                                      ]
                                                            }
                                                },
                                   'rval' => {
                                               '6' => {
                                                        '2' => 'Framed-User'
                                                      },
                                               '61' => {
                                                         '15' => 'Ethernet'
                                                       },
                                               '7' => {
                                                        '1' => 'PPP'
                                                      }
                                             },
                                   'vsaval' => {}
                                 }, 'Net::Radius::Dictionary' ),
          'opts' => {
                      'identifier' => 66,
                      'authenticator' => 'S�\'Ve�B>�M/Z',
                      'dictionary' => [
                                        'minidict'
                                      ],
                      'secret' => 'br@5hu',
                      'slots' => 12,
                      'output' => 'huawei-me60-accreq',
                      'description' => 'Huawei Quidway® ME60 - Access-Request'
                    },
          'slots' => 12
        };
