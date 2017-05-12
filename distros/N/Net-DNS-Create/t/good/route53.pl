$good = [
          {
            'name' => 'example.com.',
            'entries' => [
                           {
                             'type' => 'TXT',
                             'ttl' => 3600,
                             'action' => 'create',
                             'name' => '_adsp._domainkey.example.com.',
                             'records' => [
                                            '"dkim=all"'
                                          ]
                           },
                           {
                             'name' => 'more.stuff.example.com.',
                             'action' => 'create',
                             'type' => 'A',
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600
                           },
                           {
                             'name' => 'smtp.example.com.',
                             'action' => 'create',
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'type' => 'A'
                           },
                           {
                             'name' => 'mail.example.com.',
                             'ttl' => 3600,
                             'records' => [ '127.0.0.2' ],
                             'type' => 'A',
                             'action' => 'create'
                           },
                           {
                             'name' => 'www.example.com.',
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'type' => 'A',
                             'action' => 'create'
                           },
                           {
                             'ttl' => 3600,
                             'type' => 'TXT',
                             'action' => 'create',
                             'records' => [
                                            '"v=DKIM1; n=blah =20 Blah; g=*; k=rsa; p=THISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKEYTHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKETHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBL" "AHBLAHDOMAINKEYDOMAINKEYDOMAINKETHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKEYTHISISNOTAREALDOMAINKEY"'
                                          ],
                             'name' => 'example._domainkey.example.com.'
                           },
                           {
                             'type' => 'TXT',
                             'records' => [
                                            '"For a *great* time call: 555-1213"'
                                          ],
                             'action' => 'create',
                             'ttl' => 3600,
                             'name' => 'bob.people.example.com.'
                           },
                           {
                             'name' => 'david.people.example.com.',
                             'records' => [
                                            '"For a good time call: 555-1212"'
                                          ],
                             'ttl' => 3600,
                             'type' => 'TXT',
                             'action' => 'create'
                           },
                           {
                             'name' => 'even.more.stuff.example.com.',
                             'records' => [ '127.0.0.1' ],
                             'type' => 'A',
                             'ttl' => 3600,
                             'action' => 'create'
                           },
                           {
                             'action' => 'create',
                             'type' => 'A',
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'name' => 'ns2.example.com.'
                           },
                           {
                             'type' => 'NS',
                             'name' => 'subdomain.example.com.',
                             'action' => 'create',
                             'ttl' => 3600,
                             'records' => [
                                            'subdomain-ns.example.com.'
                                          ]
                           },
                           {
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'type' => 'A',
                             'action' => 'create',
                             'name' => 'stuff.example.com.'
                           },
                           {
                             'name' => 'www3.example.com.',
                             'value' => 'example.com.',
                             'type' => 'CNAME',
                             'ttl' => 3600,
                             'action' => 'create'
                           },
                           {
                             'action' => 'create',
                             'type' => 'SRV',
                             'ttl' => 3600,
                             'records' => [
                                            '0 0 443 calendar.example.com.'
                                          ],
                             'name' => '_carddavs._tcp.example.com.'
                           },
                           {
                             'type' => 'A',
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'action' => 'create',
                             'name' => 'ns1.example.com.'
                           },
                           {
                             'value' => 'www.example.com.',
                             'ttl' => 3600,
                             'type' => 'CNAME',
                             'action' => 'create',
                             'name' => 'www2.example.com.'
                           },
                           {
                             'records' => [ '127.0.0.1' ],
                             'ttl' => 3600,
                             'type' => 'A',
                             'action' => 'create',
                             'name' => 'calendar.example.com.'
                           },
                           {
                             'ttl' => 3600,
                             'value' => 'external.example.net.',
                             'type' => 'CNAME',
                             'action' => 'create',
                             'name' => 'external.example.com.'
                           },
                           {
                             'action' => 'create',
                             'ttl' => 3600,
                             'type' => 'TXT',
                             'name' => 'example.com.',
                             'records' => [
                                            '"Weird characters: \"hello\"\074script\076\044\044)(*\046\136\045\044\043\100\041\176\140\133\135\173\175\134\174:;\"\'\054.\057\074\076\077\000\011\012"',
                                            '"another different text record"',
                                            '"v=spf1 mx -all"',
                                          ]
                           },
                           {
                             'name' => 'example.com.',
                             'records' => [
                                            '0 mail.example.com.',
                                            '10 smtp.example.com.'
                                          ],
                             'ttl' => 3600,
                             'type' => 'MX',
                             'action' => 'create'
                           },
                           {
                             'name' => 'example.com.',
                             'action' => 'create',
                             'ttl' => 3600,
                             'records' => [ '127.0.0.3' ],
                             'type' => 'A'
                           },
                           {
                             'name' => 'tons.of.stuff.example.com.',
                             'action' => 'create',
                             'ttl' => 3600,
                             'records' => [ '127.0.0.1' ],
                             'type' => 'A'
                           },
                           {
                             'records' => [
                                            '127.0.0.4',
                                            '127.0.0.5'
                                          ],
                             'action' => 'create',
                             'type' => 'A',
                             'ttl' => 3600,
                             'name' => 'round-robin.example.com.'
                           },
                         ]
          }
        ];
