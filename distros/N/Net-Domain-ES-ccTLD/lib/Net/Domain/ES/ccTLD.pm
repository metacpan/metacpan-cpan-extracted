package Net::Domain::ES::ccTLD;

use utf8;
use Modern::Perl;
use Carp qw( croak );

use base qw/Exporter/;
our @EXPORT = qw/find_name_by_cctld/;

=head1 NAME

Net::Domain::ES::ccTLD - Lookup for country names given the TLD code (¡en Español!)

=head1 VERSION

Version 0.01. ¡Se habla Español!

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Lookup for a country name given the country code (ccTLD)... in Spanish.

  use Net::Domain::ES::ccTLD;

  my $country = find_name_by_cctld('mx')        # $country is 'México'
    or die "Couldn't find name.";

  my $neighbor = find_name_by_cctld('us');      # $neighbor is 'Estados Unidos'

=head1 EXPORT

=head2 find_name_by_cctld

It returns the Spanish name of the country code or undef if it can't find it.

=head1 DESCRIPTION

This module is similar to L<Locales::Country::es> in purpose, but this one does work
(I tried that one and it was busted), I actively maintain it (because I use it for
my work), the encoding is not messed up and it's based on the names under:

 http://es.wikipedia.org/wiki/Dominio_de_nivel_superior_geogr%C3%A1fico

You've been warned :)

=cut

