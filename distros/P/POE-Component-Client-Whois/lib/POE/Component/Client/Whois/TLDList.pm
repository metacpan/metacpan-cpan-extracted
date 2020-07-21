package POE::Component::Client::Whois::TLDList;
$POE::Component::Client::Whois::TLDList::VERSION = '1.38';
#ABSTRACT: Determine the applicable Whois server for a given Top-level domain (TLD).

use strict;
use warnings;
use Data::Dumper;

my %data = (
          '.cy' => [
                     'WEB',
                     'http://www.nic.cy/nslookup/online_database.php'
                   ],
          '.su' => [
                     'whois.ripn.net'
                   ],
          '.nz' => [
                     'whois.srs.net.nz'
                   ],
          '.in' => [
                     'whois.registry.in'
                   ],
          '.cv' => [
                     'NONE'
                   ],
          '.ni' => [
                     'WEB',
                     'http://www.nic.ni/consulta.htm'
                   ],
          '.la' => [
                     'whois.nic.la'
                   ],
          '.co.za' => [
                        'whois.coza.net.za'
                      ],
          '.sv' => [
                     'WEB',
                     'http://www.uca.edu.sv/dns/'
                   ],
          '.pm' => [
                     'whois.nic.fr'
                   ],
          '.ar' => [
                     'WEB',
                     'http://www.nic.ar/'
                   ],
          '.ng' => [
                     'whois.register.net.ng'
                   ],
          '.ae' => [
                     'whois.aeda.net.ae'
                   ],
          '.jobs' => [
                       'jobswhois.verisign-grs.com'
                     ],
          '.edu.ru' => [
                         'whois.informika.ru'
                       ],
          '-nicat' => [
                        'whois.nic.at'
                      ],
          '.tt' => [
                     'WEB',
                     'http://www.nic.tt/cgi-bin/search.pl'
                   ],
          '-dk' => [
                     'whois.dk-hostmaster.dk'
                   ],
          '.mp' => [
                     'NONE'
                   ],
          '.info' => [
                       'whois.afilias.info'
                     ],
          '.ws' => [
                     'whois.samoanic.ws'
                   ],
          '.gov.uk' => [
                         'whois.ja.net'
                       ],
          '.police.uk' => [
                            'NONE'
                          ],
          '.ma' => [
                     'whois.iam.net.ma'
                   ],
          '.de.com' => [
                         'whois.centralnic.net'
                       ],
          '.pw' => [
                     'whois.nic.pw'
                   ],
          '.no.com' => [
                         'whois.centralnic.net'
                       ],
          '.td' => [
                     'NONE'
                   ],
          '.au' => [
                     'whois.ausregistry.net.au'
                   ],
          '.je' => [
                     'whois.je'
                   ],
          '.arpa' => [
                       'whois.iana.org'
                     ],
          '.gr' => [
                     'WEB',
                     'https://grweb.ics.forth.gr/Whois?lang=en'
                   ],
          '.e164.arpa' => [
                            'whois.ripe.net'
                          ],
          '.az' => [
                     'WEB',
                     'http://www.nic.az/AzCheck.htm'
                   ],
          '.se.net' => [
                         'whois.centralnic.net'
                       ],
          '.yt' => [
                     'whois.nic.yt'
                   ],
          '.uk.net' => [
                         'whois.centralnic.net'
                       ],
          '.vi' => [
                     'WEB',
                     'http://www.nic.vi/whoisform.htm'
                   ],
          '.mz' => [
                     'NONE'
                   ],
          '.ad' => [
                     'NONE'
                   ],
          '-arin' => [
                       'whois.arin.net'
                     ],
          '.wf' => [
                     'whois.nic.wf'
                   ],
          '.ua' => [
                     'whois.net.ua'
                   ],
          '.gov' => [
                      'whois.nic.gov'
                    ],
          '.lk' => [
                     'whois.nic.lk'
                   ],
          '.do' => [
                     'WEB',
                     'http://www.nic.do/whois-h.php3'
                   ],
          '.ls' => [
                     'WEB',
                     'http://www.co.ls/data/leo2.asp'
                   ],
          '.ye' => [
                     'NONE'
                   ],
          '.ki' => [
                     'WEB',
                     'http://www.ki/dns/'
                   ],
          '.tw' => [
                     'whois.twnic.net'
                   ],
          '.nc' => [
                     'whois.cctld.nc'
                   ],
          '.sk' => [
                     'whois.sk-nic.sk'
                   ],
          '.bm' => [
                     'WEB',
                     'http://207.228.133.14/cgi-bin/lansaweb?procfun+BMWHO+BMWHO2+WHO'
                   ],
          '-norid' => [
                        'whois.norid.no'
                      ],
          '.pk' => [
                     'WEB',
                     'http://www.pknic.net.pk/'
                   ],
          '.gg' => [
                     'whois.gg'
                   ],
          '.cd' => [
                     'whois.nic.cd'
                   ],
          '.lv' => [
                     'whois.nic.lv'
                   ],
          '.kg' => [
                     'whois.domain.kg'
                   ],
          '.fk' => [
                     'NONE'
                   ],
          '.vc' => [
                     'whois.afilias-grs.info'
                   ],
          '.so' => [
                     'NONE'
                   ],
          '.an' => [
                     'NONE'
                   ],
          '.sh' => [
                     'whois.nic.sh'
                   ],
          '.ee' => [
                     'whois.eenet.ee'
                   ],
          '.pg' => [
                     'NONE'
                   ],
          '.md' => [
                     'WEB',
                     'http://www.dns.md/wh1.php'
                   ],
          '.bs' => [
                     'WEB',
                     'http://www.nic.bs/cgi-bin/search.pl'
                   ],
          '.iq' => [
                     'NONE'
                   ],
          '.sl' => [
                     'whois.nic.sl'
                   ],
          '-sixxs' => [
                        'whois.sixxs.net'
                      ],
          '.ac.za' => [
                        'whois.ac.za'
                      ],
          '.fo' => [
                     'whois.ripe.net'
                   ],
          '.uk.co' => [
                        'whois.uk.co'
                      ],
          '.us' => [
                     'whois.nic.us'
                   ],
          '.cn' => [
                     'whois.cnnic.net.cn'
                   ],
          '.tp' => [
                     'whois.nic.tp'
                   ],
          '.bz' => [
                     'whois.afilias-grs.info'
                   ],
          '.tm' => [
                     'whois.nic.tm'
                   ],
          '.mod.uk' => [
                         'NONE'
                       ],
          '.british-library.uk' => [
                                     'NONE'
                                   ],
          '.zm' => [
                     'NONE'
                   ],
          '.br.com' => [
                         'whois.centralnic.net'
                       ],
          '.eu.com' => [
                         'whois.centralnic.net'
                       ],
          '.biz' => [
                      'whois.nic.biz'
                    ],
          '.mk' => [
                     'WEB',
                     'http://dns.marnet.net.mk/registar.php'
                   ],
          '.za.net' => [
                         'whois.za.net'
                       ],
          '.qc.com' => [
                         'whois.centralnic.net'
                       ],
          '.ai' => [
                     'whois.ai'
                   ],
          '-metu' => [
                       'whois.metu.edu.tr'
                     ],
          '.rw' => [
                     'WEB',
                     'http://www.nic.rw/cgi-bin/whoisrw.pl'
                   ],
          '.me' => [
                     'whois.meregistry.net'
                   ],
          '.mo' => [
                     'WEB',
                     'http://www.monic.net.mo/'
                   ],
          '.nu' => [
                     'whois.nic.nu'
                   ],
          '.yu' => [
                     'NONE'
                   ],
          '.gq' => [
                     'NONE'
                   ],
          '.pro' => [
                      'whois.registrypro.pro'
                    ],
          '.aq' => [
                     'NONE'
                   ],
          '.com' => [
                      'whois.crsnic.net'
                    ],
          '.dj' => [
                     'whois.domain.dj'
                   ],
          '-itnic' => [
                        'whois.nic.it'
                      ],
          '.travel' => [
                         'whois.nic.travel'
                       ],
          '.na' => [
                     'whois.na-nic.com.na'
                   ],
          '.vu' => [
                     'WEB',
                     'http://www.vunic.vu/whois.html'
                   ],
          '.kn' => [
                     'NONE'
                   ],
          '.uz' => [
                     'whois.cctld.uz'
                   ],
          '.st' => [
                     'whois.nic.st'
                   ],
          '-idnic' => [
                        'whois.idnic.net.id'
                      ],
          '.sz' => [
                     'NONE'
                   ],
          '.aero' => [
                       'whois.aero'
                     ],
          '.coop' => [
                       'whois.nic.coop'
                     ],
          '.jm' => [
                     'NONE'
                   ],
          '.ps' => [
                     'WEB',
                     'http://www.nic.ps/whois/whois.html'
                   ],
          '.ms' => [
                     'whois.nic.ms'
                   ],
          '.nr' => [
                     'WEB',
                     'http://www.cenpac.net.nr/dns/whois.html'
                   ],
          '.be' => [
                     'whois.dns.be'
                   ],
          '.pa' => [
                     'WEB',
                     'http://www.nic.pa/'
                   ],
          '.mv' => [
                     'NONE'
                   ],
          '.fj' => [
                     'whois.usp.ac.fj'
                   ],
          '.th' => [
                     'whois.thnic.net'
                   ],
          '-hst' => [
                      'whois.networksolutions.com'
                    ],
          '.gov.za' => [
                         'whois.gov.za'
                       ],
          '.hr' => [
                     'WEB',
                     'http://www.dns.hr/pretrazivanje.html'
                   ],
          '.name' => [
                       'whois.nic.name'
                     ],
          '.za.org' => [
                         'whois.za.org'
                       ],
          '.cz' => [
                     'whois.nic.cz'
                   ],
          '.parliament.uk' => [
                                'NONE'
                              ],
          '.gi' => [
                     'whois.afilias-grs.info'
                   ],
          '-tel' => [
                      'whois.nic.tel'
                    ],
          '.tg' => [
                     'WEB',
                     'http://www.nic.tg/'
                   ],
          '.lu' => [
                     'whois.dns.lu'
                   ],
          '.bh' => [
                     'NONE'
                   ],
          '.cc' => [
                     'whois.nic.cc'
                   ],
          '.gd' => [
                     'whois.adamsnames.tc'
                   ],
          '-ripn' => [
                       'whois.ripn.net'
                     ],
          '.in-addr.arpa' => [
                               'ARPA'
                             ],
          '.tv' => [
                     'whois.nic.tv'
                   ],
          '.ao' => [
                     'NONE'
                   ],
          '.mu' => [
                     'whois.nic.mu'
                   ],
          '.za.com' => [
                         'whois.centralnic.net'
                       ],
          '.aw' => [
                     'NONE'
                   ],
          '.bd' => [
                     'www.whois.com.bd'
                   ],
          '.mn' => [
                     'whois.afilias-grs.info'
                   ],
          '.hn' => [
                     'whois.afilias-grs.info'
                   ],
          '.pr' => [
                     'whois.nic.pr'
                   ],
          '-cn' => [
                     'whois.cnnic.net.cn'
                   ],
          '.by' => [
                     'WEB',
                     'http://www.tld.by/indexeng.html'
                   ],
          '-sgnic' => [
                        'whois.nic.net.sg'
                      ],
          '.it' => [
                     'whois.nic.it'
                   ],
          '.ch' => [
                     'whois.nic.ch'
                   ],
          '.cm' => [
                     'NONE'
                   ],
          '.al' => [
                     'NONE'
                   ],
          '.mr' => [
                     'NONE'
                   ],
          '.ci' => [
                     'www.nic.ci'
                   ],
          '.gl' => [
                     'NONE'
                   ],
          '.pf' => [
                     'NONE'
                   ],
          '.lr' => [
                     'NONE'
                   ],
          '.bt' => [
                     'WEB',
                     'http://www.nic.bt/'
                   ],
          '-mnt' => [
                      'whois.ripe.net'
                    ],
          '.tn' => [
                     'WEB',
                     'http://whois.ati.tn/'
                   ],
          '.im' => [
                     'whois.nic.im'
                   ],
          '.tel' => [
                      'whois.nic.tel'
                    ],
          '.cl' => [
                     'whois.nic.cl'
                   ],
          '.ly' => [
                     'whois.nic.ly'
                   ],
          '.om' => [
                     'WEB',
                     'http://www.omnic.om/onlineUser/WHOISLookup.jsp'
                   ],
          '.gu' => [
                     'WEB',
                     'http://gadao.gov.gu/domainsearch.htm'
                   ],
          '.fed.us' => [
                         'whois.nic.gov'
                       ],
          '.sy' => [
                     'NONE'
                   ],
          '.sj' => [
                     'NONE'
                   ],
          '-frnic' => [
                        'whois.nic.fr'
                      ],
          '.edu' => [
                      'whois.educause.net'
                    ],
          '-org' => [
                      'whois.networksolutions.com'
                    ],
          '.cx' => [
                     'whois.nic.cx'
                   ],
          '.gp' => [
                     'whois.nic.gp'
                   ],
          '.kh' => [
                     'NONE'
                   ],
          '.mil' => [
                      'NONE'
                    ],
          '.dz' => [
                     'WEB',
                     'https://www.nic.dz/'
                   ],
          '.ru' => [
                     'whois.ripn.net'
                   ],
          '.ug' => [
                     'www.registry.co.ug'
                   ],
          '.kz' => [
                     'whois.nic.kz'
                   ],
          '.mg' => [
                     'whois.nic.mg'
                   ],
          '.int' => [
                      'whois.iana.org'
                    ],
          '.ba' => [
                     'WEB',
                     'http://www.nic.ba/stream/whois/'
                   ],
          '.jpn.com' => [
                          'whois.centralnic.net'
                        ],
          '.vg' => [
                     'whois.adamsnames.tc'
                   ],
          '.km' => [
                     'NONE'
                   ],
          '.sr' => [
                     'whois.register.sr'
                   ],
          '.ga' => [
                     'NONE'
                   ],
          '-dom' => [
                      'whois.networksolutions.com'
                    ],
          '.tc' => [
                     'whois.adamsnames.tc'
                   ],
          '.tz' => [
                     'WEB',
                     'http://whois.tznic.or.tz/'
                   ],
          '.at' => [
                     'whois.nic.at'
                   ],
          '.co.pl' => [
                        'whois.co.pl'
                      ],
          '.bg' => [
                     'whois.register.bg'
                   ],
          '.lb' => [
                     'WEB',
                     'http://www.aub.edu.lb/lbdr/search.html'
                   ],
          '.mc' => [
                     'whois.ripe.net'
                   ],
          '.tr' => [
                     'whois.metu.edu.tr'
                   ],
          '.co' => [
                     'WEB',
                     'https://www.nic.co/'
                   ],
          '.mx' => [
                     'whois.nic.mx'
                   ],
          '.es' => [
                     'WEB',
                     'https://www.nic.es/'
                   ],
          '.ve' => [
                     'whois.nic.ve'
                   ],
          '.fi' => [
                     'whois.ficora.fi'
                   ],
          '.org' => [
                      'whois.publicinterestregistry.net'
                    ],
          '.asia' => [
                       'whois.nic.asia'
                     ],
          '.sn' => [
                     'whois.nic.sn'
                   ],
          '.sc' => [
                     'whois.afilias-grs.info'
                   ],
          '.uk.com' => [
                         'whois.centralnic.net'
                       ],
          '.bw' => [
                     'NONE'
                   ],
          '.bo' => [
                     'WEB',
                     'http://www.nic.bo/'
                   ],
          '.ec' => [
                     'WEB',
                     'http://www.nic.ec/whois/eng/whois.asp'
                   ],
          '.qa' => [
                     'NONE'
                   ],
          '.dk' => [
                     'whois.dk-hostmaster.dk'
                   ],
          '.cn.com' => [
                         'whois.centralnic.net'
                       ],
          '.tk' => [
                     'whois.dot.tk'
                   ],
          '.kw' => [
                     'WEB',
                     'http://www.kw/'
                   ],
          '.jet.uk' => [
                         'NONE'
                       ],
          '.va' => [
                     'whois.ripe.net'
                   ],
          '.kr' => [
                     'whois.nic.or.kr'
                   ],
          '-ar' => [
                     'whois.aunic.net'
                   ],
          '.nhs.uk' => [
                         'NONE'
                       ],
          '.cat' => [
                      'whois.cat'
                    ],
          '.vn' => [
                     'WEB',
                     'http://www.vnnic.vn/english/'
                   ],
          '.net' => [
                      'whois.crsnic.net'
                    ],
          '.pn' => [
                     'WEB',
                     'http://www.pitcairn.pn/PnRegistry/'
                   ],
          '-uynic' => [
                        'www.rau.edu.uy'
                      ],
          '.cg' => [
                     'WEB',
                     'http://www.nic.cg/cgi-bin/whois.pl'
                   ],
          '.zw' => [
                     'NONE'
                   ],
          '.hk' => [
                     'whois.hkdnr.net.hk'
                   ],
          '.mm' => [
                     'whois.nic.mm'
                   ],
          '.ro' => [
                     'whois.rotld.ro'
                   ],
          '.gm' => [
                     'whois.ripe.net'
                   ],
          '.ht' => [
                     'whois.nic.ht'
                   ],
          '.sd' => [
                     'NONE'
                   ],
          '.sg' => [
                     'whois.nic.net.sg'
                   ],
          '-lrms' => [
                       'whois.afilias.info'
                     ],
          '.ne' => [
                     'NONE'
                   ],
          '.ck' => [
                     'whois.nic.ck'
                   ],
          '.ac' => [
                     'whois.nic.ac'
                   ],
          '.fm' => [
                     'WEB',
                     'http://www.dot.fm/whois.html'
                   ],
          '.gb.com' => [
                         'whois.centralnic.net'
                       ],
          '.py' => [
                     'WEB',
                     'http://www.nic.py/consultas.html'
                   ],
          '.bj' => [
                     'whois.nic.bj'
                   ],
          '.er' => [
                     'NONE'
                   ],
          '.tf' => [
                     'whois.nic.tf'
                   ],
          '.eu' => [
                     'whois.eu'
                   ],
          '.ke' => [
                     'whois.kenic.or.ke'
                   ],
          '.kp' => [
                     'whois.kcce.kp'
                   ],
          '.ca' => [
                     'whois.cira.ca'
                   ],
          '.mq' => [
                     'whois.nic.mq'
                   ],
          '.za' => [
                     'NONE'
                   ],
          '.ge' => [
                     'WEB',
                     'http://whois.sanet.ge/'
                   ],
          '.jp' => [
                     'whois.jprs.jp'
                   ],
          '.gy' => [
                     'whois.registry.gy'
                   ],
          '.id' => [
                     'whois.idnic.net.id'
                   ],
          '.bl.uk' => [
                        'NONE'
                      ],
          '.bb' => [
                     'WEB',
                     'http://www.barbadosdomains.net/search_domain.php'
                   ],
          '-tw' => [
                     'whois.twnic.net'
                   ],
          '.hu.com' => [
                         'whois.centralnic.net'
                       ],
          '.tj' => [
                     'whois.nic.tj'
                   ],
          '.ml' => [
                     'NONE'
                   ],
          '.cu' => [
                     'WEB',
                     'http://www.nic.cu/consult.html'
                   ],
          '-il' => [
                     'whois.isoc.org.il'
                   ],
          '.mobi' => [
                       'whois.dotmobiregistry.net'
                     ],
          '.gt' => [
                     'WEB',
                     'http://www.gt/whois.htm'
                   ],
          '.gb' => [
                     'NONE'
                   ],
          '.fr' => [
                     'whois.nic.fr'
                   ],
          '.rs' => [
                     'WEB',
                     'http://www.nic.rs/en/whois'
                   ],
          '.gb.net' => [
                         'whois.centralnic.net'
                       ],
          '.ky' => [
                     'WEB',
                     'http://kynseweb.messagesecure.com/kywebadmin/'
                   ],
          '.bv' => [
                     'NONE'
                   ],
          '.mw' => [
                     'WEB',
                     'http://www.registrar.mw/'
                   ],
          '.af' => [
                     'whois.nic.af'
                   ],
          '.no' => [
                     'whois.norid.no'
                   ],
          '.to' => [
                     'whois.tonic.to'
                   ],
          '-is' => [
                     'whois.isnet.is'
                   ],
          '.as' => [
                     'whois.nic.as'
                   ],
          '.se.com' => [
                         'whois.centralnic.net'
                       ],
          '-6bone' => [
                        'whois.6bone.net'
                      ],
          '-afrinic' => [
                          'whois.afrinic.net'
                        ],
          '-ap' => [
                     'whois.apnic.net'
                   ],
          '.sa' => [
                     'saudinic.net.sa'
                   ],
          '-uanic' => [
                        'whois.com.ua'
                      ],
          '-nicir' => [
                        'whois.nic.ir'
                      ],
          '.io' => [
                     'whois.nic.io'
                   ],
          '-cknic' => [
                        'whois.nic.ck'
                      ],
          '.eu.org' => [
                         'whois.eu.org'
                       ],
          '.icnet.uk' => [
                           'NONE'
                         ],
          '.bn' => [
                     'NONE'
                   ],
          '.et' => [
                     'NONE'
                   ],
          '.lc' => [
                     'whois.afilias-grs.info'
                   ],
          '.ax' => [
                     'NONE'
                   ],
          '.museum' => [
                         'whois.museum'
                       ],
          '.hu' => [
                     'whois.nic.hu'
                   ],
          '.nls.uk' => [
                         'NONE'
                       ],
          '.eg' => [
                     'NONE'
                   ],
          '.cf' => [
                     'NONE'
                   ],
          '.is' => [
                     'whois.isnet.is'
                   ],
          '.de' => [
                     'de.whois-servers.net'
                   ],
          '.mh' => [
                     'NONE'
                   ],
          '-lacnic' => [
                         'whois.lacnic.net'
                       ],
          '.com.uy' => [
                         'WEB',
                         'https://nic.anteldata.com.uy/dns/'
                       ],
          '.li' => [
                     'whois.nic.li'
                   ],
          '.gn' => [
                     'NONE'
                   ],
          '.nf' => [
                     'whois.nic.nf'
                   ],
          '-kenic' => [
                        'whois.kenic.or.ke'
                      ],
          '.si' => [
                     'whois.arnes.si'
                   ],
          '.uy.com' => [
                         'whois.centralnic.net'
                       ],
          '.dm' => [
                     'whois.nic.dm'
                   ],
          '.br' => [
                     'whois.nic.br'
                   ],
          '.il' => [
                     'whois.isoc.org.il'
                   ],
          '.cr' => [
                     'WEB',
                     'http://www.nic.cr/niccr_publico/showRegistroDominiosScreen.do'
                   ],
          '-kg' => [
                     'whois.domain.kg'
                   ],
          '-ti' => [
                     'whois.telstra.net'
                   ],
          '.my' => [
                     'whois.mynic.net.my'
                   ],
          '.nl' => [
                     'whois.domain-registry.nl'
                   ],
          '.gh' => [
                     'WEB',
                     'http://www.nic.gh/customer/search_c.htm'
                   ],
          '-rotld' => [
                        'whois.rotld.ro'
                      ],
          '.sa.com' => [
                         'whois.centralnic.net'
                       ],
          '.sb' => [
                     'whois.nic.net.sb'
                   ],
          '.pl' => [
                     'whois.dns.pl'
                   ],
          '.us.com' => [
                         'whois.centralnic.net'
                       ],
          '-ripe' => [
                       'whois.ripe.net'
                     ],
          '.web.com' => [
                          'whois.centralnic.net'
                        ],
          '.am' => [
                     'whois.nic.am'
                   ],
          '.bi' => [
                     'WEB',
                     'http://www.nic.bi/Nic_search.asp'
                   ],
          '.bf' => [
                     'NONE'
                   ],
          '.ag' => [
                     'whois.nic.ag'
                   ],
          '.ru.com' => [
                         'whois.centralnic.net'
                       ],
          '.org.za' => [
                         'WEB',
                         'http://www.org.za/'
                       ],
          '.mt' => [
                     'WEB',
                     'https://www.nic.org.mt/dotmt/'
                   ],
          '.gs' => [
                     'whois.nic.gs'
                   ],
          '.uy' => [
                     'whois.nic.org.uy'
                   ],
          '.hm' => [
                     'whois.registry.hm'
                   ],
          '.ph' => [
                     'WEB',
                     'http://www.dot.ph/'
                   ],
          '.edu.cn' => [
                         'whois.edu.cn'
                       ],
          '.ie' => [
                     'whois.domainregistry.ie'
                   ],
          '-coop' => [
                       'whois.nic.coop'
                     ],
          '.ac.uk' => [
                        'whois.ja.net'
                      ],
          '.co.ca' => [
                        'whois.co.ca'
                      ],
          '.np' => [
                     'WEB',
                     'http://www.mos.com.np/domsearch.html'
                   ],
          '.se' => [
                     'whois.nic-se.se'
                   ],
          '.lt' => [
                     'whois.domreg.lt'
                   ],
          '.re' => [
                     'whois.nic.fr'
                   ],
          '.uk' => [
                     'whois.nic.uk'
                   ],
          '.jo' => [
                     'WEB',
                     'http://www.dns.jo/Whois.aspx'
                   ],
          '.tl' => [
                     'whois.nic.tl'
                   ],
          '-gandi' => [
                        'whois.gandi.net'
                      ],
          '.pt' => [
                     'whois.dns.pt'
                   ],
          '-cz' => [
                     'whois.nic.cz'
                   ],
          '.gf' => [
                     'whois.nplus.gf'
                   ],
          '.gw' => [
                     'NONE'
                   ],
          '.ir' => [
                     'whois.nic.ir'
                   ],
          '.pe' => [
                     'whois.nic.pe'
                   ],
          '.sm' => [
                     'whois.ripe.net'
                   ],
);

