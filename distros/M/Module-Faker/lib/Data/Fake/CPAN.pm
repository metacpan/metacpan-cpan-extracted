package Data::Fake::CPAN 0.027;
use v5.20.0;
use warnings;

# ABSTRACT: a Data::Fake plugin for CPAN data and distributions

# Back off, man, I'm a scientist.
use experimental qw(lexical_subs postderef signatures);

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Fake qw(CPAN);
#pod
#pod   my $dist = fake_cpan_distribution()->();
#pod
#pod   my $archive = $dist->make_archive({ dir => '.' });
#pod   say "Produced archive as $archive (cpan author: " . $dist->cpan_author . ")";
#pod   say "- $_" for sort map {; $_->name } $dist->packages;
#pod
#pod This is a Data::Fake plugin for generating CPAN distributions.  Right now, it
#pod can't be configured in any way, but future revisions might add some options.
#pod You can use this to generate libraries to test your CPAN-related tooling, to
#pod test L<PAUSE|https://pause.perl.org>.  Make 10,000 and host your own competing
#pod CPAN.  The possibilities are endless.
#pod
#pod All the C<fake_...> functions exported by Data::Fake::CPAN are exported by
#pod default, and you're meant to use them via C<use Data::Fake>.  Like the rest of
#pod Data::Fake generators, they return subroutines that you must call to get the
#pod actual faked data.
#pod
#pod =cut

use Data::Fake qw( Core Dates );
use List::Util qw(uniq);

use Sub::Exporter -setup => {
  groups  => { default => [ '-all' ] },
  exports => [ qw(
    fake_cpan_author
    fake_cpan_distribution
    fake_license
    fake_package_names
    fake_prereqs
    fake_version
  ) ],
};

#pod =func fake_cpan_author
#pod
#pod This generator generates objects representing CPAN authors.  These methods are
#pod provided
#pod
#pod =for :list
#pod * given_name - a first name from Data::Fake::Names
#pod * surname - a surname from Data::Fake::Names
#pod * full_name - given name, space, surname
#pod * pauseid - an all caps PAUSE user id
#pod * email_address - an email address
#pod * name_and_email - a string in the form "full_name <email_address>"
#pod
#pod If you call this generator many times, you might get duplicated data, but the
#pod odds are not high.
#pod
#pod =cut

sub fake_cpan_author {
  sub { Module::Faker::Blaster::Author->new }
}

#pod =func fake_cpan_distribution
#pod
#pod This creates an entire CPAN distribution, as a Module::Faker::Dist object.  It
#pod will contain at least one package, and possibly several.
#pod
#pod =cut

my sub _package ($name) {
  state $config = {
    layout => {
      pkgword => fake_weighted(
        [ package => 4 ],
        [ class   => 1 ],
        [ role    => 1 ],
      )->(),
      style   => fake_pick(qw( statement block ))->(),
      version => fake_pick(qw( our our-literal inline ))->(),
    },
  };

  return $name => $config;
}

sub fake_cpan_distribution {
  require Module::Faker::Dist;

  sub {
    my @package_names = fake_package_names(fake_int(1,6)->())->();

    my $author  = fake_cpan_author()->();

    my $ext = fake_weighted(
      [ 'tar.gz' => 4 ],
      [ zip      => 1 ],
    )->();

    my $dist = Module::Faker::Dist->from_struct({
      name    => ($package_names[0] =~ s/::/-/gr),
      version => fake_version()->(),
      authors     => [ $author->name_and_email ],
      cpan_author => $author->pauseid,
      license     => [ fake_license()->() ],
      archive_ext => $ext,
      packages    => [ map {; _package($_) } sort @package_names ],
      prereqs     => fake_prereqs()->(),
    });
  }
}

#pod =func fake_license
#pod
#pod This generator will spit out license values for a CPAN::Meta file, like
#pod C<perl_5> or C<openssl> or C<unknown>.
#pod
#pod =cut

