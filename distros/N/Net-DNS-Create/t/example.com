#!/usr/bin/perl

my $localhost = '127.0.0.1';

domain 'example.com', {
    '@'                      => {     soa   => { primary_ns => 'ns1.example.com.',
                                                 rp_email   => 'some-email@example.com',
                                                 serial     => 1234,
                                                 refresh    => '8h',
                                                 retry      => '2h',
                                                 expire     => '4w',
                                                 min_ttl    => '1h' },
                                      ns    => [ 'ns1.example.com.', 'ns2.example.com.' ],
                                      a     => $localhost,
                                      mx    => { 0  => 'mail',
                                                 10 => 'smtp' },
                                      TXT   => ["v=spf1 mx -all",
                                                "another different text record",
                                                'Weird characters: "hello"<script>$$)(*&^%$#@!~`[]{}\\|:;"\',./<>?'."\0\t\n"] },
    'www'                    => { a     => $localhost,
                                  RP    => ['david@example.com', 'david.people'] },
    'david.people'           => { TXT   => 'For a good time call: 555-1212' },
    'bob.people'             => { TXT   => 'For a *great* time call: 555-1213' },
    'www2'                   => { cname => "www" },
    'www3'                   => { cname => "@" },
    'external'               => { cname => "external.example.net." },
    'mail'                   => { a     => $localhost },
    'smtp'                   => { a     => $localhost },
    'example._domainkey'     => { TXT   => "v=DKIM1; n=blah =20 Blah; g=*; k=rsa; p=THISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKE".
				           "YTHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKETHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOR".
					   "EALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAINKETHISISNOTAREALDOMAINKEYJUSTANEXAMPLENOREALLYBLAHBLAHBLAHDOMAINKEYDOMAINKEYDOMAI".
					   "NKEYTHISISNOTAREALDOMAINKEY" },
    '_adsp._domainkey'       => { TXT   => "dkim=all" },
    stuff                    => { a => $localhost },
    'more.stuff'             => { a => $localhost },
    'even.more.stuff'        => { a => $localhost },
    'tons.of.stuff'          => { a => $localhost },
    'ns1'                    => { a => $localhost },
    'ns2'                    => { a => $localhost },
    subdomain                => { ns => 'subdomain-ns.example.com.' },
    'round-robin'            => { a => [ '127.0.0.4', '127.0.0.5' ],
                                  rp => [ ['david@example.com', 'david.people'],
                                          [  'bob@example.com',   'bob.people'] ] },
    calendar                 => { a => $localhost },
    '_carddavs._tcp'         => { SRV   => { "calendar.example.com." => { port => 443 } } },
}, {
    # Another section. Anything in here overrides the previous sections
    mail                     => { a => '127.0.0.2' },
    '@'                      => { a => '127.0.0.3' }, # Doesn't stomp over @'s NS, SOA, MX, or TXT.
};