sub new {
  my $self = bless { data => \%data }, shift;
  return $self;
}

sub dump_tlds {
  my $self = shift;
  print STDERR Dumper( $self->{data} );
  return 1;
}

sub tld {
  my $self = shift;
  my $lookup = shift || return;
  $lookup =~ s/\.$//;

  unless ( $lookup =~ /\./ ) {
    foreach my $tld ( sort keys %{ $self->{data} } ) {
		  return @{ $self->{data}->{ $tld } }
        if $lookup =~ /\Q$tld\E$/i;
    }
  }
  else {
    my $query = lc $lookup;
    while ( $query ) {
      if ( exists $self->{data}->{".$query"} ) {
        return @{ $self->{data}->{".$query"} };
      }
      my @vals = split /\./, $query;
      shift @vals;
      $query = join '.', @vals;
    }
  }
  return 'NONE';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::Whois::TLDList - Determine the applicable Whois server for a given Top-level domain (TLD).

=head1 VERSION

version 1.38

=head1 SYNOPSIS

  use strict;
  use POE::Component::Client::Whois::TLDList;

  my $tldlist = POE::Component::Client::Whois::TLDList->new();

  my $whois_server = $tldlist->tld('foobar.com');

  $tldlist->dump_tlds();

=head1 DESCRIPTION

E::Component::Client::Whois::TLDList contains a list of top-level domains mapped to which Whois server has information for that domain.

=head1 CONSTRUCTOR

=over

=item C<new>

Returns a POE::Component::Client::Whois::TLDList object.

=back

=head1 METHODS

=over

=item C<tld>

Takes a domain or hostname and returns a list or an undef on failure. The list returned usually has the
reponsible Whois server as the first item in the list, but some TLDs do not have Whois servers.

If the first item in the list is 'NONE' then that TLD doesn't have a Whois server or the Whois is unknown.

If the first item in the list is 'WEB' then that TLD has a web interface only to query whois. The second item will usually be the web url to query.

If the first item in the list is 'ARPA' that that TLD is an .arpa address.

=item C<dump_tlds>

Uses Data::Dumper to dump TLD data to STDERR.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
