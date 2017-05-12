package MobilePhone::MCC;

use warnings;
use strict;
use Carp;

use overload '""' => sub { $_[0]->mcc };

#private global variable
our $CODES = {};

=head1 NAME

MobilePhone::MCC - Class and Functions to manipulate Mobile Country Codes.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS	

The class defined in this module can be used to manage MCCs and tell you which
country they apply to, etc.

Here are a few wee code snippets.

    use MobilePhone::MCC;
    
    my $iso_a2 = MobilePhone::MCC->new(234)->county;
    ...
	
=cut

use base qw( Exporter );
our @EXPORT_OK = qw( ValidMCC ValidCountryCode );

=head1 EXPORT_OK

=head2 ValidMCC (MCC)

Check if a supplied mcc value could be a valid mobile country code.

=cut

sub ValidMCC {
	my $new = shift;
	if ($new =~ /\D/) {
		$@ = 'contains non numerical chars';
		return;
	}
	unless (0 <= $new && $new <= 999) {
		$@ = 'not in range 0-999';
		return;
	}
	1;
}

=head2 ValidCountryCode (ISO_COUNTRY_CODE)

Check if a supplied country code matches that defined as A2 in ISO 3166.

=cut


sub ValidCountryCode {
	my $new = shift;
	if ($new !~ /^[a-z]{2}$/) {
		$@ = 'does not match regex /^[a-z]{2}$/';
		return;
	}
	1;
}

=head1 CLASS METHODS

=head2 new [(MCC|ISO_COUNTRY_CODE)]

Create a new MobilePhone::MCC object. This can be queried to return information
about that code. e.g. County code or Country name.

=cut

sub new {
	my $p = shift;
	my $class = ref $p || $p || __PACKAGE__;
	my $mcc = '';
	my $self = bless \$mcc, $class;
	$self->_init(@_);
	$self;
}

sub _init {
	my $self = shift;
	$self->_load_data();
	#attempt to set value from params
	if (@_) {
		my $new = shift;
		if (ValidMCC($new)) {
			return $self->mcc($new);
		} elsif (ValidCountryCode($new)) {
			return $self->country($new);
		} else {
			carp('usage: ' . __PACKAGE__. '->new(MMC|COUNTRY_CODE)');
		}
	}
}

=head2 mcc [MCC]

Get or set the mobile county code

=cut

sub mcc {
	my $self = shift;
	if (@_) {
		my $new = shift;
		if (ValidMCC($new)) {
			${$self} = $new;
		} else {
			carp("bad mcc: $@");
			return;
		}
	}
	$$self;
}

=head2 country (ISO_COUNTRY_CODE)

Get or set the county code. This should be in the A2 format defined in ISO 3166

=cut