sub fake_license {
  state @specific = qw(
    agpl_3 apache_1_1 apache_2_0 artistic_1 artistic_2 bsd freebsd gfdl_1_2
    gfdl_1_3 gpl_1 gpl_2 gpl_3 lgpl_2_1 lgpl_3_0 mit mozilla_1_0 mozilla_1_1
    openssl perl_5 qpl_1_0 ssleay sun zlib
  );

  state @general = qw( open_source restricted unrestricted unknown );

  fake_pick(@specific, @general);
}

#pod =func fake_package_names
#pod
#pod   my $generator = fake_package_names($n);
#pod
#pod The constructed generator will return I<n> package names.  The first package
#pod name will be a prefix of all the rest of the package names.
#pod
#pod =cut

my sub make_identifier ($str) {
  my @bits = split /[^A-Za-z0-9_]/, $str;
  join q{}, map {; ucfirst } @bits;
}

sub fake_package_names ($n) {
  return unless $n >= 1;

  sub {
    my @base = map { make_identifier( _noun() ) } (1 .. fake_int(1,2)->());
    my @names = join q{::}, @base;

    my @adjs = uniq map {; make_identifier( _adj() ) } (1 .. $n-1);
    push @names, map {; join q{::}, $names[0], $_ } @adjs;

    return @names;
  }
}

#pod =func fake_prereqs
#pod
#pod This generator will produce a reference to a hash that can be used as the
#pod C<prereqs> entry in a CPAN::Meta file.  Various type and phase combinations
#pod will be produced with unevenly distributed probabilities.  All package names
#pod will be faked with C<fake_package_names>.
#pod
#pod =cut

sub fake_prereqs {
  sub {
    my %prereqs;

    my $mk_phase = fake_weighted(
      [ configure =>  1 ],
      [ runtime   => 10 ],
      [ build     =>  2 ],
      [ test      =>  3 ],
      [ develop   =>  2 ],
    );

    my $mk_type = fake_weighted(
      [ conflicts   =>  1 ],
      [ recommends  =>  3 ],
      [ requires    => 15 ],
      [ suggests    =>  1 ],
    );

    for (1 .. fake_int(0, 20)->()) {
      my $phase = $mk_phase->();
      my $type  = $mk_type->();

      my ($package) = fake_package_names(1)->();
      $prereqs{$phase}{$type}{$package} = fake_version()->();
    }

    return \%prereqs;
  }
}

package Module::Faker::Blaster::Author 0.027 {
  use Moose;

  use Data::Fake::Names ();

  use v5.20.0;
  # I collect spores, molds and fungus.
  use experimental qw(lexical_subs postderef signatures);

  has given_name => (
    is      => 'ro',
    default => sub { Data::Fake::Names::fake_first_name()->() },
  );

  has surname => (
    is      => 'ro',
    default => sub { Data::Fake::Names::fake_surname()->() },
  );

  sub full_name ($self) {
    join q{ }, $self->given_name, $self->surname;
  }

  has pauseid => (
    is    => 'ro',
    lazy  => 1,
    default => sub ($self) {
      uc( substr($self->given_name, 0, 1) . substr($self->surname, 0, 7));
    },
  );

  has email_address => (
    is => 'ro',
    lazy => 1,
    default => sub ($self) {
      lc $self->pauseid . '@fakecpan.org';
    },
  );

  sub name_and_email ($self) {
    sprintf "%s <%s>", $self->full_name, $self->email_address;
  }

  no Moose;
}

my @v_generators = (
  sub {
    # n.nnn
    my $ver_x = int rand 10;
    my $ver_y = int rand 1000;

    return sprintf '%d.%03d', $ver_x, $ver_y;
  },
  sub {
    # YYYYMMDD.nnn
    my $date = fake_past_datetime('%Y%m%d')->();
    return sprintf '%d.%03d', $date, int rand 1000;
  },
  sub {
    # x.y.z
    return join q{.}, map {; int rand 20 } (1..3);
  },
);

