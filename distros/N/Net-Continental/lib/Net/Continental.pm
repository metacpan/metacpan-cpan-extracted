use strict;
use warnings;
package Net::Continental;
# ABSTRACT: code to map countries to continents, esp. with nerd.dk dnsbl
$Net::Continental::VERSION = '0.016';
use Carp ();
use Locale::Codes::Country ();
use Net::Continental::Zone;
use Scalar::Util qw(blessed);

our %Continent = (
  N => 'North America',
  S => 'South America',
  E => 'Europe',
  A => 'Asia',
  F => 'Africa',
  O => 'Oceania',
  Q => 'Antarctica',
);

#         qw(continent description)

my %zone = (
  ae => [ A => q{United Arab Emirates} ],
  af => [ A => q{Afghanistan} ],
  az => [ A => q{Azerbaijan} ],
  bd => [ A => q{Bangladesh} ],
  bh => [ A => q{Bahrain} ],
  bt => [ A => q{Bhutan} ],
  bn => [ A => q{Brunei Darussalam} ],
  cn => [ A => q{China} ],

  # classification of Georgia in Europe or Asia is touchy
  ge => [ A => q{Georgia} ],

  hk => [ A => q{Hong Kong} ],
  il => [ A => q{Israel} ],
  in => [ A => q{India} ],
  id => [ A => q{Indonesia} ],
  iq => [ A => q{Iraq} ],
  ir => [ A => q{Iran (Islamic Republic of)} ],
  jo => [ A => q{Jordan} ],
  jp => [ A => q{Japan} ],
  kg => [ A => q{Kyrgyzstan} ],
  kh => [ A => q{Cambodia} ],
  kp => [ A => q{Korea, Democratic People's Republic} ],
  kr => [ A => q{Korea, Republic of} ],
  kw => [ A => q{Kuwait} ],
  kz => [ A => q{Kazakhstan} ],
  la => [ A => q{Lao People's Democratic Republic} ],
  lb => [ A => q{Lebanon} ],
  lk => [ A => q{Sri Lanka} ],
  mm => [ A => q{Myanmar} ],
  mn => [ A => q{Mongolia} ],
  mo => [ A => q{Macau} ],
  mv => [ A => q{Maldives} ],
  my => [ A => q{Malaysia} ],
  np => [ A => q{Nepal} ],
  om => [ A => q{Oman} ],
  ph => [ A => q{Philippines} ],
  pk => [ A => q{Pakistan} ],
  ps => [ A => q{Palestinian Territories} ],
  qa => [ A => q{Qatar} ],
  ru => [ A => q{Russian Federation} ],
  sa => [ A => q{Saudi Arabia} ],
  sg => [ A => q{Singapore} ],
  su => [ A => q{Soviet Union} ],
  sy => [ A => q{Syrian Arab Republic} ],
  th => [ A => q{Thailand} ],
  tj => [ A => q{Tajikistan} ],
  tl => [ A => q{Timor-Leste} ],
  tm => [ A => q{Turkmenistan} ],
  tp => [ A => q{East Timor} ],
  tr => [ A => q{Turkey} ],
  tw => [ A => q{Taiwan} ],
  uz => [ A => q{Uzbekistan} ],
  vn => [ A => q{Vietnam} ],
  ye => [ A => q{Yemen} ],

  ad => [ E => q{Andorra} ],
  al => [ E => q{Albania} ],
  am => [ E => q{Armenia} ],
  at => [ E => q{Austria} ],
  ax => [ E => q(Aland Islands) ],
  ba => [ E => q{Bosnia and Herzegovina} ],
  be => [ E => q{Belgium} ],
  bg => [ E => q{Bulgaria} ],
  by => [ E => q{Belarus} ],
  ch => [ E => q{Switzerland} ],
  cy => [ E => q{Cyprus} ],
  cz => [ E => q{Czech Republic} ],
  de => [ E => q{Germany} ],
  dk => [ E => q{Denmark} ],
  ee => [ E => q{Estonia} ],
  es => [ E => q{Spain} ],
  eu => [ E => q{European Union} ],
  fi => [ E => q{Finland} ],
  fo => [ E => q{Faroe Islands} ],
  fr => [ E => q{France} ],
  fx => [ E => q{France, Metropolitan} ],
  gb => [ E => q{United Kingdom} ],
  gg => [ E => q{Guernsey} ],
  gi => [ E => q{Gibraltar} ],
  gr => [ E => q{Greece} ],
  hr => [ E => q{Croatia/Hrvatska} ],
  hu => [ E => q{Hungary} ],
  ie => [ E => q{Ireland} ],
  im => [ E => q{Isle of Man} ],
  is => [ E => q{Iceland} ],
  it => [ E => q{Italy} ],
  je => [ E => q{Jersey} ],
  li => [ E => q{Liechtenstein} ],
  lt => [ E => q{Lithuania} ],
  lu => [ E => q{Luxembourg} ],
  lv => [ E => q{Latvia} ],
  mc => [ E => q{Monaco} ],
  md => [ E => q{Moldova, Republic of} ],
  me => [ E => q(Montenegro) ],
  mk => [ E => q{Macedonia, Former Yugoslav Republic} ],
  mt => [ E => q{Malta} ],
  nl => [ E => q{Netherlands} ],
  no => [ E => q{Norway} ],
  pl => [ E => q{Poland} ],
  pt => [ E => q{Portugal} ],
  ro => [ E => q{Romania} ],
  rs => [ E => q(Serbia) ],
  se => [ E => q{Sweden} ],
  si => [ E => q{Slovenia} ],
  sj => [ E => q{Svalbard and Jan Mayen Islands} ],
  sk => [ E => q{Slovak Republic} ],
  sm => [ E => q{San Marino} ],
  ua => [ E => q{Ukraine} ],
  # uk => [ E => q{United Kingdom} ],
  va => [ E => q{Holy See (City Vatican State)} ],
  yu => [ E => q{Yugoslavia} ],

  ac => [ F => q{Ascension Island} ],
  ao => [ F => q{Angola} ],
  bf => [ F => q{Burkina Faso} ],
  bi => [ F => q{Burundi} ],
  bj => [ F => q{Benin} ],
  bw => [ F => q{Botswana} ],
  cd => [ F => q{Congo, Democratic Republic of the} ],
  cf => [ F => q{Central African Republic} ],
  cg => [ F => q{Congo, Republic of} ],
  ci => [ F => q{Cote d'Ivoire} ],
  cm => [ F => q{Cameroon} ],
  cv => [ F => q{Cap Verde} ],
  dj => [ F => q{Djibouti} ],
  dz => [ F => q{Algeria} ],
  eg => [ F => q{Egypt} ],
  eh => [ F => q{Western Sahara} ],
  er => [ F => q{Eritrea} ],
  et => [ F => q{Ethiopia} ],
  ga => [ F => q{Gabon} ],
  gh => [ F => q{Ghana} ],
  gm => [ F => q{Gambia} ],
  gn => [ F => q{Guinea} ],
  gq => [ F => q{Equatorial Guinea} ],
  gw => [ F => q{Guinea-Bissau} ],
  ke => [ F => q{Kenya} ],
  km => [ F => q{Comoros} ],
  lr => [ F => q{Liberia} ],
  ls => [ F => q{Lesotho} ],
  ly => [ F => q{Libyan Arab Jamahiriya} ],
  ma => [ F => q{Morocco} ],
  mg => [ F => q{Madagascar} ],
  ml => [ F => q{Mali} ],
  mr => [ F => q{Mauritania} ],
  mu => [ F => q{Mauritius} ],
  mw => [ F => q{Malawi} ],
  mz => [ F => q{Mozambique} ],
  na => [ F => q{Namibia} ],
  ne => [ F => q{Niger} ],
  ng => [ F => q{Nigeria} ],
  re => [ F => q{Reunion Island} ],
  rw => [ F => q{Rwanda} ],
  sc => [ F => q{Seychelles} ],
  sd => [ F => q{Sudan} ],
  sh => [ F => q{St. Helena} ],
  sl => [ F => q{Sierra Leone} ],
  sn => [ F => q{Senegal} ],
  so => [ F => q{Somalia} ],
  st => [ F => q{Sao Tome and Principe} ],
  sz => [ F => q{Swaziland} ],
  td => [ F => q{Chad} ],
  tg => [ F => q{Togo} ],
  tn => [ F => q{Tunisia} ],
  tz => [ F => q{Tanzania} ],
  ug => [ F => q{Uganda} ],
  yt => [ F => q{Mayotte} ],
  za => [ F => q{South Africa} ],
  zm => [ F => q{Zambia} ],
  zr => [ F => q{Zaire} ],
  zw => [ F => q{Zimbabwe} ],

  ag => [ N => q{Antigua and Barbuda} ],
  ai => [ N => q{Anguilla} ],
  an => [ N => q{Netherlands Antilles} ],
  aw => [ N => q{Aruba} ],
  bb => [ N => q{Barbados} ],
  bl => [ N => q(Saint Barthelemy) ],
  bm => [ N => q{Bermuda} ],
  bs => [ N => q{Bahamas} ],
  bz => [ N => q{Belize} ],
  ca => [ N => q{Canada} ],
  cr => [ N => q{Costa Rica} ],
  cu => [ N => q{Cuba} ],
  dm => [ N => q{Dominica} ],
  do => [ N => q{Dominican Republic} ],
  gd => [ N => q{Grenada} ],
  gl => [ N => q{Greenland} ],
  gp => [ N => q{Guadeloupe} ],
  gt => [ N => q{Guatemala} ],
  hn => [ N => q{Honduras} ],
  ht => [ N => q{Haiti} ],
  jm => [ N => q{Jamaica} ],
  kn => [ N => q{Saint Kitts and Nevis} ],
  lc => [ N => q{Saint Lucia} ],
  mf => [ N => q{Saint Martin (French part)} ],
  mq => [ N => q{Martinique} ],
  ms => [ N => q{Montserrat} ],
  mx => [ N => q{Mexico} ],
  ni => [ N => q{Nicaragua} ],
  pa => [ N => q{Panama} ],
  pm => [ N => q{St. Pierre and Miquelon} ],
  pr => [ N => q{Puerto Rico} ],
  sv => [ N => q{El Salvador} ],
  tc => [ N => q{Turks and Caicos Islands} ],
  tt => [ N => q{Trinidad and Tobago} ],
  us => [ N => q{United States} ],
  vc => [ N => q{Saint Vincent and the Grenadines} ],
  vg => [ N => q{Virgin Islands (British)} ],
  vi => [ N => q{Virgin Islands (USA)} ],

  as => [ O => q{American Samoa} ],
  au => [ O => q{Australia} ],
  cc => [ O => q{Cocos (Keeling) Islands} ],
  ck => [ O => q{Cook Islands} ],
  cx => [ O => q{Christmas Island} ],
  fj => [ O => q{Fiji} ],
  fm => [ O => q{Micronesia, Federated States of} ],
  gu => [ O => q{Guam} ],
  io => [ O => q{British Indian Ocean Territory} ],
  ki => [ O => q{Kiribati} ],
  ky => [ O => q{Cayman Islands} ],
  mh => [ O => q{Marshall Islands} ],
  mp => [ O => q{Northern Mariana Islands} ],
  nc => [ O => q{New Caledonia} ],
  nf => [ O => q{Norfolk Island} ],
  nr => [ O => q{Nauru} ],
  nu => [ O => q{Niue} ],
  nz => [ O => q{New Zealand} ],
  pf => [ O => q{French Polynesia} ],
  pg => [ O => q{Papua New Guinea} ],
  pn => [ O => q{Pitcairn Island} ],
  pw => [ O => q{Palau} ],
  sb => [ O => q{Solomon Islands} ],
  tk => [ O => q{Tokelau} ],
  to => [ O => q{Tonga} ],
  tv => [ O => q{Tuvalu} ],
  um => [ O => q{US Minor Outlying Islands} ],
  vu => [ O => q{Vanuatu} ],
  wf => [ O => q{Wallis and Futuna Islands} ],
  ws => [ O => q{Western Samoa} ],

  aq => [ Q => q{Antartica} ],
  bv => [ Q => q{Bouvet Island} ],
  gs => [ Q => q{South Georgia and the South Sandwich Islands} ],
  hm => [ Q => q{Heard and McDonald Islands} ],
  tf => [ Q => q{French Southern Territories} ],

  ar => [ S => q{Argentina} ],
  bo => [ S => q{Bolivia} ],
  br => [ S => q{Brazil} ],
  cl => [ S => q{Chile} ],
  co => [ S => q{Colombia} ],
  cw => [ S => q{Curacao} ],
  ec => [ S => q{Ecuador} ],
  fk => [ S => q{Falkland Islands (Malvina)} ],
  gf => [ S => q{French Guiana} ],
  gy => [ S => q{Guyana} ],
  pe => [ S => q{Peru} ],
  py => [ S => q{Paraguay} ],
  sr => [ S => q{Suriname} ],
  uy => [ S => q{Uruguay} ],
  ve => [ S => q{Venezuela} ],
);

#pod =head1 NAME
#pod
#pod Net::Continental - IP addresses of the world, by country and continent
#pod
#pod =head1 METHODS
#pod
#pod =head2 zone
#pod
#pod   # Get the zone for the US.
#pod   my $zone = Net::Continental->zone('us');
#pod
#pod This returns a L<Net::Continental::Zone> object for the given ISO code.
#pod
#pod =cut

my %tld_for_code = (gb => 'uk');
my %code_for_tld = reverse %tld_for_code;

sub zone {
  my ($self, $code) = @_;

  unless (exists $zone{$code}) {
    $code = $code_for_tld{$code}
      if exists $code_for_tld{$code}
      && exists $zone{ $code_for_tld{ $code } };
  }

  Carp::croak("unknown code $code") unless exists $zone{$code};

  unless (blessed $zone{ $code }) {
    $zone{ $code } = Net::Continental::Zone->_new([
      $code,
      @{ $zone{ $code } },
      $tld_for_code{ $code } || $code,
    ])
  }

  return $zone{ $code };
}

#pod =head2 zone_for_nerd_ip
#pod
#pod   # get the zone for nerd's response for the US
#pod   my $zone = Net::Continental->zone_for_nerd_ip('127.0.3.72');
#pod
#pod =cut

sub zone_for_nerd_ip {
  my ($self, $ip) = @_;

  my ($matched, $top, $bot);
  $matched = do {
    no warnings 'uninitialized';
    ($top, $bot) = $ip =~ /\A127\.0\.([0-9]+)\.([0-9]+)\z/;
  };

  unless ($matched) {
    my $str = defined $ip ? $ip : '(undef)';
    Carp::croak("invalid input to zone_for_nerd_ip: $str");
  }

  my $cc = ($top << 8) + $bot;

  my $code = Locale::Codes::Country::country_code2code(
    $cc,
    'numeric',
    'alpha-2',
  );

  Carp::croak("unknown nerd ip $ip") unless $code;

  return $self->zone($code);
}

#pod =head2 known_zone_codes
#pod
#pod   my @codes = Net::Continental->known_zone_codes;
#pod
#pod This returns a list of all known zone codes, in no particular order.
#pod
#pod =cut

sub known_zone_codes {
  return keys %zone
}

#pod =head1 AUTHOR
#pod
#pod This code was written in 2009 by Ricardo SIGNES.
#pod
#pod The development of this code was sponsored by Pobox.com.  Thanks, Pobox!
#pod
#pod =cut


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Continental - code to map countries to continents, esp. with nerd.dk dnsbl

=head1 VERSION

version 0.016

=head1 NAME

Net::Continental - IP addresses of the world, by country and continent

=head1 METHODS

=head2 zone

  # Get the zone for the US.
  my $zone = Net::Continental->zone('us');

This returns a L<Net::Continental::Zone> object for the given ISO code.

=head2 zone_for_nerd_ip

  # get the zone for nerd's response for the US
  my $zone = Net::Continental->zone_for_nerd_ip('127.0.3.72');

=head2 known_zone_codes

  my @codes = Net::Continental->known_zone_codes;

This returns a list of all known zone codes, in no particular order.

=head1 AUTHOR

This code was written in 2009 by Ricardo SIGNES.

The development of this code was sponsored by Pobox.com.  Thanks, Pobox!

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