my %_cc_map = (
	ad => 'Andorra',
	ae => 'Emiratos Árabes Unidos',
	af => 'Afganistán',
	ag => 'Antigua y Barbuda',
	ai => 'Anguila',
	al => 'Albania',
	am => 'Armenia',
	an => 'Antillas Neerlandesas',
	ao => 'Angola',
	aq => 'Antártida',
	ar => 'Argentina',
	as => 'Samoa Americana',
	at => 'Austria',
	au => 'Australia',
	aw => 'Aruba',
	ax => 'Åland',
	az => 'Azerbaiyán',
	ba => 'Bosnia-Herzegovina',
	bb => 'Barbados',
	bd => 'Bangladesh',
	be => 'Bélgica',
	bf => 'Burkina Faso',
	bg => 'Bulgaria',
	bh => 'Bahréin',
	bi => 'Burundi',
	bj => 'Benín',
	bm => 'Bermudas',
	bn => 'Brunei Darussalam',
	bo => 'Bolivia',
	br => 'Brasil',
	bs => 'Bahamas',
	bt => 'Bután',
	bu => 'Birmania',
	bv => 'Isla Bouvet',
	bw => 'Botsuana',
	by => 'Bielorrusia',
	bz => 'Belice',
	ca => 'Canadá',
	cc => 'Islas Cocos',
	cd => 'República Democrática del Congo',
	cf => 'República Centroafricana',
	cg => 'República del Congo',
	ch => 'Suiza',
	ci => 'Costa de Marfil',
	ck => 'Islas Cook',
	cl => 'Chile',
	cm => 'Camerún',
	cn => 'República Popular China',
	co => 'Colombia',
	cr => 'Costa Rica',
	cs => 'Serbia y Montenegro',
	cu => 'Cuba',
	cv => 'Cabo Verde',
	cx => 'Isla de Navidad',
	cy => 'Chipre',
	cz => 'República Checa',
	dd => 'República Democrática Alemana',
	de => 'Alemania',
	dj => 'Yibuti',
	dk => 'Dinamarca',
	dm => 'Dominica',
	do => 'República Dominicana',
	dz => 'Argelia',
	ec => 'Ecuador',
	ee => 'Estonia',
	eg => 'Egipto',
	eh => 'Sáhara Occidental',
	er => 'Eritrea',
	es => 'España',
	et => 'Etiopía',
	eu => 'Unión Europea',
	fi => 'Finlandia',
	fj => 'Fiyi',
	fk => 'Islas Malvinas',
	fm => 'Estados Federados de Micronesia',
	fo => 'Islas Feroe',
	fr => 'Francia',
	ga => 'Gabón',
	gb => 'Reino Unido',
	gd => 'Granada',
	ge => 'Georgia',
	gf => 'Guayana Francesa',
	gg => 'Guernesey',
	gh => 'Ghana',
	gi => 'Gibraltar',
	gl => 'Groenlandia',
	gm => 'Gambia',
	gn => 'Guinea',
	gp => 'Guadalupe',
	gq => 'Guinea Ecuatorial',
	gr => 'Grecia',
	gs => 'Islas Georgias del Sur y Sandwich del Sur',
	gt => 'Guatemala',
	gu => 'Guam',
	gw => 'Guinea-Bissau',
	gy => 'Guyana',
	hk => 'Hong Kong',
	hm => 'Islas Heard y McDonald',
	hn => 'Honduras',
	hr => 'Croacia',
	ht => 'Haití',
	hu => 'Hungría',
	id => 'Indonesia',
	ie => 'Irlanda',
	il => 'Israel',
	im => 'Isla de Man',
	in => 'India',
	io => 'Territorio Británico en el Océano Índico',
	iq => 'Iraq',
	ir => 'Irán',
	is => 'Islandia',
	it => 'Italia',
	je => 'Isla de Jersey',
	jm => 'Jamaica',
	jo => 'Jordania',
	jp => 'Japón',
	ke => 'Kenia',
	kg => 'Kirguistán',
	kh => 'Camboya',
	ki => 'Kiribati',
	km => 'Comoras',
	kn => 'San Cristóbal y Nieves',
	kp => 'Corea del Norte',
	kr => 'Corea del Sur',
	kw => 'Kuwait',
	ky => 'Islas Caimán',
	kz => 'Kazajistán',
	la => 'Laos',
	lb => 'Líbano',
	lc => 'Santa Lucía',
	li => 'Liechtenstein',
	lk => 'Sri Lanka',
	lr => 'Liberia',
	ls => 'Lesotho',
	lt => 'Lituania',
	lu => 'Luxemburgo',
	lv => 'Letonia',
	ly => 'Libia',
	ma => 'Marruecos',
	mc => 'Mónaco',
	md => 'Moldavia',
	me => 'Montenegro',
	mg => 'Madagascar',
	mh => 'Islas Marshall',
	mk => 'República de Macedonia',
	ml => 'Malí',
	mm => 'Myanmar',
	mn => 'Mongolia',
	mo => 'Macao',
	mp => 'Islas Marianas del Norte',
	mq => 'Martinica',
	mr => 'Mauritania',
	ms => 'Montserrat',
	mt => 'Malta',
	mu => 'Mauricio',
	mv => 'Maldivas',
	mw => 'Malawi',
	mx => 'México',
	my => 'Malasia',
	mz => 'Mozambique',
	na => 'Namibia',
	nc => 'Nueva Caledonia',
	ne => 'Níger',
	nf => 'Isla Norfolk',
	ng => 'Nigeria',
	ni => 'Nicaragua',
	nl => 'Países Bajos',
	no => 'Noruega',
	np => 'Nepal',
	nr => 'Nauru',
	nu => 'Niue',
	nz => 'Nueva Zelanda',
	om => 'Omán',
	pa => 'Panamá',
	pe => 'Perú',
	pf => 'Polinesia Francesa',
	pg => 'Papúa Nueva Guinea',
	ph => 'Filipinas',
	pk => 'Pakistán',
	pl => 'Polonia',
	pm => 'San Pedro y Miquelón',
	pn => 'Islas Pitcairn',
	pr => 'Puerto Rico',
	ps => 'Palestina',
	pt => 'Portugal',
	pw => 'Palaos',
	py => 'Paraguay',
	qa => 'Qatar',
	re => 'Reunión',
	ro => 'Rumania',
	rs => 'Serbia',
	ru => 'Rusia',
	rw => 'Ruanda',
	sa => 'Arabia Saudita',
	sb => 'Islas Salomón',
	sc => 'Seychelles',
	sd => 'Sudán',
	se => 'Suecia',
	sg => 'Singapur',
	sh => 'Santa Helena',
	si => 'Eslovenia',
	sj => 'Svalbard y Jan Mayen',
	sk => 'Eslovaquia',
	sl => 'Sierra Leona',
	sm => 'San Marino',
	sn => 'Senegal',
	so => 'Somalia',
	sr => 'Surinam',
	st => 'Santo Tomé y Príncipe',
	su => 'Antigua Unión Soviética',
	sv => 'El Salvador',
	sy => 'Siria',
	sz => 'Swazilandia',
	tc => 'Islas Turcas y Caicos',
	td => 'Chad',
	tf => 'Territorios Australes Franceses',
	tg => 'Togo',
	th => 'Tailandia',
	tj => 'Tayikistán',
	tk => 'Tokelau',
	tl => 'Timor Oriental',
	tm => 'Turkmenistán',
	tn => 'Túnez',
	to => 'Tonga',
	tp => 'Timor Oriental',
	tr => 'Turquía',
	tt => 'Trinidad y Tobago',
	tv => 'Tuvalu',
	tw => 'Taiwán',
	tz => 'Tanzania',
	ua => 'Ucrania',
	ug => 'Uganda',
	uk => 'Reino Unido',
	um => 'Islas Ultramarinas de Estados Unidos',
	us => 'Estados Unidos',
	uy => 'Uruguay',
	uz => 'Uzbekistán',
	va => 'Ciudad del Vaticano',
	vc => 'San Vicente y las Granadinas',
	ve => 'Venezuela',
	vg => 'Islas Vírgenes Británicas',
	vi => 'Islas Vírgenes de los Estados Unidos',
	vn => 'Vietnam',
	vu => 'Vanuatu',
	wf => 'Wallis y Futuna',
	ws => 'Samoa',
	ye => 'Yemen',
	yt => 'Mayotte',
	yu => 'Yugoslavia',
	za => 'Sudáfrica',
	zm => 'Zambia',
	zr => 'Zaire',
	zw => 'Zimbabue',
);

sub find_name_by_cctld {
    $_cc_map{ $_[0] || croak 'no argument passed' }
}

=head1 AUTHOR

David Moreno, C<< <david at axiombox.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-domain-es-cctld at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Domain-ES-ccTLD>. 
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Net::Domain::ES::ccTLD

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Domain-ES-ccTLD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Domain-ES-ccTLD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Domain-ES-ccTLD>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Domain-ES-ccTLD/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 David Moreno.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut

1; # End of Net::Domain::ES::ccTLD
