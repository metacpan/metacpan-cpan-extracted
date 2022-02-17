use Test2::V0;

use lib 't/lib';
use Test2::Tools::LicenseRegistry;

plan 1;

# Key is wikibase.label
# Value is WikiData identifier.

# Data sources (last checked 2021-08-09):
# <https://query.wikidata.org/#SELECT%20DISTINCT%20%3FitemLabel%20%3Fitem%20WHERE%20%7B%0A%20%20%3Fitem%20wdt%3AP31%2Fwdt%3AP2670%3F%2Fwdt%3AP279%2a%20wd%3AQ207621.%0A%20%20FILTER%20NOT%20EXISTS%20%7B%20%3Fitem%20wdt%3AP31%2Fwdt%3AP279%2a%20wd%3AQ7397.%20%7D%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%2Cen%22.%20%7D%0A%7D%20ORDER%20BY%20ASC%28%3FitemLabel%29>
# <https://query.wikidata.org/#SELECT%20DISTINCT%20%3FitemLabel%20%3Fitem%20WHERE%20%7B%0A%20%20%3Fitem%20wdt%3AP31%2Fwdt%3AP279%2a%20%7C%20wdt%3AP279%2a%20wd%3AQ7257461.%0A%20%20FILTER%20NOT%20EXISTS%20%7B%20%3Fitem%20wdt%3AP31%2Fwdt%3AP279%2a%20%7C%20wdt%3AP279%2a%20wd%3AQ207621.%20%7D%0A%20%20FILTER%20NOT%20EXISTS%20%7B%20%3Fitem%20wdt%3AP31%20wd%3AQ14204246.%20%7D%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%2Cen%2Cde%22.%20%7D%0A%7D%20ORDER%20BY%20ASC%28%3FitemLabel%29>

# TODO: explore if possible (and relevant) to include other kinds of licenses
# (filtering on all 13000 licensing exhausts the wikidata SPARQL endpoint)

