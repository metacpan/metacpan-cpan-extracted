
package Plack::Middleware::DetectRobots;
$Plack::Middleware::DetectRobots::VERSION = '0.03';
# ABSTRACT: Automatically set a flag in the environment if a robot client is detected

use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( env_key basic_check extended_check generic_check local_regexp );
use Regexp::Assemble qw();
use feature 'state';

sub prepare_app {
	my $self = shift;
	$self->basic_check(1) unless defined $self->basic_check;
	return;
}

sub call {
	my ( $self, $env ) = @_;

	state $reList   = _read_list();
	state $basic    = _assemble( $reList, 'basic' );
	state $extended = _assemble( $reList, 'extended' );
	state $generic  = _assemble( $reList, 'generic' );
	$reList = undef;

	my $key = defined( $self->env_key ) ? $self->env_key : 'robot_client';

	my $ua = $env->{'HTTP_USER_AGENT'};

	$env->{$key} = 0;

	my $local = $self->local_regexp;
	if ( defined($local) and ( ref $local eq ref qr// ) and ( $ua =~ $local ) ) {
		$env->{$key} = 'LOCAL';
	}

	if ( !$env->{$key} and $self->basic_check ) {
		if ( $ua =~ $basic ) {
			$env->{$key} = 'BASIC';
		}
	}

	if ( !$env->{$key} and $self->extended_check ) {
		if ( $ua =~ $extended ) {
			$env->{$key} = 'EXTENDED';
		}
	}

	if ( !$env->{$key} and $self->generic_check ) {
		if ( $ua =~ $generic ) {
			$env->{$key} = 'GENERIC';
		}
	}

	return $self->app->($env);
} ## end sub call

sub _assemble {
	my ( $bots, $type ) = @_;

	my $ra = Regexp::Assemble->new( flags => 'i' );
	foreach my $r ( @{ $bots->{$type} } ) {
		$ra->add($r);
	}

	return $ra->re;
}

sub _read_list {
	my $bots = { basic => [], extended => [], generic => [], };
	my $currentType = 'basic';

	state $pos = tell(Plack::Middleware::DetectRobots::DATA);
	if ( $ENV{'HARNESS_ACTIVE'} ) {
		seek( Plack::Middleware::DetectRobots::DATA, $pos, 0 );
	}

	while (<Plack::Middleware::DetectRobots::DATA>) {
		chomp;
		next unless $_;
		$currentType = 'extended' if /\A##\s+EXTENDED/;
		$currentType = 'generic'  if /\A##\s+GENERIC/;

		push @{ $bots->{$currentType} }, $_;
	}

	if ( !$ENV{'HARNESS_ACTIVE'} ) {
		close Plack::Middleware::DetectRobots::DATA;
	}

	return $bots;
}

1;

=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::DetectRobots - Automatically set a flag in the environment if a robot client is detected

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub { ... } # as usual

  builder {
      enable 'DetectRobots';
	  # or: enable 'DetectRobots', env_key => 'psgix.robot_client';
	  # or: enable 'DetectRobots', extended_check => 1, generic_check => 1;
      $app;
  };

  # ... and later ...
  
  if ( $env->{'robot_client'} ) {
      # ... do something ...
  }

=head1 DESCRIPTION

This Plack middleware uses the list of robots that is part of the 
L<AWStats log analyzer|http://awstats.org/> software package to 
analyse the C<User-Agent> HTTP header and to set an environment 
flag to either a true or false value depending on the detection 
of a robot client.

Once activated it checks the User-Agent HTTP header against a 
basic list of patterns for common bots.

If you activate the appropriate options, it can also use an extended
list for the detection of less common bots (cf. C<extended_check>)
and / or a list of quite generic patterns to detect unknown bots
(cf. C<generic_check>).

You may also pass in your own regular expression as a string for
further checks (cf. <local_regexp>).

The checks are executed in this order:

B<1.> Local regular expression

B<2.> Basic check

B<3.> Extended check

B<4.> Generic check

If a check yields a positive result (i.e.: detects a bot) the
remaining checks are skipped.

Depending on the check which detected a bot, the environment flag
is set to one of these values: C<LOCAL>, C<BASIC>, C<EXTENDED>, or
C<GENERIC>.

If no bot is detected, the flag is set to C<0>.

The default name of the flag in the environment is C<robot_client>,
but this can be customized by setting the C<env_key> option when 
enabling this middleware.

It might make sense to use C<psgix.robot_client> by default instead,
but the PSGI spec states that the "'psgix.' prefix is reserved for 
officially blessed extensions" - which does not apply to this module.
You may, however, set the key to C<psgix.robot_client> yourself
by using the C<env_key> option mentioned before.

=head1 WARNING

This software is currently considered BETA and still needs to
be seriously tested!

=head1 ROBOTS LIST

Based on B<Revision 2d289e, 2014-11-20> of
L<http://sourceforge.net/p/awstats/code/ci/develop/tree/wwwroot/cgi-bin/lib/robots.pm>.

B<Note:> that list might be somewhat dated, as I did not find bingbot
in the list of common bots (only in the extended list) while it's 
predecessor msnbot was considered common.

=head1 CONFIGURATION

You may specify the following option when enabling the middleware:

=over 4

=item C<env_key>

Set the name of the entry in the environment hash.

=item C<basic_check>

You may deactivate the standard checks by setting this option to
a false value. E.g. if your are only interested in obscure bots
or in your local pattern checks.

By setting this option to a false value while simultaneously 
passing a regular expression to C<local_regexp> one can imitate
the behaviour of L<Plack::Middleware::BotDetector>.

=item C<extended_check>

Determines if an extended list of less often seen robots is also
checked for.
By default, only common robots are checked for, because the extended
check requires a rather large and complex regular expression.
Set this param to a true value to change the default behaviour.

=item C<generic_check>

Determines if the User-Agent string is also analysed to determine
if it contains certain strings that generically identify the
client as a bot, e.g. "spider" or "crawler"
By default, this check is not performed, even though it uses only
a relatively short and simple regex..
Set this param to a true value to change the default behaviour.

=item C<local_regexp>

You may optionally pass in your own regular expression (as a Regexp
object using C<qr//>) to check for additional patterns in the 
User-Agent string.

=back

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Plack::Middleware::BotDetector>,
L<http://awstats.org/>

The functionality provided by C<Plack::Middleware::BotDetector> is 
basically the same as that of this module, but it requires you to 
pass in your own regular expression and does not include a default
list of known bots.

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
appie
architext
baiduspider
bingbot
bingpreview
bjaaland
contentmatch
ferret
googlebot\-image
googlebot
google\-sitemaps
google[_+\s]web[_+\s]preview
grabber
gulliver
virus[_+\s]detector
harvest
htdig
jeeves
linkwalker
lilina
lycos[_+\s]
moget
muscatferret
myweb
nomad
scooter
slurp
^voyager\/
weblayers
antibot
bruinbot
digout4u
echo!
fast\-webcrawler
ia_archiver\-web\.archive\.org
ia_archiver
jennybot
mercator
netcraft
msnbot\-media
petersnews
relevantnoise\.com
unlost_web_crawler
voila
webbase
webcollage
cfetch
zyborg
wisenutbot
## EXTENDED
[^a]fish
abcdatos
abonti\.com
acme\.spider
ahoythehomepagefinder
ahrefsbot
alkaline
anthill
arachnophilia
arale
araneo
aretha
ariadne
powermarks
arks
aspider
atn\.txt
atomz
auresys
backrub
bbot
bigbrother
blackwidow
blindekuh
bloodhound
borg\-bot
brightnet
bspider
cactvschemistryspider
calif[^r]
cassandra
cgireader
checkbot
christcrawler
churl
cienciaficcion
collective
combine
conceptbot
coolbot
core
cosmos
cruiser
cusco
cyberspyder
desertrealm
deweb
dienstspider
digger
diibot
direct_hit
dnabot
download_express
dragonbot
dwcp
e\-collector
ebiness
elfinbot
emacs
emcspider
esther
evliyacelebi
fastcrawler
feedcrawl
fdse
felix
fetchrover
fido
finnish
fireball
fouineur
francoroute
freecrawl
funnelweb
gama
gazz
gcreep
getbot
geturl
golem
gougou
grapnel
griffon
gromit
gulperbot
hambot
havindex
hometown
htmlgobble
hyperdecontextualizer
iajabot
iaskspider
hl_ftien_spider
sogou
icjobs\.de
iconoclast
ilse
imagelock
incywincy
informant
infoseek
infoseeksidewinder
infospider
inspectorwww
intelliagent
irobot
iron33
israelisearch
javabee
jbot
jcrawler
jobo
jobot
joebot
jubii
jumpstation
kapsi
katipo
kilroy
ko[_+\s]yappo[_+\s]robot
kummhttp
labelgrabber\.txt
larbin
legs
linkidator
linkscan
lockon
logo_gif
macworm
magpie
marvin
mattie
mediafox
merzscope
meshexplorer
mindcrawler
mnogosearch
momspider
monster
motor
msnbot
muncher
mwdsearch
ndspider
nederland\.zoek
netcarta
netmechanic
netscoop
newscan\-online
nhse
northstar
nzexplorer
objectssearch
occam
octopus
openfind
orb_search
packrat
pageboy
parasite
patric
pegasus
perignator
perlcrawler
phantom
phpdig
piltdownman
pimptrain
pioneer
pitkow
pjspider
plumtreewebaccessor
poppi
portalb
psbot
python
raven
rbse
resumerobot
rhcs
road_runner
robbie
robi
robocrawl
robofox
robozilla
roverbot
rules
safetynetrobot
search\-info
search_au
searchprocess
senrigan
sgscout
shaggy
shaihulud
sift
simbot
site\-valet
sitetech
skymob
slcrawler
smartspider
snooper
solbot
speedy
spider[_+\s]monkey
spiderbot
spiderline
spiderman
spiderview
spry
sqworm
ssearcher
suke
sunrise
suntek
sven
tach_bw
tagyu_agent
tailrank
tarantula
tarspider
techbot
templeton
titan
titin
tkwww
tlspider
ucsd
udmsearch
universalfeedparser
urlck
valkyrie
verticrawl
victoria
visionsearch
voidbot
vwbot
w3index
w3m2
wallpaper
wanderer
wapspIRLider
webbandit
webcatcher
webcopy
webfetcher
webfoot
webinator
weblinker
webmirror
webmoose
webquest
webreader
webreaper
websnarf
webspider
webvac
webwalk
webwalker
webwatch
whatuseek
whowhere
wired\-digital
wmir
wolp
wombat
wordpress
worm
woozweb
wwwc
wz101
xget
1\-more_scanner
360spider
a6-indexer
accoona\-ai\-agent
activebookmark
adamm_bot
adsbot-google
almaden
aipbot
aleadsoftbot
alpha_search_agent
allrati
aport
archive\.org_bot
argus
arianna\.libero\.it
aspseek
asterias
awbot
backlinktest\.com
becomebot
bender
betabot
biglotron
bittorrent_bot
biz360[_+\s]spider
blogbridge[_+\s]service
bloglines
blogpulse
blogsearch
blogshares
blogslive
blogssay
bncf\.firenze\.sbn\.it\/raccolta\.txt
bobby
boitho\.com\-dc
bookmark\-manager
boris
bubing
bumblebee
candlelight[_+\s]favorites[_+\s]inspector
careerbot
cbn00glebot
cerberian_drtrs
cfnetwork
cipinetbot
checkweb_link_validator
commons\-httpclient
computer_and_automation_research_institute_crawler
converamultimediacrawler
converacrawler
copubbot
cscrawler
cse_html_validator_lite_online
cuasarbot
cursor
custo
datafountains\/dmoz_downloader
dataprovider\.com
daumoa
daviesbot
daypopbot
deepindex
dipsie\.bot
dnsgroup
domainchecker
domainsdb\.net
dulance
dumbot
dumm\.de\-bot
earthcom\.info
easydl
eccp
edgeio\-retriever
ets_v
exactseek
extreme[_+\s]picture[_+\s]finder
eventax
everbeecrawler
everest\-vulcan
ezresult
enteprise
facebook
fast_enterprise_crawler.*crawleradmin\.t\-info@telekom\.de
fast_enterprise_crawler.*t\-info_bi_cluster_crawleradmin\.t\-info@telekom\.de
matrix_s\.p\.a\._\-_fast_enterprise_crawler
fast_enterprise_crawler
fast\-search\-engine
favicon
favorg
favorites_sweeper
feedburner
feedfetcher\-google
feedflow
feedster
feedsky
feedvalidator
filmkamerabot
filterdb\.iss\.net
findlinks
findexa_crawler
firmilybot
foaf-search\.net
fooky\.com\/ScorpionBot
g2crawler
gaisbot
geniebot
gigabot
girafabot
global_fetch
gnodspider
goforit\.com
goforitbot
gonzo
grapeshot
grub
gpu_p2p_crawler
henrythemiragorobot
heritrix
holmes
hoowwwer
hpprint
htmlparser
html[_+\s]link[_+\s]validator
httrack
hundesuche\.com\-bot
i-bot
ichiro
iltrovatore\-setaccio
infobot
infociousbot
infohelfer
infomine
insurancobot
integromedb\.org
internet[_+\s]ninja
internetarchive
internetseer
internetsupervision
ips\-agent
irlbot
isearch2006
istellabot
iupui_research_bot
jrtwine[_+\s]software[_+\s]check[_+\s]favorites[_+\s]utility
justview
kalambot
kamano\.de_newsfeedverzeichnis
kazoombot
kevin
keyoshid
kinjabot
kinja\-imagebot
knowitall
knowledge\.com
kouaa_krawler
krugle
ksibot
kurzor
lanshanbot
letscrawl\.com
libcrawl
linkbot
linkdex\.com
link_valet_online
metager\-linkchecker
linkchecker
livejournal\.com
lmspider
ltbot
lwp\-request
lwp\-trivial
magpierss
mail\.ru
mapoftheinternet\.com
mediapartners\-google
megite
metaspinner
miadev
microsoft bits
microsoft.*discovery
microsoft[_+\s]url[_+\s]control
mini\-reptile
minirank
missigua_locator
misterbot
miva
mizzu_labs
mj12bot
mojeekbot
msiecrawler
ms_search_4\.0_robot
msrabot
msrbot
mt::telegraph::agent
mydoyouhike
nagios
nasa_search
netestate ne crawler
netluchs
netsprint
newsgatoronline
nicebot
nimblecrawler
noxtrumbot
npbot
nutchcvs
nutchosu\-vlib
nutch
ocelli
octora_beta_bot
omniexplorer[_+\s]bot
onet\.pl[_+\s]sa
onfolio
opentaggerbot
openwebspider
oracle_ultra_search
orbiter
yodaobot
qihoobot
passwordmaker\.org
pear_http_request_class
peerbot
perman
php[_+\s]version[_+\s]tracker
pictureofinternet
ping\.blo\.gs
plinki
pluckfeedcrawler
pogodak
pompos
popdexter
port_huron_labs
postfavorites
projectwf\-java\-test\-crawler
proodlebot
pyquery
rambler
redalert
rojo
rssimagesbot
ruffle
rufusbot
sandcrawler
sbider
schizozilla
scumbot
searchguild[_+\s]dmoz[_+\s]experiment
searchmetricsbot
seekbot
semrushbot
sensis_web_crawler
seokicks\.de
seznambot
shim\-crawler
shoutcast
siteexplorer\.info
slysearch
snap\.com_beta_crawler
sohu\-search
sohu
snappy
spbot
sphere_scout
spiderlytics
spip
sproose_crawler
ssearch_bot
steeler
steroid__download
suchfin\-bot
superbot
surveybot
susie
syndic8
syndicapi
synoobot
tcl_http_client_package
technoratibot
teragramcrawlersurf
test_crawler
testbot
t\-h\-u\-n\-d\-e\-r\-s\-t\-o\-n\-e
topicblogs
turnitinbot
turtlescanner
turtle
tutorgigbot
twiceler
ubicrawler
ultraseek
unchaos_bot_hybrid_web_search_engine
unido\-bot
unisterbot
updated
ustc\-semantic\-group
vagabondo\-wap
vagabondo
vermut
versus_crawler_from_eda\.baykan@epfl\.ch
vespa_crawler
vortex
vse\/
w3c\-checklink
w3c[_+\s]css[_+\s]validator[_+\s]jfouffa
w3c_validator
watchmouse
wavefire
waybackarchive\.org
webclipping\.com
webcompass
webcrawl\.net
web_downloader
webdup
webfilter
webindexer
webminer
website[_+\s]monitoring[_+\s]bot
webvulncrawl
wells_search
wesee:search
wonderer
wume_crawler
wwweasel
xenu\'s_link_sleuth
xenu_link_sleuth
xirq
y!j
yacy
yahoo\-blogs
yahoo\-verticalcrawler
yahoofeedseeker
yahooseeker\-testing
yahooseeker
yahoo\-mmcrawler
yahoo!_mindset
yandex
flexum
yanga
yet-another-spider
yooglifetchagent
z\-add_link_checker
zealbot
zhuaxia
zspider
zeus
ng\/1\.
ng\/2\.
exabot
^[1-3]$
alltop
applesyndication
asynchttpclient
blogged_crawl
bloglovin
butterfly
buzztracker
carpathia
catbot
chattertrap
check_http
coldfusion
covario
daylifefeedfetcher
discobot
dlvr\.it
dreamwidth
drupal
ezoom
feedmyinbox
feedroll\.com
feedzira
fever\/
freenews
geohasher
hanrss
inagist
jacobin club
jakarta
js\-kit
largesmall crawler
linkedinbot
longurl
metauri
microsoft\-webdav\-miniredir
^motorola$
movabletype
^mozilla\/3\.0\s+\(compatible$
^mozilla\/4\.0$
^mozilla\/4\.0\s+\(compatible;\)$
^mozilla\/5\.0$
^mozilla\/5\.0\s+\(compatible;$
^mozilla\/5\.0\s+\(en\-us\)$
^mozilla\/5\.0\s+firefox\/3\.0\.5$
^msie
netnewswire
 netseer 
netvibes
newrelicpinger
newsfox
nextgensearchbot
ning
pingdom
pita
postpost
postrank
printfulbot
protopage
proximic
quipply
r6\_
ratingburner
regator
rome client
rpt\-httpclient
rssgraffiti
sage\+\+
scoutjet
simplepie
sitebot
summify\.com
superfeedr
synthesio
teoma
topblogsinfo
topix\.net
trapit
trileet
tweetedtimes
twisted pagegetter
twitterbot
twitterfeed
unwindfetchor
wazzup
windows\-rss\-platform
wiumi
xydo
yahoo! slurp
yahoo pipes
yahoo\-newscrawler
yahoocachesystem
yahooexternalcache
yahoo! searchmonkey
yahooysmcm
yammer
yeti
yie8
youdao
yourls
zemanta
zend_http_client
zumbot
wget
libwww
^java\/[0-9]
## GENERIC
robot
checker
crawl
discovery
hunter
scanner
spider
sucker
bot[\s_+:,\.\;\/\\\-]
[\s_+:,\.\;\/\\\-]bot
curl
php
ruby\/
no_user_agent