sub fake_version {
  fake_pick(@v_generators);
}

my @ADJECTIVES = qw(
  abandoned able absolute adorable adventurous academic acceptable acclaimed
  accomplished accurate aching acidic acrobatic active actual adept admirable
  admired adolescent adorable adored advanced afraid affectionate aged
  aggravating aggressive agile agitated agonizing agreeable ajar alarmed
  alarming alert alienated alive all altruistic amazing ambitious ample amused
  amusing anchored ancient angelic angry anguished animated annual another
  antique anxious any apprehensive appropriate apt arctic arid aromatic
  artistic ashamed assured astonishing athletic attached attentive attractive
  austere authentic authorized automatic avaricious average aware awesome
  awful awkward babyish bad back baggy bare barren basic beautiful belated
  beloved beneficial better best bewitched big big-hearted biodegradable
  bite-sized bitter black black-and-white bland blank blaring bleak blind
  blissful blond blue blushing bogus boiling bold bony boring bossy both
  bouncy bountiful bowed brave breakable brief bright brilliant brisk broken
  bronze brown bruised bubbly bulky bumpy buoyant burdensome burly bustling
  busy buttery buzzing calculating calm candid canine capital carefree careful
  careless caring cautious cavernous celebrated charming cheap cheerful cheery
  chief chilly chubby circular classic clean clear clear-cut clever close
  closed cloudy clueless clumsy cluttered coarse cold colorful colorless
  colossal comfortable common compassionate competent complete complex
  complicated composed concerned concrete confused conscious considerate
  constant content conventional cooked cool cooperative coordinated corny
  corrupt costly courageous courteous crafty crazy creamy creative creepy
  criminal crisp critical crooked crowded cruel crushing cuddly cultivated
  cultured cumbersome curly curvy cute cylindrical damaged damp dangerous
  dapper daring darling dark dazzling dead deadly deafening dear dearest
  decent decimal decisive deep defenseless defensive defiant deficient
  definite definitive delayed delectable delicious delightful delirious
  demanding dense dental dependable dependent descriptive deserted detailed
  determined devoted different difficult digital diligent dim dimpled
  dimwitted direct disastrous discrete disfigured disgusting disloyal dismal
  distant downright dreary dirty disguised dishonest dismal distant distinct
  distorted dizzy dopey doting double downright drab drafty dramatic dreary
  droopy dry dual dull dutiful each eager earnest early easy easy-going
  ecstatic edible educated elaborate elastic elated elderly electric elegant
  elementary elliptical embarrassed embellished eminent emotional empty
  enchanted enchanting energetic enlightened enormous enraged entire envious
  equal equatorial essential esteemed ethical euphoric even evergreen
  everlasting every evil exalted excellent exemplary exhausted excitable
  excited exciting exotic expensive experienced expert extraneous extroverted
  extra-large extra-small fabulous failing faint fair faithful fake false
  familiar famous fancy fantastic far faraway far-flung far-off fast fat fatal
  fatherly favorable favorite fearful fearless feisty feline female feminine
  few fickle filthy fine finished firm first firsthand fitting fixed flaky
  flamboyant flashy flat flawed flawless flickering flimsy flippant flowery
  fluffy fluid flustered focused fond foolhardy foolish forceful forked formal
  forsaken forthright fortunate fragrant frail frank frayed free French fresh
  frequent friendly frightened frightening frigid frilly frizzy frivolous
  front frosty frozen frugal fruitful full fumbling functional funny fussy
  fuzzy gargantuan gaseous general generous gentle genuine giant giddy
  gigantic gifted giving glamorous glaring glass gleaming gleeful glistening
  glittering gloomy glorious glossy glum golden good good-natured gorgeous
  graceful gracious grand grandiose granular grateful grave gray great greedy
  green gregarious grim grimy gripping grizzled gross grotesque grouchy
  grounded growing growling grown grubby gruesome grumpy guilty gullible gummy
  hairy half handmade handsome handy happy happy-go-lucky hard hard-to-find
  harmful harmless harmonious harsh hasty hateful haunting healthy heartfelt
  hearty heavenly heavy hefty helpful helpless hidden hideous high high-level
  hilarious hoarse hollow homely honest honorable honored hopeful horrible
  hospitable hot huge humble humiliating humming humongous hungry hurtful
  husky icky icy ideal idealistic identical idle idiotic idolized ignorant ill
  illegal ill-fated ill-informed illiterate illustrious imaginary imaginative
  immaculate immaterial immediate immense impassioned impeccable impartial
  imperfect imperturbable impish impolite important impossible impractical
  impressionable impressive improbable impure inborn incomparable incompatible
  incomplete inconsequential incredible indelible inexperienced indolent
  infamous infantile infatuated inferior infinite informal innocent insecure
  insidious insignificant insistent instructive insubstantial intelligent
  intent intentional interesting internal international intrepid ironclad
  irresponsible irritating itchy jaded jagged jam-packed jaunty jealous
  jittery joint jolly jovial joyful joyous jubilant judicious juicy jumbo
  junior jumpy juvenile kaleidoscopic keen key kind kindhearted kindly klutzy
  knobby knotty knowledgeable knowing known kooky kosher lame lanky large last
  lasting late lavish lawful lazy leading lean leafy left legal legitimate
  light lighthearted likable likely limited limp limping linear lined liquid
  little live lively livid loathsome lone lonely long long-term loose lopsided
  lost loud lovable lovely loving low loyal lucky lumbering luminous lumpy
  lustrous luxurious mad made-up magnificent majestic major male mammoth
  married marvelous masculine massive mature meager mealy mean measly meaty
  medical mediocre medium meek mellow melodic memorable menacing merry messy
  metallic mild milky mindless miniature minor minty miserable miserly
  misguided misty mixed modern modest moist monstrous monthly monumental moral
  mortified motherly motionless mountainous muddy muffled multicolored mundane
  murky mushy musty muted mysterious naive narrow nasty natural naughty
  nautical near neat necessary needy negative neglected negligible neighboring
  nervous new next nice nifty nimble nippy nocturnal noisy nonstop normal
  notable noted noteworthy novel noxious numb nutritious nutty obedient obese
  oblong oily oblong obvious occasional odd oddball offbeat offensive official
  old old-fashioned only open optimal optimistic opulent orange orderly
  organic ornate ornery ordinary original other our outlying outgoing
  outlandish outrageous outstanding oval overcooked overdue overjoyed
  overlooked palatable pale paltry parallel parched partial passionate past
  pastel peaceful peppery perfect perfumed periodic perky personal pertinent
  pesky pessimistic petty phony physical piercing pink pitiful plain plaintive
  plastic playful pleasant pleased pleasing plump plush polished polite
  political pointed pointless poised poor popular portly posh positive
  possible potable powerful powerless practical precious present prestigious
  pretty precious previous pricey prickly primary prime pristine private prize
  probable productive profitable profuse proper proud prudent punctual pungent
  puny pure purple pushy putrid puzzled puzzling quaint qualified quarrelsome
  quarterly queasy querulous questionable quick quick-witted quiet
  quintessential quirky quixotic quizzical radiant ragged rapid rare rash raw
  recent reckless rectangular ready real realistic reasonable red reflecting
  regal regular reliable relieved remarkable remorseful remote repentant
  required respectful responsible repulsive revolving rewarding rich rigid
  right ringed ripe roasted robust rosy rotating rotten rough round rowdy
  royal rubbery rundown ruddy rude runny rural rusty sad safe salty same sandy
  sane sarcastic sardonic satisfied scaly scarce scared scary scented
  scholarly scientific scornful scratchy scrawny second secondary second-hand
  secret self-assured self-reliant selfish sentimental separate serene serious
  serpentine several severe shabby shadowy shady shallow shameful shameless
  sharp shimmering shiny shocked shocking shoddy short short-term showy shrill
  shy sick silent silky silly silver similar simple simplistic sinful single
  sizzling skeletal skinny sleepy slight slim slimy slippery slow slushy small
  smart smoggy smooth smug snappy snarling sneaky sniveling snoopy sociable
  soft soggy solid somber some spherical sophisticated sore sorrowful soulful
  soupy sour Spanish sparkling sparse specific spectacular speedy spicy spiffy
  spirited spiteful splendid spotless spotted spry square squeaky squiggly
  stable staid stained stale standard starchy stark starry steep sticky stiff
  stimulating stingy stormy straight strange steel strict strident striking
  striped strong studious stunning stupendous stupid sturdy stylish subdued
  submissive substantial subtle suburban sudden sugary sunny super superb
  superficial superior supportive sure-footed surprised suspicious svelte
  sweaty sweet sweltering swift sympathetic tall talkative tame tan tangible
  tart tasty tattered taut tedious teeming tempting tender tense tepid
  terrible terrific testy thankful that these thick thin third thirsty this
  thorough thorny those thoughtful threadbare thrifty thunderous tidy tight
  timely tinted tiny tired torn total tough traumatic treasured tremendous
  tragic trained tremendous triangular tricky trifling trim trivial troubled
  true trusting trustworthy trusty truthful tubby turbulent twin ugly ultimate
  unacceptable unaware uncomfortable uncommon unconscious understated
  unequaled uneven unfinished unfit unfolded unfortunate unhappy unhealthy
  uniform unimportant unique united unkempt unknown unlawful unlined unlucky
  unnatural unpleasant unrealistic unripe unruly unselfish unsightly unsteady
  unsung untidy untimely untried untrue unused unusual unwelcome unwieldy
  unwilling unwitting unwritten upbeat upright upset urban usable used useful
  useless utilized utter vacant vague vain valid valuable vapid variable vast
  velvety venerated vengeful verifiable vibrant vicious victorious vigilant
  vigorous villainous violet violent virtual virtuous visible vital vivacious
  vivid voluminous wan warlike warm warmhearted warped wary wasteful watchful
  waterlogged watery wavy wealthy weak weary webbed wee weekly weepy weighty
  weird welcome well-documented well-groomed well-informed well-lit well-made
  well-off well-to-do well-worn wet which whimsical whirlwind whispered white
  whole whopping wicked wide wide-eyed wiggly wild willing wilted winding
  windy winged wiry wise witty wobbly woeful wonderful wooden woozy wordy
  worldly worn worried worrisome worse worst worthless worthwhile worthy
  wrathful wretched writhing wrong wry yawning yearly yellow yellowish young
  youthful yummy zany zealous zesty
);

