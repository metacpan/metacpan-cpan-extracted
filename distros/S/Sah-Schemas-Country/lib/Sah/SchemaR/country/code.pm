## no critic: TestingAndDebugging::RequireStrict
package Sah::SchemaR::country::code;

our $DATE = '2023-08-07'; # DATE
our $VERSION = '0.009'; # VERSION

our $rschema = do{my$var={base=>"str",clsets_after_base=>[{description=>"\nAccept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.\n\nCode will be converted to lowercase.\n\n",examples=>[{valid=>0,value=>""},{valid=>1,validated_value=>"id",value=>"ID"},{valid=>1,validated_value=>"idn",value=>"IDN"},{valid=>0,value=>"xx"},{valid=>0,value=>"xxx"}],in=>["hu","tv","ca","pk","by","tf","pn","tm","bl","ie","pm","tn","lt","pf","tk","cg","ls","ga","mg","mq","ph","jp","fr","dm","yt","ax","as","bb","th","sr","kg","dk","us","ma","ee","at","gg","io","gq","ec","lv","jo","qa","ps","bi","sa","pt","mr","vn","tt","lk","ro","id","gr","kr","sg","am","sj","af","um","je","nf","bw","fj","re","cr","mx","na","gs","aq","gt","il","ag","ug","tr","sh","om","ua","mt","pr","rw","ru","be","ng","ms","vg","sn","fm","sk","cx","sm","fk","bo","sv","la","va","kn","zw","ch","mv","lr","gn","mf","mm","bd","mn","bz","gf","gm","mk","km","tj","ar","pa","ss","cn","tg","ck","kh","gh","st","mh","nr","cv","dj","pg","sx","cm","cf","zm","ci","sl","de","rs","sy","ad","uz","az","mu","mw","to","gw","gu","lc","vc","kw","nz","np","nc","ki","in","gi","do","eh","br","sb","pe","im","cu","cw","es","hr","jm","dz","cl","cy","ba","et","si","ae","bg","bq","fi","ne","ye","tc","gb","ao","it","gl","tz","gy","ve","td","bj","ky","is","no","ml","my","bh","ni","lu","vu","cz","er","cd","se","mc","ht","ai","py","au","aw","pl","bn","mz","md","mp","fo","cc","bv","so","kp","ws","li","vi","kz","nu","bf","bm","tl","gp","gd","ir","nl","lb","hm","tw","mo","uy","pw","al","iq","hn","hk","sd","sz","sc","me","wf","bt","bs","ke","za","ge","eg","co","ly","phl","esp","tkm","ago","jor","cyp","cuw","blm","can","aia","hun","atg","vat","esh","glp","mli","mda","ind","eth","png","asm","bfa","guy","deu","ukr","jpn","prt","cck","lao","tkl","blr","afg","are","gab","swz","vnm","idn","tcd","bgd","srb","ala","mwi","rus","bes","tgo","che","zwe","cok","mne","mar","guf","grl","sjm","mmr","flk","plw","ben","bmu","gnq","bol","lca","sgs","zaf","omn","shn","gtm","nam","lso","iot","svn","gnb","fro","cmr","bra","grc","bel","niu","gmb","eri","pyf","arg","abw","nld","hmd","vgb","dza","hti","hnd","mac","msr","mtq","tto","tca","chn","mhl","egy","sxm","pse","qat","fsm","lby","tza","chl","ita","mrt","moz","mng","cod","pan","khm","smr","arm","cxr","aut","prk","uga","gum","kgz","ncl","kaz","bvt","gbr","lie","nga","ton","ner","mco","ggy","sgp","bgr","rwa","brn","isr","civ","ltu","imn","slv","bih","fji","vut","svk","cri","blz","gin","nzl","wlf","cze","dom","umi","npl","nor","sur","pol","gib","yem","isl","syr","jey","kna","tjk","fin","reu","bhs","brb","cym","cub","maf","pcn","grd","atf","hrv","gha","uzb","rou","nic","aus","zmb","caf","kir","slb","tls","sau","and","per","pak","ecu","geo","ven","tur","bdi","mdv","sen","mdg","lbr","mnp","kor","irl","fra","dma","sle","dnk","irn","jam","wsm","stp","aze","dji","som","pry","mys","cpv","ata","tha","vct","kwt","mex","alb","usa","ury","nru","sdn","spm","pri","mus","lva","bhr","swe","lux","tun","twn","col","lka","mlt","lbn","myt","cog","mkd","com","nfk","est","ssd","ken","tuv","syc","bwa","hkg","vir","irq","btn"],match=>"\\A[a-z]{2,3}\\z",summary=>"Country code (alpha-2 or alpha-3)","x.in.summaries"=>["Hungary","Tuvalu","Canada","Pakistan","Belarus","French Southern Territories","Pitcairn","Turkmenistan","Saint Barthelemy","Ireland","Saint Pierre and Miquelon","Tunisia","Lithuania","French Polynesia","Tokelau","Congo","Lesotho","Gabon","Madagascar","Martinique","Philippines","Japan","France","Dominica","Mayotte","Aland Islands","American Samoa","Barbados","Thailand","Suriname","Kyrgyzstan","Denmark","United States of America","Morocco","Estonia","Austria","Guernsey","British Indian Ocean Territory","Equatorial Guinea","Ecuador","Latvia","Jordan","Qatar","Palestine, State of","Burundi","Saudi Arabia","Portugal","Mauritania","Viet Nam","Trinidad and Tobago","Sri Lanka","Romania","Indonesia","Greece","Korea, The Republic of","Singapore","Armenia","Svalbard and Jan Mayen","Afghanistan","United States Minor Outlying Islands","Jersey","Norfolk Island","Botswana","Fiji","Reunion","Costa Rica","Mexico","Namibia","South Georgia and the South Sandwich Islands","Antarctica","Guatemala","Israel","Antigua and Barbuda","Uganda","Turkiye","Saint Helena, Ascension and Tristan da Cunha","Oman","Ukraine","Malta","Puerto Rico","Rwanda","Russian Federation","Belgium","Nigeria","Montserrat","Virgin Islands (British)","Senegal","Micronesia (Federated States of)","Slovakia","Christmas Island","San Marino","Falkland Islands (The) [Malvinas]","Bolivia (Plurinational State of)","El Salvador","Lao People's Democratic Republic","Holy See","Saint Kitts and Nevis","Zimbabwe","Switzerland","Maldives","Liberia","Guinea","Saint Martin (French part)","Myanmar","Bangladesh","Mongolia","Belize","French Guiana","Gambia","North Macedonia","Comoros","Tajikistan","Argentina","Panama","South Sudan","China","Togo","Cook Islands","Cambodia","Ghana","Sao Tome and Principe","Marshall Islands","Nauru","Cabo Verde","Djibouti","Papua New Guinea","Sint Maarten (Dutch part)","Cameroon","Central African Republic","Zambia","Cote d'Ivoire","Sierra Leone","Germany","Serbia","Syrian Arab Republic","Andorra","Uzbekistan","Azerbaijan","Mauritius","Malawi","Tonga","Guinea-Bissau","Guam","Saint Lucia","Saint Vincent and the Grenadines","Kuwait","New Zealand","Nepal","New Caledonia","Kiribati","India","Gibraltar","Dominican Republic","Western Sahara","Brazil","Solomon Islands","Peru","Isle of Man","Cuba","Curacao","Spain","Croatia","Jamaica","Algeria","Chile","Cyprus","Bosnia and Herzegovina","Ethiopia","Slovenia","United Arab Emirates","Bulgaria","Bonaire, Sint Eustatius and Saba","Finland","Niger","Yemen","Turks and Caicos Islands","United Kingdom of Great Britain and Northern Ireland","Angola","Italy","Greenland","Tanzania, the United Republic of","Guyana","Venezuela (Bolivarian Republic of)","Chad","Benin","Cayman Islands","Iceland","Norway","Mali","Malaysia","Bahrain","Nicaragua","Luxembourg","Vanuatu","Czechia","Eritrea","Congo (The Democratic Republic of the)","Sweden","Monaco","Haiti","Anguilla","Paraguay","Australia","Aruba","Poland","Brunei Darussalam","Mozambique","Moldova, The Republic of","Northern Mariana Islands","Faroe Islands","Cocos (Keeling) Islands","Bouvet Island","Somalia","Korea, The Democratic People's Republic of","Samoa","Liechtenstein","Virgin Islands (U.S.)","Kazakhstan","Niue","Burkina Faso","Bermuda","Timor-Leste","Guadeloupe","Grenada","Iran (Islamic Republic of)","Netherlands (Kingdom of the)","Lebanon","Heard Island and McDonald Islands","Taiwan (Province of China)","Macao","Uruguay","Palau","Albania","Iraq","Honduras","Hong Kong","Sudan","Eswatini","Seychelles","Montenegro","Wallis and Futuna","Bhutan","Bahamas","Kenya","South Africa","Georgia","Egypt","Colombia","Libya","Philippines","Spain","Turkmenistan","Angola","Jordan","Cyprus","Curacao","Saint Barthelemy","Canada","Anguilla","Hungary","Antigua and Barbuda","Holy See","Western Sahara","Guadeloupe","Mali","Moldova, The Republic of","India","Ethiopia","Papua New Guinea","American Samoa","Burkina Faso","Guyana","Germany","Ukraine","Japan","Portugal","Cocos (Keeling) Islands","Lao People's Democratic Republic","Tokelau","Belarus","Afghanistan","United Arab Emirates","Gabon","Eswatini","Viet Nam","Indonesia","Chad","Bangladesh","Serbia","Aland Islands","Malawi","Russian Federation","Bonaire, Sint Eustatius and Saba","Togo","Switzerland","Zimbabwe","Cook Islands","Montenegro","Morocco","French Guiana","Greenland","Svalbard and Jan Mayen","Myanmar","Falkland Islands (The) [Malvinas]","Palau","Benin","Bermuda","Equatorial Guinea","Bolivia (Plurinational State of)","Saint Lucia","South Georgia and the South Sandwich Islands","South Africa","Oman","Saint Helena, Ascension and Tristan da Cunha","Guatemala","Namibia","Lesotho","British Indian Ocean Territory","Slovenia","Guinea-Bissau","Faroe Islands","Cameroon","Brazil","Greece","Belgium","Niue","Gambia","Eritrea","French Polynesia","Argentina","Aruba","Netherlands (Kingdom of the)","Heard Island and McDonald Islands","Virgin Islands (British)","Algeria","Haiti","Honduras","Macao","Montserrat","Martinique","Trinidad and Tobago","Turks and Caicos Islands","China","Marshall Islands","Egypt","Sint Maarten (Dutch part)","Palestine, State of","Qatar","Micronesia (Federated States of)","Libya","Tanzania, the United Republic of","Chile","Italy","Mauritania","Mozambique","Mongolia","Congo (The Democratic Republic of the)","Panama","Cambodia","San Marino","Armenia","Christmas Island","Austria","Korea, The Democratic People's Republic of","Uganda","Guam","Kyrgyzstan","New Caledonia","Kazakhstan","Bouvet Island","United Kingdom of Great Britain and Northern Ireland","Liechtenstein","Nigeria","Tonga","Niger","Monaco","Guernsey","Singapore","Bulgaria","Rwanda","Brunei Darussalam","Israel","Cote d'Ivoire","Lithuania","Isle of Man","El Salvador","Bosnia and Herzegovina","Fiji","Vanuatu","Slovakia","Costa Rica","Belize","Guinea","New Zealand","Wallis and Futuna","Czechia","Dominican Republic","United States Minor Outlying Islands","Nepal","Norway","Suriname","Poland","Gibraltar","Yemen","Iceland","Syrian Arab Republic","Jersey","Saint Kitts and Nevis","Tajikistan","Finland","Reunion","Bahamas","Barbados","Cayman Islands","Cuba","Saint Martin (French part)","Pitcairn","Grenada","French Southern Territories","Croatia","Ghana","Uzbekistan","Romania","Nicaragua","Australia","Zambia","Central African Republic","Kiribati","Solomon Islands","Timor-Leste","Saudi Arabia","Andorra","Peru","Pakistan","Ecuador","Georgia","Venezuela (Bolivarian Republic of)","Turkiye","Burundi","Maldives","Senegal","Madagascar","Liberia","Northern Mariana Islands","Korea, The Republic of","Ireland","France","Dominica","Sierra Leone","Denmark","Iran (Islamic Republic of)","Jamaica","Samoa","Sao Tome and Principe","Azerbaijan","Djibouti","Somalia","Paraguay","Malaysia","Cabo Verde","Antarctica","Thailand","Saint Vincent and the Grenadines","Kuwait","Mexico","Albania","United States of America","Uruguay","Nauru","Sudan","Saint Pierre and Miquelon","Puerto Rico","Mauritius","Latvia","Bahrain","Sweden","Luxembourg","Tunisia","Taiwan (Province of China)","Colombia","Sri Lanka","Malta","Lebanon","Mayotte","Congo","North Macedonia","Comoros","Norfolk Island","Estonia","South Sudan","Kenya","Tuvalu","Seychelles","Botswana","Hong Kong","Virgin Islands (U.S.)","Iraq","Bhutan"],"x.perl.coerce_rules"=>["From_str::to_lower"]}],clsets_after_type=>['$var->{clsets_after_base}[0]'],"clsets_after_type.alt.merge.merged"=>['$var->{clsets_after_base}[0]'],resolve_path=>["str"],type=>"str",v=>2};$var->{clsets_after_type}[0]=$var->{clsets_after_base}[0];$var->{"clsets_after_type.alt.merge.merged"}[0]=$var->{clsets_after_base}[0];$var};

1;
# ABSTRACT: Country code (alpha-2 or alpha-3)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaR::country::code - Country code (alpha-2 or alpha-3)

=head1 VERSION

This document describes version 0.009 of Sah::SchemaR::country::code (from Perl distribution Sah-Schemas-Country), released on 2023-08-07.

=head1 DESCRIPTION

This module is automatically generated by Dist::Zilla::Plugin::Sah::Schemas during distribution build.

A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Country>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Country>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