like(
	license_org_metadata('wikidata'),
	hash {
		# software licenses (excluding software)
		field '1-clause BSD License' => 'Q19292556';
		field '2-clause BSD License' => 'Q18517294';
		field '3-clause BSD License' => 'Q18491847';
		field '4-clause BSD License' => 'Q21503790';

#		field 'AROS Public License' => 'Q4653881';
		field 'Academic Free License'   => 'Q337279';
		field 'Adaptive Public License' => 'Q4680711';

#		field 'Affero General Public License' => 'Q28130012';
		field 'Affero General Public License, version 1.0' => 'Q27017230';
		field 'Affero General Public License, version 1.0 or later' =>
			'Q54571707';
		field 'Affero General Public License, version 2.0' => 'Q54365943';

#		field 'Against DRM license' => 'Q1905513';
		field 'Aladdin Free Public License' => 'Q979794';

#		field 'Angband licence' => 'Q26701938';
#		field 'Anti 996 License' => 'Q63020872';
		field 'Apache License'                       => 'Q616526';
		field 'Apache Software License, Version 1.0' => 'Q26897902';
		field 'Apache Software License, Version 1.1' => 'Q17817999';
		field 'Apache Software License, Version 2.0' => 'Q13785927';
		field 'Apple Public Source License'          => 'Q621330';
		field 'Artistic License'                     => 'Q713244';
		field 'Artistic License 2.0'                 => 'Q14624826';
		field 'Attribution Assurance License'        => 'Q38364310';

#		field 'Avira Free AntiVirus' => 'Q53679891';
		field 'BSD licenses'                                  => 'Q191307';
		field 'Beerware'                                      => 'Q10249';
		field 'BitTorrent Open Source License'                => 'Q4918693';
		field 'Boost Software License'                        => 'Q2353141';
		field 'CC0'                                           => 'Q6938433';
		field 'CNRI portion of the multi-part Python License' => 'Q38365646';
		field 'CUA Office Public License'                     => 'Q38365770';
		field 'Carnegie Mellon University License'            => 'Q2939745';
		field 'CeCILL'                                        => 'Q1052189';

#		field 'Client access license' => 'Q1100998';
		field 'Code Project Open License'                   => 'Q5140041';
		field 'Common Development and Distribution License' => 'Q304628';
		field 'Common Development and Distribution License version 1.0' =>
			'Q26996811';
		field 'Common Development and Distribution License version 1.1' =>
			'Q26996804';
		field 'Common Public Attribution License' => 'Q1116195';
		field 'Common Public License'             => 'Q2477807';
		field
			'Computer Associates Trusted Open Source License, Version 1.1' =>
			'Q38365570';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic'
			=> 'Q28050835';

#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Korea' => 'Q58041147';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic'
			=> 'Q19068212';

#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Germany' => 'Q105295756';
#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Ireland' => 'Q105658155';
#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 United States' => 'Q107464247';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported'
			=> 'Q15643954';
		field 'Creative Commons Attribution-ShareAlike' => 'Q6905942';
		field 'Creative Commons Attribution-NonCommercial-ShareAlike' =>
			'Q6998997';

# WRONG		field 'Creative Commons Public Domain Mark' => 'Q7257361';
		field 'Cryptix General License' => 'Q5190781';

#		field 'Design Science License' => 'Q2352806';
#		field 'EPICS Open License' => 'Q27096218';
		field 'EU DataGrid Software License'  => 'Q38365944';
		field 'Eclipse Distribution License'  => 'Q26245522';
		field 'Eclipse Public License'        => 'Q1281977';
		field 'Eclipse Public License 1.0'    => 'Q55633170';
		field 'Eclipse Public License 2.0'    => 'Q55633295';
		field 'Educational Community License' => 'Q5341236';
		field 'Eiffel Forum License'          => 'Q17011832';

#		field 'Elastic License' => 'Q104835286';
		field 'Entessa Public License'        => 'Q38366115';
		field 'Erlang Public License'         => 'Q3731857';
		field 'European Union Public Licence' => 'Q1376919';
		field 'Expat license'                 => 'Q18526198';
		field 'Fair License'                  => 'Q22682017';

#		field 'Flora License' => 'Q5460320';
		field 'Frameworx License' => 'Q5477987';

#		field 'Fraunhofer FDK AAC Codec Library for Android license' => 'Q47524122';
#		field 'FreeBSD Documentation License' => 'Q2033808';
		field 'FreeBSD license' => 'Q90408476';

#		field 'GNAT Modified General Public License' => 'Q1486114';
		field 'GNU Affero General Public License'              => 'Q1131681';
		field 'GNU Affero General Public License, version 3.0' => 'Q27017232';
		field 'GNU Affero General Public License, version 3.0 or later' =>
			'Q27020062';
		field 'GNU Free Documentation License'          => 'Q22169';
		field 'GNU General Public License'              => 'Q7603';
		field 'GNU General Public License, version 1.0' => 'Q10513452';
		field 'GNU General Public License, version 1.0 or later' =>
			'Q27016750';
		field 'GNU General Public License, version 2.0' => 'Q10513450';
		field 'GNU General Public License, version 2.0 or later' =>
			'Q27016752';
		field
			'GNU General Public License, version 2.0 or later with library exception'
			=> 'Q89706542';
		field 'GNU General Public License, version 3.0' => 'Q10513445';
		field 'GNU General Public License, version 3.0 or later' =>
			'Q27016754';
		field 'GNU Lesser General Public License'              => 'Q192897';
		field 'GNU Lesser General Public License, version 2.1' => 'Q18534390';
		field 'GNU Lesser General Public License, version 2.1 or later' =>
			'Q27016757';
		field 'GNU Lesser General Public License, version 3.0' => 'Q18534393';
		field 'GNU Lesser General Public License, version 3.0 or later' =>
			'Q27016762';
		field 'GNU Library General Public License, version 2.0' =>
			'Q23035974';
		field 'GNU Library General Public License, version 2.0 or later' =>
			'Q27016756';
		field 'GPL font exception'    => 'Q5514182';
		field 'GPL linking exception' => 'Q1486447';

#		field 'German Free Software License' => 'Q5551105';
#		field 'Hacktivismo Enhanced-Source Software License Agreement' => 'Q5637395';
#		field 'Hamilton Laboratories software license' => 'Q65463196';
		field 'Historical Permission Notice and Disclaimer' => 'Q5773924';

#		field 'Honest Public License' => 'Q3139999';
		field 'IBM Public License' => 'Q288745';
		field 'IPA Font License'   => 'Q38366264';
		field 'ISC license'        => 'Q386474';

#		field 'ImageMagick License' => 'Q27676327';
		field 'Independent JPEG Group License' => 'Q106186423';

#		field 'Info-ZIP License' => 'Q105235524';
#		field 'Initial Developer\'s Public License' => 'Q11712557';
		field 'Intel Open Source License' => 'Q6043507';

#		field 'Interbase Public License' => 'Q3153096';
		field 'Jabber Open Source License' => 'Q1149006';

#		field 'JasPer License Version 2.0' => 'Q47524112';
#		field 'Java Research License' => 'Q6165015';
#		field 'Kopimi' => 'Q98341313';
#		field 'LPO' => 'Q5961707';
		field 'LaTeX Project Public License'               => 'Q1050635';
		field 'Libpng License'                             => 'Q6542418';
		field 'Licence Libre du Québec – Permissive'    => 'Q38493399';
		field 'Licence Libre du Québec – Réciprocité' => 'Q38490890';
		field 'Licence Libre du Québec – Réciprocité forte' =>
			'Q38493724';
		field 'Lucent Public License'        => 'Q6696468';
		field 'MIT No Attribution License'   => 'Q67538600';
		field 'MIT license'                  => 'Q334661';
		field 'Microsoft Public License'     => 'Q15477153';
		field 'Microsoft Reciprocal License' => 'Q1772828';

#		field 'Minecraft Mod Public License' => 'Q93043822';
		field 'MirOS Licence'                                => 'Q1951343';
		field 'Motosoto Open Source License'                 => 'Q38494497';
		field 'Mozilla Public License'                       => 'Q308915';
		field 'Mozilla Public License, version 1.0'          => 'Q26737738';
		field 'Mozilla Public License, version 1.1'          => 'Q26737735';
		field 'Mozilla Public License, version 2.0'          => 'Q25428413';
		field 'Mulan Permissive Software License, Version 1' => 'Q66563953';
		field 'Mulan Permissive Software License, Version 2' => 'Q99634430';
		field 'Multics License'                              => 'Q38494754';
		field 'NASA Open Source Agreement'                   => 'Q6952418';
		field 'NAUMEN Public License'                        => 'Q38495690';
		field 'NTP License'                                  => 'Q38495487';
		field 'Nethack General Public License'               => 'Q20764732';
		field 'Netscape Public License'                      => 'Q2306611';
		field 'Nokia Open Source License'                    => 'Q38495954';
		field 'Non-Profit Open Software License'             => 'Q38495282';

#		field 'Norwegian Licence for Open Government Data' => 'Q106835859';
		field 'OCLC Research Public License'   => 'Q38496210';
		field 'OSET Foundation Public License' => 'Q38496558';

#		field 'OSI-approved license' => 'Q1156659';
#		field 'Open Content License' => 'Q4398755';
		field 'Open Database License'               => 'Q1224853';
		field 'Open Group Test Suite License'       => 'Q38686558';
		field 'Open Software License'               => 'Q777520';
		field 'OpenLDAP Public License Version 2.8' => 'Q25273268';
		field 'OpenSSL License'                     => 'Q89948816';
		field 'PHP License'                         => 'Q376841';
		field 'PostgreSQL License'                  => 'Q18563589';

#		field 'Public Documentation License' => 'Q492916';
		field 'Public Domain Dedication and License v1.0' => 'Q24273512';
		field 'Python License 2.0'                        => 'Q5975028';
		field 'Python Software Foundation License 2.0'    => 'Q2600299';
		field 'Q Public License'                          => 'Q1396282';
		field 'RealNetworks Public Source License'        => 'Q7300815';
		field 'Reciprocal Public License'                 => 'Q7302458';
		field 'Ricoh Source Code Public License'          => 'Q7332330';
		field 'Ruby License'                              => 'Q3066722';

#		field 'SLUC' => 'Q7391010';
#		field 'Server Side Public License' => 'Q58531884';
		field 'Simple Public License' => 'Q38351460';
		field 'Sleepycat License'     => 'Q2294050';

#		field 'Spencer License 86' => 'Q97463778';
		field 'Standard ML of New Jersey License' => 'Q99635287';
		field 'SugarCRM Public License'           => 'Q3976707';

#		field 'Sun Community Source License' => 'Q7638252';
		field 'Sun Industry Standards Source License' => 'Q635577';
		field 'Sun Public License'                    => 'Q648252';
		field 'Sybase Open Watcom Public License'     => 'Q7659488';

#		field 'TAPR Open Hardware License' => 'Q7669334';
		field 'The MITRE Collaborative Virtual Workspace License' =>
			'Q38365796';
		field 'Unicode, Inc. License Agreement' => 'Q67145209';
		field 'Universal Permissive License'    => 'Q38685700';
		field 'University of Illinois/NCSA Open Source License' => 'Q2495855';
		field 'Unlicense' => 'Q21659044';

#		field 'Upstream Compatibility License' => 'Q48795302';
#		field 'Vim license' => 'Q43338605';
		field 'Vovida Software License Version 1.0' => 'Q38349857';
		field 'W3C Software Notice and License'     => 'Q3564577';
		field 'WTFPL'                               => 'Q152481';
		field 'X.Net, Inc. License'                 => 'Q38346089';
		field 'X11 license'                         => 'Q18526202';

#		field 'XCore Open Source License' => 'Q8041726';
		field 'XFree86 License'         => 'Q100375790';
		field 'Yahoo! Public License'   => 'Q16948289';
		field 'Zend license'            => 'Q85269786';
		field 'Zero-clause BSD License' => 'Q48271011';
		field 'Zope Public License'     => 'Q3780982';

#		field 'adware' => 'Q193345';
#		field 'commercial open-source software' => 'Q4229799';
#		field 'commercial software' => 'Q1340793';
#		field 'copyleft free software license' => 'Q5975031';
#		field 'copyleft license' => 'Q1139274';
		field 'curl license' => 'Q33042394';

#		field 'donationware' => 'Q10267';
#		field 'doujin-mark' => 'Q17229293';
		field 'eCos-2.0' => 'Q26904555';

#		field 'free software license' => 'Q3943414';
#		field 'freemium' => 'Q1444631';
#		field 'freeware' => 'Q178285';
		field 'gSOAP Public License' => 'Q3756289';

#		field 'gnuplot license' => 'Q103979882';
		field 'libtiff License' => 'Q105688056';

#		field 'license-free software' => 'Q6543028';
#		field 'nagware' => 'Q1195197';
#		field 'non-Copyfree software license' => 'Q27529879';
#		field 'open source license' => 'Q97044024';
#		field 'permissive free software license' => 'Q1437937';
#		field 'proprietary software' => 'Q218616';
#		field 'public domain equivalent license' => 'Q25047642';
#		field 'released into the public domain by the copyright holder' => 'Q98592850';
#		field 'retail software' => 'Q7316614';
#		field 'shareware' => 'Q185534';
#		field 'software license' => 'Q207621';
#		field 'source available license' => 'Q94920209';
#		field 'trial' => 'Q9361521';
#		field 'volume licensing' => 'Q4016359';
		field 'wxWindows Library License' => 'Q38347878';
		field 'zlib License'              => 'Q207243';

		# public licenses (excluding software licenses)
#		field 'UVM-Lizenz für freie Inhalte' => 'Q2471941';
		field 'Artistic License 1.0' => 'Q14624823';

#		field 'Attribution-NonCommercial-NoDerivs 2.5 Australia' => 'Q84436292';
#		field 'Attribution-NonCommercial-NoDerivs 3.0 Costa Rica' => 'Q102768546';
#		field 'Attribution-NonCommercial-NoDerivs 3.0 Spain' => 'Q77554954';
#		field 'CERN Open Hardware Licence' => 'Q1023365';
#		field 'Copyheart' => 'Q5169203';
		field 'Creative Commons Attribution' => 'Q6905323';

#		field 'Creative Commons Attribution 3.0 IGO' => 'Q26259495';
#		field 'Creative Commons Attribution 1.0 Finland' => 'Q75446635';
		field 'Creative Commons Attribution 1.0 Generic' => 'Q30942811';

#		field 'Creative Commons Attribution 1.0 Israel' => 'Q75446609';
#		field 'Creative Commons Attribution 1.0 Netherlands' => 'Q75445499';
#		field 'Creative Commons Attribution 2.0 Australia' => 'Q75452310';
#		field 'Creative Commons Attribution 2.0 Austria' => 'Q75450165';
#		field 'Creative Commons Attribution 2.0 Belgium' => 'Q75457467';
#		field 'Creative Commons Attribution 2.0 Brazil' => 'Q75457506';
#		field 'Creative Commons Attribution 2.0 Canada' => 'Q75460106';
#		field 'Creative Commons Attribution 2.0 Chile' => 'Q75460149';
#		field 'Creative Commons Attribution 2.0 Croatia' => 'Q75474094';
#		field 'Creative Commons Attribution 2.0 France' => 'Q75470422';
		field 'Creative Commons Attribution 2.0 Generic' => 'Q19125117';

#		field 'Creative Commons Attribution 2.0 Germany' => 'Q75466259';
#		field 'Creative Commons Attribution 2.0 Italy' => 'Q75475677';
#		field 'Creative Commons Attribution 2.0 Japan' => 'Q75477775';
#		field 'Creative Commons Attribution 2.0 Netherlands' => 'Q75476747';
#		field 'Creative Commons Attribution 2.0 Poland' => 'Q75486069';
#		field 'Creative Commons Attribution 2.0 South Africa' => 'Q75488238';
#		field 'Creative Commons Attribution 2.0 South Korea' => 'Q44282633';
#		field 'Creative Commons Attribution 2.0 Spain' => 'Q75470365';
#		field 'Creative Commons Attribution 2.0 Taiwan' => 'Q75487055';
#		field 'Creative Commons Attribution 2.0 UK: England & Wales' => 'Q63241773';
#		field 'Creative Commons Attribution 2.1 Australia' => 'Q75894680';
#		field 'Creative Commons Attribution 2.1 Japan' => 'Q26116436';
#		field 'Creative Commons Attribution 2.1 Spain' => 'Q75894644';
#		field 'Creative Commons Attribution 2.5 Argentina' => 'Q75491630';
#		field 'Creative Commons Attribution 2.5 Australia' => 'Q75494411';
#		field 'Creative Commons Attribution 2.5 Brazil' => 'Q75501683';
#		field 'Creative Commons Attribution 2.5 Bulgaria' => 'Q75500112';
#		field 'Creative Commons Attribution 2.5 Canada' => 'Q75504835';
#		field 'Creative Commons Attribution 2.5 China Mainland' => 'Q75434631';
#		field 'Creative Commons Attribution 2.5 Columbia' => 'Q75663969';
#		field 'Creative Commons Attribution 2.5 Croatia' => 'Q75706881';
#		field 'Creative Commons Attribution 2.5 Denmark' => 'Q75665696';
		field 'Creative Commons Attribution 2.5 Generic' => 'Q18810333';

#		field 'Creative Commons Attribution 2.5 Hungary' => 'Q75759387';
#		field 'Creative Commons Attribution 2.5 India' => 'Q75443434';
#		field 'Creative Commons Attribution 2.5 Israel' => 'Q75759731';
#		field 'Creative Commons Attribution 2.5 Italy' => 'Q75760479';
#		field 'Creative Commons Attribution 2.5 Macedonia' => 'Q75761383';
#		field 'Creative Commons Attribution 2.5 Malaysia' => 'Q75762784';
#		field 'Creative Commons Attribution 2.5 Malta' => 'Q75761779';
#		field 'Creative Commons Attribution 2.5 Mexico' => 'Q75762418';
#		field 'Creative Commons Attribution 2.5 Netherlands' => 'Q75763101';
#		field 'Creative Commons Attribution 2.5 Peru' => 'Q75764151';
#		field 'Creative Commons Attribution 2.5 Poland' => 'Q75764470';
#		field 'Creative Commons Attribution 2.5 Portugal' => 'Q75764895';
#		field 'Creative Commons Attribution 2.5 Slovenia' => 'Q75766316';
#		field 'Creative Commons Attribution 2.5 South Africa' => 'Q75767606';
#		field 'Creative Commons Attribution 2.5 Spain' => 'Q75705948';
#		field 'Creative Commons Attribution 2.5 Sweden' => 'Q27940776';
#		field 'Creative Commons Attribution 2.5 Switzerland' => 'Q75506669';
#		field 'Creative Commons Attribution 2.5 Taiwan' => 'Q75767185';
#		field 'Creative Commons Attribution 2.5 UK: Scotland' => 'Q75765287';
#		field 'Creative Commons Attribution 3.0 Australia' => 'Q52555753';
#		field 'Creative Commons Attribution 3.0 Austria' => 'Q75768706';
#		field 'Creative Commons Attribution 3.0 Brazil' => 'Q75770766';
#		field 'Creative Commons Attribution 3.0 Chile' => 'Q75771874';
#		field 'Creative Commons Attribution 3.0 China Mainland' => 'Q75779562';
#		field 'Creative Commons Attribution 3.0 Costa Rica' => 'Q75789929';
#		field 'Creative Commons Attribution 3.0 Croatia' => 'Q75776014';
#		field 'Creative Commons Attribution 3.0 Czech Republic' => 'Q67918154';
#		field 'Creative Commons Attribution 3.0 Ecuador' => 'Q75850366';
#		field 'Creative Commons Attribution 3.0 Egypt' => 'Q75850832';
#		field 'Creative Commons Attribution 3.0 Estonia' => 'Q75850813';
#		field 'Creative Commons Attribution 3.0 France' => 'Q75775714';
#		field 'Creative Commons Attribution 3.0 Germany' => 'Q62619894';
#		field 'Creative Commons Attribution 3.0 Greece' => 'Q75851799';
#		field 'Creative Commons Attribution 3.0 Guatemala' => 'Q75852313';
#		field 'Creative Commons Attribution 3.0 Hong Kong' => 'Q75779905';
#		field 'Creative Commons Attribution 3.0 Ireland' => 'Q75852938';
#		field 'Creative Commons Attribution 3.0 Italy' => 'Q75776487';
#		field 'Creative Commons Attribution 3.0 Luxembourg' => 'Q75853187';
#		field 'Creative Commons Attribution 3.0 Netherlands' => 'Q53859967';
#		field 'Creative Commons Attribution 3.0 New Zealand' => 'Q75853514';
#		field 'Creative Commons Attribution 3.0 Norway' => 'Q75853549';
#		field 'Creative Commons Attribution 3.0 Philippines' => 'Q75856699';
#		field 'Creative Commons Attribution 3.0 Poland' => 'Q75777688';
#		field 'Creative Commons Attribution 3.0 Portugal' => 'Q75854323';
#		field 'Creative Commons Attribution 3.0 Puerto Rico' => 'Q75857518';
#		field 'Creative Commons Attribution 3.0 Romania' => 'Q75858169';
#		field 'Creative Commons Attribution 3.0 Serbia' => 'Q75859019';
#		field 'Creative Commons Attribution 3.0 Singapore' => 'Q75859751';
#		field 'Creative Commons Attribution 3.0 South Africa' => 'Q76631753';
#		field 'Creative Commons Attribution 3.0 Spain' => 'Q75775133';
#		field 'Creative Commons Attribution 3.0 Switzerland' => 'Q75771320';
#		field 'Creative Commons Attribution 3.0 Taiwan' => 'Q75778801';
#		field 'Creative Commons Attribution 3.0 Thailand' => 'Q75866892';
#		field 'Creative Commons Attribution 3.0 Uganda' => 'Q75882470';
#		field 'Creative Commons Attribution 3.0 United States' => 'Q18810143';
		field 'Creative Commons Attribution 3.0 Unported' => 'Q14947546';

#		field 'Creative Commons Attribution 3.0 Vietnam' => 'Q75889409';
		field 'Creative Commons Attribution 4.0 International' => 'Q20007257';
		field 'Creative Commons Attribution-NoDerivatives'     => 'Q6999319';
		field 'Creative Commons Attribution-NoDerivs 1.0 Generic' =>
			'Q47008966';
		field 'Creative Commons Attribution-NoDerivs 2.0 Generic' =>
			'Q35254645';

#		field 'Creative Commons Attribution-NoDerivs 2.0 UK: England & Wales' => 'Q63241854';
		field 'Creative Commons Attribution-NoDerivs 2.5 Generic' =>
			'Q18810338';

#		field 'Creative Commons Attribution-NoDerivs 3.0 Germany' => 'Q108002236';
#		field 'Creative Commons Attribution-NoDerivs 3.0 Taiwan' => 'Q105699164';
		field 'Creative Commons Attribution-NoDerivs 3.0 Unported' =>
			'Q18810160';
		field 'Creative Commons Attribution-NoDerivs 4.0 International' =>
			'Q36795408';
		field 'Creative Commons Attribution-NonCommercial' => 'Q6936496';
		field 'Creative Commons Attribution-NonCommercial 1.0 Generic' =>
			'Q44283370';
		field 'Creative Commons Attribution-NonCommercial 2.0 Generic' =>
			'Q44128984';

#		field 'Creative Commons Attribution-NonCommercial 2.1 Japan' => 'Q107673639';
		field 'Creative Commons Attribution-NonCommercial 2.5 Generic' =>
			'Q19113746';

#		field 'Creative Commons Attribution-NonCommercial 3.0 Germany' => 'Q108002180';
#		field 'Creative Commons Attribution-NonCommercial 3.0 Spain' => 'Q80230469';
		field 'Creative Commons Attribution-NonCommercial 3.0 Unported' =>
			'Q18810331';
		field
			'Creative Commons Attribution-NonCommercial 4.0 International' =>
			'Q34179348';
		field 'Creative Commons Attribution-NonCommercial-NoDerivatives' =>
			'Q6937225';

#		field 'Creative Commons Attribution-NonCommercial-NoDerivatives 3.0 United States' => 'Q96200688';
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 1.0 Generic'
			=> 'Q47008926';

#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 France' => 'Q104708274';
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic'
			=> 'Q47008927';

#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 UK: England & Wales' => 'Q56299316';
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Generic'
			=> 'Q19068204';

#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Portugal' => 'Q42172282';
#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Spain' => 'Q77660706';
#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 France' => 'Q23006354';
#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Germany' => 'Q108002189';
#		field 'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 IGO' => 'Q76448905';
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported'
			=> 'Q19125045';
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 4.0 International'
			=> 'Q24082749';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic'
			=> 'Q47008954';

#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 France' => 'Q94507369';
#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 UK: England & Wales' => 'Q63241094';
#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Italy' => 'Q65096132';
#		field 'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Switzerland' => 'Q96473808';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International'
			=> 'Q42553662';

#		field 'Creative Commons Attribution-NonCommercial-ShareAlive 3.0 IGO' => 'Q106453388';
#		field 'Creative Commons Attribution-Share Alike 2.5 Argentina' => 'Q99239269';
#		field 'Creative Commons Attribution-Share Alike 2.5 Australia' => 'Q99239530';
#		field 'Creative Commons Attribution-Share Alike 2.5 Brazil' => 'Q99239977';
#		field 'Creative Commons Attribution-Share Alike 2.5 Bulgaria' => 'Q99239903';
#		field 'Creative Commons Attribution-Share Alike 2.5 China Mainland' => 'Q99240158';
#		field 'Creative Commons Attribution-Share Alike 2.5 Colombia' => 'Q99240246';
#		field 'Creative Commons Attribution-Share Alike 2.5 Croatia' => 'Q99240535';
#		field 'Creative Commons Attribution-Share Alike 2.5 Denmark' => 'Q99240336';
#		field 'Creative Commons Attribution-Share Alike 2.5 India' => 'Q99240684';
#		field 'Creative Commons Attribution-Share Alike 2.5 Israel' => 'Q99240616';
#		field 'Creative Commons Attribution-Share Alike 2.5 Macedonia' => 'Q99437988';
#		field 'Creative Commons Attribution-Share Alike 2.5 Malaysia' => 'Q99438269';
#		field 'Creative Commons Attribution-Share Alike 2.5 Malta' => 'Q99438077';
#		field 'Creative Commons Attribution-Share Alike 2.5 Mexico' => 'Q99438138';
#		field 'Creative Commons Attribution-Share Alike 2.5 Peru' => 'Q99438515';
#		field 'Creative Commons Attribution-Share Alike 2.5 Portugal' => 'Q99438743';
#		field 'Creative Commons Attribution-Share Alike 2.5 Slovenia' => 'Q99438751';
#		field 'Creative Commons Attribution-Share Alike 2.5 South Africa' => 'Q99438757';
#		field 'Creative Commons Attribution-Share Alike 2.5 Spain' => 'Q99240437';
#		field 'Creative Commons Attribution-Share Alike 2.5 Switzerland' => 'Q99240068';
#		field 'Creative Commons Attribution-Share Alike 2.5 Taiwan' => 'Q99438755';
#		field 'Creative Commons Attribution-Share Alike 2.5 UK: Scotland' => 'Q99438747';
#		field 'Creative Commons Attribution-Share Alike 3.0 Brazil' => 'Q98755369';
#		field 'Creative Commons Attribution-Share Alike 3.0 China Mainland' => 'Q99458406';
#		field 'Creative Commons Attribution-Share Alike 3.0 Croatia' => 'Q99459365';
#		field 'Creative Commons Attribution-Share Alike 3.0 Ecuador' => 'Q99458819';
#		field 'Creative Commons Attribution-Share Alike 3.0 Greece' => 'Q99457707';
#		field 'Creative Commons Attribution-Share Alike 3.0 Guatemala' => 'Q99459010';
#		field 'Creative Commons Attribution-Share Alike 3.0 Hong Kong' => 'Q99459076';
#		field 'Creative Commons Attribution-Share Alike 3.0 New Zealand' => 'Q99438798';
#		field 'Creative Commons Attribution-Share Alike 3.0 Philippines' => 'Q99460006';
#		field 'Creative Commons Attribution-Share Alike 3.0 Portugal' => 'Q99460272';
#		field 'Creative Commons Attribution-Share Alike 3.0 Puerto Rico' => 'Q99460154';
#		field 'Creative Commons Attribution-Share Alike 3.0 Serbia' => 'Q98755344';
#		field 'Creative Commons Attribution-Share Alike 3.0 Singapore' => 'Q99460356';
#		field 'Creative Commons Attribution-Share Alike 3.0 Switzerland' => 'Q99457378';
#		field 'Creative Commons Attribution-Share Alike 3.0 Taiwan' => 'Q98960995';
#		field 'Creative Commons Attribution-Share Alike 3.0 Thailand' => 'Q99460411';
#		field 'Creative Commons Attribution-ShareAlike 1.0 Finland' => 'Q76767348';
		field 'Creative Commons Attribution-ShareAlike 1.0 Generic' =>
			'Q47001652';

#		field 'Creative Commons Attribution-ShareAlike 1.0 Israel' => 'Q76769447';
#		field 'Creative Commons Attribution-ShareAlike 1.0 Netherlands' => 'Q77014037';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Australia' => 'Q77131257';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Austria' => 'Q77021108';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Belgium' => 'Q77132386';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Brazil' => 'Q77133402';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Canada' => 'Q77135172';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Chile' => 'Q77136299';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Croatia' => 'Q77361415';
#		field 'Creative Commons Attribution-ShareAlike 2.0 France' => 'Q77355872';
		field 'Creative Commons Attribution-ShareAlike 2.0 Generic' =>
			'Q19068220';

#		field 'Creative Commons Attribution-ShareAlike 2.0 Germany' => 'Q77143083';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Italy' => 'Q77362254';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Japan' => 'Q77363039';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Netherlands' => 'Q77363856';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Poland' => 'Q77364488';
#		field 'Creative Commons Attribution-ShareAlike 2.0 South Africa' => 'Q77365530';
#		field 'Creative Commons Attribution-ShareAlike 2.0 South Korea' => 'Q44282641';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Spain' => 'Q77352646';
#		field 'Creative Commons Attribution-ShareAlike 2.0 Taiwan' => 'Q77364872';
#		field 'Creative Commons Attribution-ShareAlike 2.0 UK: England & Wales' => 'Q77365183';
#		field 'Creative Commons Attribution-ShareAlike 2.1 Australia' => 'Q77366066';
#		field 'Creative Commons Attribution-ShareAlike 2.1 Japan' => 'Q77367349';
#		field 'Creative Commons Attribution-ShareAlike 2.1 Spain' => 'Q77366576';
#		field 'Creative Commons Attribution-ShareAlike 2.5 Canada' => 'Q24331618';
		field 'Creative Commons Attribution-ShareAlike 2.5 Generic' =>
			'Q19113751';

#		field 'Creative Commons Attribution-ShareAlike 2.5 Hungary' => 'Q98755330';
#		field 'Creative Commons Attribution-ShareAlike 2.5 Italy' => 'Q98929925';
#		field 'Creative Commons Attribution-ShareAlike 2.5 Netherlands' => 'Q18199175';
#		field 'Creative Commons Attribution-ShareAlike 2.5 Poland' => 'Q98755337';
#		field 'Creative Commons Attribution-ShareAlike 2.5 Sweden' => 'Q15914252';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Australia' => 'Q86239208';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Austria' => 'Q80837139';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Chile' => 'Q99457535';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Costa Rica' => 'Q99458659';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Czech Republic' => 'Q98755321';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Estonia' => 'Q86239559';
#		field 'Creative Commons Attribution-ShareAlike 3.0 France' => 'Q86240326';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Germany' => 'Q42716613';
#		field 'Creative Commons Attribution-ShareAlike 3.0 IGO' => 'Q56292840';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Ireland' => 'Q99459488';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Italy' => 'Q98755364';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Luxembourg' => 'Q86240624';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Netherlands' => 'Q18195572';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Norway' => 'Q63340742';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Poland' => 'Q80837607';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Romania' => 'Q86241082';
#		field 'Creative Commons Attribution-ShareAlike 3.0 South Africa' => 'Q99460515';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Spain' => 'Q86239991';
#		field 'Creative Commons Attribution-ShareAlike 3.0 Uganda' => 'Q99460475';
#		field 'Creative Commons Attribution-ShareAlike 3.0 United States' => 'Q18810341';
		field 'Creative Commons Attribution-ShareAlike 3.0 Unported' =>
			'Q14946043';

#		field 'Creative Commons Attribution-ShareAlike 3.0 Vietnam' => 'Q99460484';
		field 'Creative Commons Attribution-ShareAlike 4.0 International' =>
			'Q18199165';
		field 'Creative Commons NonCommercial'     => 'Q65071627';
		field 'Creative Commons Sampling Plus 1.0' => 'Q26913038';
		field 'Creative Commons ShareAlike 1.0'    => 'Q75209430';

#		field 'Creative Commons jurisdiction port' => 'Q5183504';
		field 'Creative Commons license' => 'Q284742';

#		field 'Data licence Germany - Zero - Version 2.0' => 'Q56064789';
#		field 'Database Contents License' => 'Q96393884';
#		field 'Dominion Rules Licence' => 'Q5291073';
#		field 'FSF-approved license' => 'Q106916980';
#		field 'Free Art License' => 'Q152332';
		field 'GNU Free Documentation License, version 1.1' => 'Q26921685';
		field 'GNU Free Documentation License, version 1.1 or later' =>
			'Q50829096';

#		field 'GNU Free Documentation License, version 1.1 or later with invariants' => 'Q103979227';
#		field 'GNU Free Documentation License, version 1.1 or later with no invariants' => 'Q103979229';
#		field 'GNU Free Documentation License, version 1.1 with invariants' => 'Q103979163';
#		field 'GNU Free Documentation License, version 1.1 with no invariants' => 'Q103979171';
		field 'GNU Free Documentation License, version 1.2' => 'Q26921686';
		field 'GNU Free Documentation License, version 1.2 or later' =>
			'Q50829104';

#		field 'GNU Free Documentation License, version 1.2 or later with invariants' => 'Q103891130';
#		field 'GNU Free Documentation License, version 1.2 with invariants' => 'Q103891106';
#		field 'GNU Free Documentation License, version 1.2 with no invariants' => 'Q103979695';
		field 'GNU Free Documentation License, version 1.3' => 'Q26921691';
		field 'GNU Free Documentation License, version 1.3 or later' =>
			'Q27019786';

#		field 'GNU Free Documentation License, version 1.3 or later with invariants' => 'Q103979768';
#		field 'GNU Free Documentation License, version 1.3 or later with no invariants' => 'Q103891115';
#		field 'GNU Free Documentation License, version 1.3 with invariants' => 'Q103891111';
#		field 'GNU Free Documentation License, version 1.3 with no invariants' => 'Q103979743';
#		field 'GUST Font License' => 'Q99675272';
#		field 'Game System License' => 'Q5519899';
#		field 'Giftware' => 'Q10289473';
#		field 'Government Open Data License - India' => 'Q99891295';
#		field 'Government Website Open Information Announcement' => 'Q99659043';
#		field 'Government of Japan Standard Terms of Use' => 'Q22131381';
#		field 'Government of Japan Standard Terms of Use (Version 1.0)' => 'Q104709222';
#		field 'Government of Japan Standard Terms of Use (Version 1.1)' => 'Q104709242';
#		field 'Government of Japan Standard Terms of Use (Version 2.0)' => 'Q104709225';
#		field 'Italian Open Data License' => 'Q16566743';
#		field 'Italian Open Data License 1.0' => 'Q26805816';
#		field 'Italian Open Data License 2.0' => 'Q26805818';
		field 'MPICH2 license' => 'Q17070027';

#		field 'Matplotlib license' => 'Q30222888';
#		field 'Mexico City Open Government License' => 'Q57487793';
#		field 'Non-Commercial Government Licence 2.0' => 'Q58337120';
#		field 'Norwegian Licence for Open Government Data 1.0' => 'Q18632926';
#		field 'Norwegian Licence for Open Government Data 2.0' => 'Q106835855';
#		field 'Oireachtas (Open Data) PSI Licence' => 'Q100534948';
#		field 'Open Audio License' => 'Q627693';
#		field 'Open Data Commons Attribution License' => 'Q30940585';
#		field 'Open Directory License' => 'Q4045888';
#		field 'Open Game License v1.0' => 'Q1752744';
#		field 'Open Game License v1.0a' => 'Q100878500';
#		field 'Open Government Data License' => 'Q47001673';
#		field 'Open Government Licence' => 'Q17016921';
#		field 'Open Government Licence - Canada' => 'Q56419952';
#		field 'Open Government Licence v1.0' => 'Q99891660';
#		field 'Open Government Licence v2.0' => 'Q99891692';
#		field 'Open Government Licence v3.0' => 'Q99891702';
#		field 'Open Hardware License' => 'Q7096068';
#		field 'Open Licence 1.0' => 'Q80938815';
#		field 'Open Licence 2.0' => 'Q80939351';
#		field 'Open License' => 'Q3238028';
#		field 'Open Parliament Licence' => 'Q82682924';
#		field 'Open Publication License' => 'Q1412537';
#		field 'Open Web Foundation Agreement, Version 0.9' => 'Q28554579';
		field 'SIL Open Font License' => 'Q1150837';
		field 'Sampling 1.0'          => 'Q100509915';

#		field 'Simputer General Public License' => 'Q7521185';
#		field 'data copyright license' => 'Q51754273';
#		field 'deprecated Creative Commons license' => 'Q100508534';
#		field 'free license' => 'Q196294';
#		field 'public license' => 'Q7257461';

		# default summaries
		field 'a BSD-style license'  => 'Q191307';
		field 'an MIT-style license' => 'Q334661';

		# historical caption until 2021-08-09 (em-dash instead of dash)
#		field 'Creative Commons Attribution–NonCommercial-ShareAlike' => 'Q6998997';

		end();
	},
	'coverage of Creative Commons Public licenses'
);

done_testing;