sub country
{
	my $self = shift;
	if (@_) {
		my $new = shift;
		if (! ValidCountryCode($new)) {
			carp("bad country code: $@");
			return;
		}
		#reverse lookup
		my $mcc = eval (q#	 $CODES->{'cc'}->{$new}->[0]	 # );
		if (! $mcc) {
			carp("mcc lookup failed: $@");
		}
		${$self} = $mcc;
	}
	#lookup
	eval (q#	 $CODES->{'mcc'}->{$self->mcc}->[1]	 # );
}

=head2 country_name

Retrive the country name of the current mobile country code.

=cut

sub country_name
{
	my $self = shift;
	eval (q#	 $CODES->{'mcc'}->{$self->mcc}->[2]	 # );
}

#initialise data by loading it into a global hashref
sub _load_data {
	local $| = 1;
	while (my $line = <DATA>) {
		chomp($line);
		my $data = [(split (/:/, $line))];

		#index by mcc
		$CODES->{'mcc'} ||= {};
		$CODES->{'mcc'}->{$data->[0]} = $data;

		#index by country code
		$CODES->{'cc'} ||= {};
		$CODES->{'cc'}->{$data->[1]} = $data;
	}
}

=head1 AUTHOR

Ali Craigmile, C<< <ali at hodgers.com> >>

=head1 KNOWN BUGS AND CAVEATS

All mcc data is loaded from source on each object invocation which is time and 
processor consuming. A future release will include caching of this data.

County names should not be trusted for accuracy or to be correct given the 
current Locale. Use C<Locale::Country> instead if you need accuracy.

=head1 ALSO SEE

=over 4

=item examples/mcc.pl

for more detailed example of using this package.

=item L<http://en.wikipedia.org/wiki/Mobile_Network_Code>

for an (almost) exhaustive HTML list of MCC codes.

=item L<http://search.cpan.org/dist/Locale-Codes/>

for more detailed ISO Country Code information, especially when it comes to
explaining what A2 is.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ali Craigmile, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MobilePhone::MMC

__DATA__
412:af:Afghanistan
276:al:Albania
603:dz:Algeria
213:ad:Andorra
631:ao:Angola
365:ai:Anguilla
344:ag:Antigua & Barbuda
722:ar:Argentina
283:am:Armenia
363:aw:Aruba
505:au:Australia
232:at:Austria
400:az:Azerbaijan
426:bh:Bahrain
470:bd:Bangladesh
880:bb:Barbados
342:bb:Barbados ??
257:by:Belarus
206:be:Belgium
702:bz:Belize
616:bj:Benin
402:bt:Bhutan
218:ba:Bosnia and Herzegovina
736:bo:Bolivia
652:bw:Botswana
724:br:Brazil
348:vg:British Virgin Islands
528:bn:Brunei Darussalam
284:bg:Bulgaria
613:bf:Burkina Faso
642:bi:Burundi
456:kh:Cambodia
624:cm:Cameroon
302:ca:Canada
625:cv:Cape Verde
346:ky:Cayman Islands
623:cf:Central African Republic
622:td:Chad
730:cl:Chile
460:cn:China
732:co:Colombia
654:km:Comoros
629:cd:Republic of Congo
548:ck:Cook Islands
712:cr:Costa Rica
219:hr:Croatia
368:cu:Cuba
280:cy:Cyprus
230:cz:Czech Republic
630:cd:Democratic Republic of the Congo
238:dk:Denmark
638:dj:Djibouti
370:do:Dominican Republic
740:ec:Ecuador
602:eg:Egypt
706:sv:El Salvador
248:es:Estonia
636:et:Ethiopia
288:fo:Faroe Islands
542:fj:Fiji
244:fi:Finland
208:fr:France
547:pf:French Polynesia (France)
628:ga:Gabon
607:gm:Gambia
282:ge:Georgia
262:de:Germany
620:gh:Ghana
266:gi:Gibraltar
202:gr:Greece
290:gl:Greenland
340:gp:Guadeloupe
704:gt:Guatemala
611:gq:Guinea
632:gw:Guinea-Bissau
738:gy:Guyana
708:hn:Honduras
454:hk:Hong Kong
216:hu:Hungary
274:is:Iceland
404:in:India
510:id:Indonesia
432:ir:Iran
418:iq:Iraq
272:ie:Ireland
425:il:Israel
222:it:Italy
612::Ivory Coast
338:jm:Jamaica
440:jp:Japan
416:jo:Jordan
401:kz:Kazakhstan
639:ke:Kenya
450:kp:Korea ??
450:kr:Korea ??
419:kw:Kuwait
437:kg:Kyrgyzstan
457:l:Laos
247:lv:Latvia
415:lb:Lebanon
651:ls:Lesotho
618:lr:Liberia
606:ly:Libya
295:li:Liechtenstein
246:lt:Lithuania
270:lu:Luxembourg
455:mo:Macao
294:mk:Republic of Macedonia
646:mg:Madagascar
650:mw:Malawi
502:my:Malaysia
472:mv:Maldives
610:ml:Mali
278:mt:Malta
609:mr:Mauritania
617:mu:Mauritius
334:mx:Mexico
550:fm:Micronesia
259:md:Moldova
208:mc:Monaco
428:mn:Mongolia
220:cs:Montenegro
604:ma:Morocco
643:mz:Mozambique
414:mm:Myanmar
649:ma:Namibia
429:np:Nepal
204:nl:Netherlands
362:an:Netherlands Antilles (Netherlands)
546:nc:New Caledonia
530:nz:New Zealand
710:ni:Nicaragua
614:ne:Niger
621:ng:Nigeria
242:no:Norway
422:om:Oman
410:pk:Pakistan
552:pw:Palau
714:pa:Panama
537:pg:Papua New Guinea
744:py:Paraguay
716:pe:Peru
260:pl:Poland
268:pt:Portugal
427:qa:Qatar
647:re:Réunion
226:ro:Romania
250:ru:Russian Federation
635:rw:Rwanda
308:pm:Saint Pierre and Miquelon
549:ws:Samoa
292:sm:San Marino
222:sm::San Marino
626:st:Sao Tome and Principe
420:sa:Saudi Arabia
608:sn:Senegal
220:cs:Serbia
633:sc:Seychelles
619:sl:Sierra Leone
525:sg:Singapore
231:sk:Slovakia
293:si:Slovenia
655:sa:South Africa
214:es:Spain
413:lk:Sri Lanka
634:sd:Sudan
746:sr:Suriname
653:sz:Swaziland
240:se:Sweden
228:ch:Switzerland
417:sy:Syria
436:tj:Tajikistan
466:tw:Taiwan
640:tz:Tanzania
520:th:Thailand
615:tg:Togolese Republic
539:to:Tonga
374:tt:Trinidad and Tobago
605:tn:Tunisia
286:tr:Turkey
438:tm:Turkmenistan
641:ug:Uganda
255:ua:Ukraine
424:ae:United Arab Emirates
234:gb:United Kingdom
310:us:United States of America
311:us:United States of America
316:us:United States of America
748:uy:Uruguay
434:uz:Uzbekistan
541:vu:Vanuatu
225:va:Vatican
734:ve:Venezuela
452:vn:Vietnam
421:ye:Yemen
645:zm:Zambia
648:zw:Zimbabwe
909:*:International