my @NOUNS = qw(
  ability accident activity actor ad addition administration advertising
  advice agency agreement airport alcohol analysis anxiety apartment
  appearance application appointment area argument army arrival art article
  aspect assistance association assumption atmosphere attention attitude
  audience awareness baseball basis basket bath bird blood bonus boyfriend
  bread breath buyer cabinet camera cancer candidate category cell chapter
  charity chemistry chest child childhood chocolate church cigarette city
  classroom climate clothes coffee collection college combination committee
  communication community comparison competition complaint computer concept
  conclusion confusion connection construction context contract contribution
  control conversation cookie country county courage cousin criticism currency
  customer dad data database dealer death debt decision definition delivery
  department depression depth description desk development device difference
  difficulty dinner direction director disaster discussion disease disk
  distribution drama drawer drawing driver economics editor education
  efficiency effort election elevator emotion emphasis employee employer
  employment energy engine engineering entertainment enthusiasm entry
  environment equipment error establishment estate event exam examination
  excitement explanation expression extent fact failure family farmer feedback
  finding fishing flight food football foundation freedom garbage gate girl
  goal government grandmother grocery growth guest guidance guitar hair hall
  health hearing heart height highway historian history homework honey
  hospital hotel housing idea imagination importance impression improvement
  income independence industry inflation information initiative injury insect
  inspection inspector instance instruction insurance interaction internet
  introduction investment judgment king knowledge lab ladder lake language law
  leader leadership length library literature location loss love magazine
  maintenance mall management manager manufacturer map marketing marriage math
  meal meaning measurement meat media medicine member membership memory menu
  message method mixture mode mom moment month mood movie mud music nation
  nature news newspaper night office operation opinion opportunity orange
  organization outcome oven owner painting paper passion patience payment
  penalty people percentage perception performance permission person
  personality perspective philosophy phone photo physics piano pie player poem
  poetry police policy politics population possession possibility potato power
  preference preparation presence presentation president priority problem
  procedure product profession professor promotion property proposal
  protection psychology quality quantity queen ratio reaction reading reality
  reception recipe recommendation recording reflection refrigerator region
  relation relationship replacement republic requirement resolution resource
  response responsibility restaurant revenue revolution river road role safety
  salad sample satisfaction scene science secretary sector security selection
  series session setting shopping signature significance singer sister
  situation skill society software solution son song soup speech statement
  steak storage story strategy student studio success suggestion supermarket
  system tea teacher teaching technology television temperature tennis tension
  thanks theory thing thought tongue tooth topic town tradition transportation
  truth two understanding union unit university user variation variety vehicle
  version video village virus volume warning way weakness wealth wedding week
  wife winner woman wood worker world writer writing year
);

sub _noun { return $NOUNS[ rand @NOUNS ] }
sub _adj  { return $ADJECTIVES[ rand @ADJECTIVES ] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::CPAN - a Data::Fake plugin for CPAN data and distributions

=head1 VERSION

version 0.027

=head1 SYNOPSIS

  use Data::Fake qw(CPAN);

  my $dist = fake_cpan_distribution()->();

  my $archive = $dist->make_archive({ dir => '.' });
  say "Produced archive as $archive (cpan author: " . $dist->cpan_author . ")";
  say "- $_" for sort map {; $_->name } $dist->packages;

This is a Data::Fake plugin for generating CPAN distributions.  Right now, it
can't be configured in any way, but future revisions might add some options.
You can use this to generate libraries to test your CPAN-related tooling, to
test L<PAUSE|https://pause.perl.org>.  Make 10,000 and host your own competing
CPAN.  The possibilities are endless.

All the C<fake_...> functions exported by Data::Fake::CPAN are exported by
default, and you're meant to use them via C<use Data::Fake>.  Like the rest of
Data::Fake generators, they return subroutines that you must call to get the
actual faked data.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 FUNCTIONS

=head2 fake_cpan_author

This generator generates objects representing CPAN authors.  These methods are
provided

=over 4

=item *

given_name - a first name from Data::Fake::Names

=item *

surname - a surname from Data::Fake::Names

=item *

full_name - given name, space, surname

=item *

pauseid - an all caps PAUSE user id

=item *

email_address - an email address

=item *

name_and_email - a string in the form "full_name <email_address>"

=back

If you call this generator many times, you might get duplicated data, but the
odds are not high.

=head2 fake_cpan_distribution

This creates an entire CPAN distribution, as a Module::Faker::Dist object.  It
will contain at least one package, and possibly several.

=head2 fake_license

This generator will spit out license values for a CPAN::Meta file, like
C<perl_5> or C<openssl> or C<unknown>.

=head2 fake_package_names

  my $generator = fake_package_names($n);

The constructed generator will return I<n> package names.  The first package
name will be a prefix of all the rest of the package names.

=head2 fake_prereqs

This generator will produce a reference to a hash that can be used as the
C<prereqs> entry in a CPAN::Meta file.  Various type and phase combinations
will be produced with unevenly distributed probabilities.  All package names
will be faked with C<fake_package_names>.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
