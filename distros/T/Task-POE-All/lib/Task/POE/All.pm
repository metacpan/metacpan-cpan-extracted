#
# This file is part of Task-POE-All
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Task::POE::All;
# git description: release-1.101-3-g74c7309
$Task::POE::All::VERSION = '1.102';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: All of POE on CPAN

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Task::POE::All - All of POE on CPAN

=head1 VERSION

  This document describes v1.102 of Task::POE::All - released November 09, 2014 as part of Task-POE-All.

=head1 SYNOPSIS

	# apoc@box:~$ cpanp install Task::POE::All

=head1 DESCRIPTION

This task contains all distributions under the L<POE> namespace.

=head1 TASK CONTENTS

=head2 Servers

=head3 L<POE::Component::Server::AsyncEndpoint> 0.10

=head3 L<POE::Component::Server::Bayeux> 0.04

=head3 L<POE::Component::Server::BigBrother> 0.08

=head3 L<POE::Component::Server::Chargen> 1.14

=head3 L<POE::Component::Server::DNS> 0.30

=head3 L<POE::Component::Server::Daytime> 1.14

=head3 L<POE::Component::Server::Discard> 1.14

=head3 L<POE::Component::Server::Echo> 1.64

=head3 L<POE::Component::Server::FTP> 0.08

=head3 L<POE::Component::Server::HTTP> 0.09

=head3 L<POE::Component::Server::HTTP::KeepAlive> 0.0307

=head3 L<POE::Component::Server::HTTPServer> 0.009002

=head3 L<POE::Component::Server::IRC> 1.54

=head3 L<POE::Component::Server::Ident> 1.16

=head3 L<POE::Component::Server::Inet> 0.06

=head3 L<POE::Component::Server::JSONRPC> 0.05

=head3 L<POE::Component::Server::MySQL> 0.02

=head3 L<POE::Component::Server::NNTP> 1.04

=head3 L<POE::Component::Server::NRPE> 0.18

=head3 L<POE::Component::Server::NSCA> 0.08

=head3 L<POE::Component::Server::POP3> 0.10

=head3 L<POE::Component::Server::PSGI> 0.6

=head3 L<POE::Component::Server::Postfix> 0.001

=head3 L<POE::Component::Server::PreforkTCP> 0.11

=head3 L<POE::Component::Server::Qotd> 1.14

=head3 L<POE::Component::Server::RADIUS> 1.08

=head3 L<POE::Component::Server::SMTP> 1.6

=head3 L<POE::Component::Server::SOAP> 1.14

=head3 L<POE::Component::Server::SimpleContent> 1.14

=head3 L<POE::Component::Server::SimpleHTTP> 2.18

=head3 L<POE::Component::Server::SimpleHTTP::PreFork> 2.10

=head3 L<POE::Component::Server::SimpleSMTP> 1.50

=head3 L<POE::Component::Server::SimpleXMLRPC> 0.02

=head3 L<POE::Component::Server::Syslog> 1.20

=head3 L<POE::Component::Server::TCP> 1.365

=head3 L<POE::Component::Server::TacacsPlus> 1.11

=head3 L<POE::Component::Server::Time> 1.14

=head3 L<POE::Component::Server::Twirc> 0.17

=head3 L<POE::Component::Server::XMLRPC> 0.05

=head3 L<POE::Component::Server::eris> 1.8

=head2 Clients

=head3 L<POE::Component::Client::AMQP> 0.03

=head3 L<POE::Component::Client::AirTunes> 0.01

=head3 L<POE::Component::Client::Asterisk::Manager> 0.08

=head3 L<POE::Component::Client::BigBrother> 1.00

=head3 L<POE::Component::Client::CouchDB> 0.05

=head3 L<POE::Component::Client::DNS> 1.053

=head3 L<POE::Component::Client::DNS::Recursive> 1.08

=head3 L<POE::Component::Client::DNSBL> 1.08

=head3 L<POE::Component::Client::FTP> 0.22

=head3 L<POE::Component::Client::Feed> 0.901

=head3 L<POE::Component::Client::HTTP> 0.949

=head3 L<POE::Component::Client::HTTPDeferred> 0.02

=head3 L<POE::Component::Client::Halo> 0.2

=head3 L<POE::Component::Client::Icecast> 0.6

=head3 L<POE::Component::Client::Ident> 1.16

=head3 L<POE::Component::Client::Keepalive> 0.272

=head3 L<POE::Component::Client::LDAP> 0.04

=head3 L<POE::Component::Client::Lingr> 0.04

=head3 L<POE::Component::Client::MPD> 2.000

=head3 L<POE::Component::Client::MSN> 0.03

=head3 L<POE::Component::Client::MogileFS> 0.02

=head3 L<POE::Component::Client::NNTP> 2.22

=head3 L<POE::Component::Client::NNTP::Tail> 0.03

=head3 L<POE::Component::Client::NRPE> 0.20

=head3 L<POE::Component::Client::NSCA> 0.16

=head3 L<POE::Component::Client::NTP> 0.10

=head3 L<POE::Component::Client::POP3> 0.02

=head3 L<POE::Component::Client::Pastebot> 1.16

=head3 L<POE::Component::Client::Ping> 1.174

=head3 L<POE::Component::Client::RADIUS> 1.04

=head3 L<POE::Component::Client::Rcon> 0.23

=head3 L<POE::Component::Client::SMTP> 0.22

=head3 L<POE::Component::Client::SOCKS> 1.00

=head3 L<POE::Component::Client::SimpleFTP> 0.003

=head3 L<POE::Component::Client::Stomp> 0.12

=head3 L<POE::Component::Client::Stomp::Utils> 0.02

=head3 L<POE::Component::Client::TCPMulti> 0.0524

=head3 L<POE::Component::Client::Telnet> 0.06

=head3 L<POE::Component::Client::Traceroute> 0.21

=head3 L<POE::Component::Client::Twitter> 0.01

=head3 L<POE::Component::Client::UserAgent> 0.08

=head3 L<POE::Component::Client::Whois> 1.30

=head3 L<POE::Component::Client::Whois::Smart> 0.187

=head3 L<POE::Component::Client::eris> 1.4

=head3 L<POE::Component::Client::opentick> 0.21

=head2 Generic Components

=head3 L<POE::Component::AI::MegaHAL> 1.18

=head3 L<POE::Component::AIO> 1.00

=head3 L<POE::Component::Algorithm::Evolutionary> 0.002001

=head3 L<POE::Component::Amazon::S3> 0.01

=head3 L<POE::Component::Archive::Any> 0.002

=head3 L<POE::Component::AssaultCube::ServerQuery::Server> 0.04

=head3 L<POE::Component::AtomAggregator> 1.0

=head3 L<POE::Component::Basement> 0.01

=head3 L<POE::Component::BlogCloud> 0.01

=head3 L<POE::Component::Bundle::WebDevelopment> 1.001004

=head3 L<POE::Component::CD::Detect> 1.1

=head3 L<POE::Component::CD::Rip> 1.2

=head3 L<POE::Component::CPAN::Mirror::Multiplexer> 0.04

=head3 L<POE::Component::CPAN::Reporter> 0.06

=head3 L<POE::Component::CPAN::SQLite::Info> 0.11

=head3 L<POE::Component::CPAN::YACSmoke> 1.36

=head3 L<POE::Component::CPANIDX> 0.10

=head3 L<POE::Component::CPANPLUS::YACSmoke> 1.62

=head3 L<POE::Component::Cache> 0.001001

=head3 L<POE::Component::Captcha::reCAPTCHA> 0.02

=head3 L<POE::Component::Child> 1.39

=head3 L<POE::Component::ControlPort> 1.0266

=head3 L<POE::Component::Cron> 0.021

=head3 L<POE::Component::Curl::Multi> 0.10

=head3 L<POE::Component::Curses> 0.211

=head3 L<POE::Component::DBIAgent> 0.26

=head3 L<POE::Component::DHCP::Monitor> 1.04

=head3 L<POE::Component::Daemon> 0.1400

=head3 L<POE::Component::Daemon::Win32> 0.01

=head3 L<POE::Component::DebugShell> 1.412

=head3 L<POE::Component::DebugShell::Jabber> 0.04

=head3 L<POE::Component::DirWatch> 0.300001

=head3 L<POE::Component::DirWatch::Object> 0.10

=head3 L<POE::Component::EasyDBI> 1.24

=head3 L<POE::Component::Enc::Flac> 1.01

=head3 L<POE::Component::Enc::Mp3> 1.2

=head3 L<POE::Component::Enc::Ogg> 1.05

=head3 L<POE::Component::FastCGI> 0.19

=head3 L<POE::Component::FeedAggregator> 0.902

=head3 L<POE::Component::Fuse> 0.05

=head3 L<POE::Component::Gearman::Client> 0.03

=head3 L<POE::Component::Generic> 0.1403

=head3 L<POE::Component::Github> 0.08

=head3 L<POE::Component::Growl> 1.00

=head3 L<POE::Component::Hailo> 0.10

=head3 L<POE::Component::ICal> 0.130020

=head3 L<POE::Component::IKC> 0.2402

=head3 L<POE::Component::IRC> 6.88

=head3 L<POE::Component::IRC::Object> 0.02

=head3 L<POE::Component::IRC::Plugin::BaseWrap> 1.001001

=head3 L<POE::Component::IRC::Plugin::Blowfish> 0.01

=head3 L<POE::Component::IRC::Plugin::Bollocks> 1.00

=head3 L<POE::Component::IRC::Plugin::CPAN::Info> 1.001002

=head3 L<POE::Component::IRC::Plugin::CoreList> 1.02

=head3 L<POE::Component::IRC::Plugin::Donuts> 0.07

=head3 L<POE::Component::IRC::Plugin::Eval> 0.07

=head3 L<POE::Component::IRC::Plugin::FTP::EasyUpload> 0.002

=head3 L<POE::Component::IRC::Plugin::Google::Calculator> 0.04

=head3 L<POE::Component::IRC::Plugin::Hailo> 0.18

=head3 L<POE::Component::IRC::Plugin::Hello> 0.001002

=head3 L<POE::Component::IRC::Plugin::IRCDHelp> 0.01

=head3 L<POE::Component::IRC::Plugin::ImageMirror> 0.15

=head3 L<POE::Component::IRC::Plugin::Infobot> 0.001002

=head3 L<POE::Component::IRC::Plugin::Karma> 0.003

=head3 L<POE::Component::IRC::Plugin::Logger::Irssi> 0.001002

=head3 L<POE::Component::IRC::Plugin::MegaHAL> 0.46

=head3 L<POE::Component::IRC::Plugin::MultiProxy> 0.01

=head3 L<POE::Component::IRC::Plugin::OutputToPastebin> 0.002

=head3 L<POE::Component::IRC::Plugin::POE::Knee> 1.08

=head3 L<POE::Component::IRC::Plugin::QueryDNS> 1.04

=head3 L<POE::Component::IRC::Plugin::QueryDNSBL> 1.04

=head3 L<POE::Component::IRC::Plugin::RSS::Headlines> 1.08

=head3 L<POE::Component::IRC::Plugin::RTorrentStatus> 0.17

=head3 L<POE::Component::IRC::Plugin::Role> 0.06

=head3 L<POE::Component::IRC::Plugin::Seen> 0.001001

=head3 L<POE::Component::IRC::Plugin::Trac::RSS> 0.11

=head3 L<POE::Component::IRC::Plugin::URI::Find> 1.10

=head3 L<POE::Component::IRC::Plugin::Unicode::UCD> 0.004

=head3 L<POE::Component::IRC::Plugin::WWW::CPANRatings::RSS> 0.0106

=head3 L<POE::Component::IRC::Plugin::WWW::Google::Time> 0.0102

=head3 L<POE::Component::IRC::Plugin::WWW::KrispyKreme::HotLight> 0.06

=head3 L<POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search> 0.002

=head3 L<POE::Component::IRC::Plugin::WWW::Reddit::TIL> 0.07

=head3 L<POE::Component::IRC::Plugin::WWW::Vim::Tips> 0.14

=head3 L<POE::Component::IRC::Plugin::WWW::Weather::US> 0.04

=head3 L<POE::Component::IRC::Plugin::WWW::XKCD::AsText> 0.003

=head3 L<POE::Component::IRC::Plugin::WubWubWub> 0.1

=head3 L<POE::Component::IRC::PluginBundle::Toys> 1.001001

=head3 L<POE::Component::IRC::PluginBundle::WebDevelopment> 2.001003

=head3 L<POE::Component::IRC::Service> 0.996

=head3 L<POE::Component::Jabber> 3.00

=head3 L<POE::Component::JobQueue> 0.571

=head3 L<POE::Component::LaDBI> 1.002001

=head3 L<POE::Component::Lightspeed> 0.05

=head3 L<POE::Component::Lingua::Translate> 0.06

=head3 L<POE::Component::Log4perl> 0.03

=head3 L<POE::Component::Logger> 1.10

=head3 L<POE::Component::MXML> 0.03

=head3 L<POE::Component::MessageQueue> 0.3001

=head3 L<POE::Component::Metabase::Client::Submit> 0.12

=head3 L<POE::Component::Metabase::Relay::Server> 0.34

=head3 L<POE::Component::Net::FTP> 0.001

=head3 L<POE::Component::Net::LastFM::Submission> 0.24

=head3 L<POE::Component::NetSNMP::agent> 0.500

=head3 L<POE::Component::NomadJukebox> 0.02

=head3 L<POE::Component::NonBlockingWrapper::Base> 0.002

=head3 L<POE::Component::OSCAR> 0.05

=head3 L<POE::Component::Omegle> 0.02

=head3 L<POE::Component::OpenSSH> 0.10

=head3 L<POE::Component::Pastebin::Create> 0.0

=head3 L<POE::Component::Pcap> 0.04

=head3 L<POE::Component::Player::Mpg123> 1.2

=head3 L<POE::Component::Player::Musicus> 1.32

=head3 L<POE::Component::Player::Slideshow> 1.4

=head3 L<POE::Component::Player::Xmms> 0.04

=head3 L<POE::Component::Pluggable> 1.26

=head3 L<POE::Component::PluginManager> 0.67

=head3 L<POE::Component::Pool::DBI> 0.014

=head3 L<POE::Component::Pool::Thread> 0.015

=head3 L<POE::Component::PreforkDispatch> 0.101

=head3 L<POE::Component::ProcTerminator> 0.03

=head3 L<POE::Component::Proxy::MySQL> 0.04

=head3 L<POE::Component::Proxy::SOCKS> 1.02

=head3 L<POE::Component::Proxy::TCP> 1.2

=head3 L<POE::Component::RSS> 3.01

=head3 L<POE::Component::RSSAggregator> 1.11

=head3 L<POE::Component::RemoteTail> 0.01011

=head3 L<POE::Component::Rendezvous::Publish> 0.01

=head3 L<POE::Component::Resolver> 0.921

=head3 L<POE::Component::ResourcePool> 0.04

=head3 L<POE::Component::ResourcePool::Resource::TokenBucket> 0.01

=head3 L<POE::Component::SASLAuthd> 0.03

=head3 L<POE::Component::SNMP> 1.1006

=head3 L<POE::Component::SNMP::Session> 0.1202

=head3 L<POE::Component::SSLify> 1.008

=head3 L<POE::Component::SSLify::NonBlock> 0.41

=head3 L<POE::Component::Schedule> 0.95

=head3 L<POE::Component::Sequence> 0.02

=head3 L<POE::Component::SimpleDBI> 1.30

=head3 L<POE::Component::SimpleLog> 1.05

=head3 L<POE::Component::SmokeBox> 0.48

=head3 L<POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini> 0.58

=head3 L<POE::Component::SmokeBox::Dists> 1.08

=head3 L<POE::Component::SmokeBox::Recent> 1.46

=head3 L<POE::Component::SmokeBox::Uploads::CPAN::Mini> 1.00

=head3 L<POE::Component::SmokeBox::Uploads::NNTP> 1.00

=head3 L<POE::Component::SmokeBox::Uploads::RSS> 1.00

=head3 L<POE::Component::SmokeBox::Uploads::Rsync> 1.000

=head3 L<POE::Component::Spread> 0.02

=head3 L<POE::Component::SpreadClient> 1.002

=head3 L<POE::Component::SubWrapper> 2.01

=head3 L<POE::Component::Supervisor> 0.08

=head3 L<POE::Component::Syndicator> 0.06

=head3 L<POE::Component::TFTPd> 0.0302

=head3 L<POE::Component::TSTP> 0.02

=head3 L<POE::Component::Telephony::CTPort> 0.03

=head3 L<POE::Component::UserBase> 0.09

=head3 L<POE::Component::WWW::CPANRatings::RSS> 0.0101

=head3 L<POE::Component::WWW::DoingItWrongCom::RandImage> 0.03

=head3 L<POE::Component::WWW::Google::Calculator> 0.03

=head3 L<POE::Component::WWW::Google::Time> 0.0102

=head3 L<POE::Component::WWW::OhNoRobotCom::Search> 0.002

=head3 L<POE::Component::WWW::Pastebin::Bot::Pastebot::Create> 0.003

=head3 L<POE::Component::WWW::Pastebin::Many::Retrieve> 0.001

=head3 L<POE::Component::WWW::Shorten> 1.20

=head3 L<POE::Component::WWW::XKCD::AsText> 0.002

=head3 L<POE::Component::WakeOnLAN> 1.04

=head3 L<POE::Component::Win32::ChangeNotify> 1.22

=head3 L<POE::Component::Win32::EventLog> 1.24

=head3 L<POE::Component::Win32::Service> 1.24

=head3 L<POE::Component::XUL> 0.02

=head3 L<POE::Component::YahooMessenger> 0.05

=head3 L<POE::Component::YubiAuth> 0.07

=head2 Data Parsers and Wheels

=head3 L<POE::Filter::BigBrother> 0.13

=head3 L<POE::Filter::Bzip2> 1.58

=head3 L<POE::Filter::CSV> 1.16

=head3 L<POE::Filter::CSV_XS> 1.16

=head3 L<POE::Filter::DHCPd::Lease> 0.0703

=head3 L<POE::Filter::DNS::TCP> 0.06

=head3 L<POE::Filter::ErrorProof> 0.01

=head3 L<POE::Filter::FSSocket> 0.07

=head3 L<POE::Filter::Finger> 0.08

=head3 L<POE::Filter::HTTP::Parser> 1.06

=head3 L<POE::Filter::HTTPD::Chunked> 0.9

=head3 L<POE::Filter::Hessian> 1.00

=head3 L<POE::Filter::IASLog> 1.08

=head3 L<POE::Filter::IRCD> 2.44

=head3 L<POE::Filter::IRCv3> 1.001001

=head3 L<POE::Filter::JSON> 0.04

=head3 L<POE::Filter::JSON::Incr> 0.03

=head3 L<POE::Filter::KennySpeak> 1.02

=head3 L<POE::Filter::LOLCAT> 1.10

=head3 L<POE::Filter::LZF> 1.70

=head3 L<POE::Filter::LZO> 1.70

=head3 L<POE::Filter::LZW> 1.72

=head3 L<POE::Filter::LZW::Progressive> 0.1

=head3 L<POE::Filter::Log::IPTables> 0.02

=head3 L<POE::Filter::Log::Procmail> 0.03

=head3 L<POE::Filter::Ls> 0.01

=head3 L<POE::Filter::PPPHDLC> 0.01

=head3 L<POE::Filter::ParseWords> 1.06

=head3 L<POE::Filter::Postfix> 0.003

=head3 L<POE::Filter::RecDescent> 0.02

=head3 L<POE::Filter::Redis> 0.02

=head3 L<POE::Filter::Regexp> 1.0

=head3 L<POE::Filter::SSL> 0.28

=head3 L<POE::Filter::SimpleHTTP> 0.091710

=head3 L<POE::Filter::Slim::CLI> 0.02

=head3 L<POE::Filter::Snort> 0.031

=head3 L<POE::Filter::Stomp> 0.04

=head3 L<POE::Filter::Transparent::SMTP> 0.2

=head3 L<POE::Filter::XML> 1.140700

=head3 L<POE::Filter::XML::RPC> 0.04

=head3 L<POE::Filter::Zlib> 2.02

=head3 L<POE::Wheel::Audio::Mad> 0.3

=head3 L<POE::Wheel::GnuPG> 0.01

=head3 L<POE::Wheel::MyCurses> 1.2102

=head3 L<POE::Wheel::Null> 0.01

=head3 L<POE::Wheel::Run::Win32> 0.18

=head3 L<POE::Wheel::Sendfile> 0.0200

=head3 L<POE::Wheel::TermKey> 0.02

=head3 L<POE::Wheel::UDP> 0.02

=head3 L<POE::Wheel::VimColor> 0.0

=head2 Event Loops

=head3 L<POE::Loop::AnyEvent> 0.004

=head3 L<POE::Loop::EV> 0.06

=head3 L<POE::Loop::Event> 1.305

=head3 L<POE::Loop::Glib> 0.038

=head3 L<POE::Loop::Gtk> 1.306

=head3 L<POE::Loop::IO_Async> 0.004

=head3 L<POE::Loop::Kqueue> 0.02

=head3 L<POE::Loop::Prima> 1.02

=head3 L<POE::Loop::Tk> 1.305

=head3 L<POE::Loop::Wx> 0.04

=head2 Session Types

=head3 L<POE::Session::Attribute> 0.80

=head3 L<POE::Session::AttributeBased> 0.10

=head3 L<POE::Session::GladeXML2> 0.40

=head3 L<POE::Session::Irssi> 0.50

=head3 L<POE::Session::MessageBased> 0.111

=head3 L<POE::Session::MultiDispatch> 1.3

=head3 L<POE::Session::Multiplex> 0.0600

=head3 L<POE::Session::PlainCall> 0.0301

=head3 L<POE::Session::YieldCC> 0.202

=head2 Debugging and Developing POE

=head3 L<POE::API::Hooks> 2.03

=head3 L<POE::API::Peek> 2.20

=head3 L<POE::Devel::Benchmarker> 0.05

=head3 L<POE::Devel::ProcAlike> 0.02

=head3 L<POE::Devel::Profiler> 0.02

=head3 L<POE::Devel::Top> 0.100

=head3 L<POE::Test::Helpers> 1.11

=head3 L<POE::Test::Loops> 1.359

=head3 L<POE::XS::Loop::EPoll> 1.003

=head3 L<POE::XS::Loop::Poll> 1.000

=head3 L<POE::XS::Queue::Array> 0.006

=head2 POE Extensions

=head3 L<POEx::HTTP::Server> 0.0902

=head3 L<POEx::IRC::Backend> 0.024006

=head3 L<POEx::IRC::Client::Lite> 0.002002

=head3 L<POEx::Inotify> 0.0201

=head3 L<POEx::Role::PSGIServer> 1.110670

=head3 L<POEx::Tickit> 0.02

=head3 L<POEx::URI> 0.0301

=head3 L<POEx::Weather::OpenWeatherMap> 0.002001

=head3 L<POEx::ZMQ> 0.005002

=head2 Uncategorized

=head3 L<POE::Declarative> 0.09

=head3 L<POE::Declare> 0.59

=head3 L<POE::Declare::HTTP::Client> 0.05

=head3 L<POE::Declare::HTTP::Online> 0.02

=head3 L<POE::Declare::HTTP::Server> 0.05

=head3 L<POE::Declare::Log::File> 0.01

=head3 L<POE::Event::Message> 0.11

=head3 L<POE::Framework::MIDI> 0.09

=head3 L<POE::Future> 0.03

=head3 L<POE::Quickie> 0.18

=head3 L<POE::Stage> 0.060

=head3 L<POE::Sugar::Args> 1.3

=head3 L<POE::Sugar::Attributes> 0.02

=head3 L<POE::TIKC> 0.02

=head3 L<POE::XUL::Javascript> 0.0

=head3 L<POE::strict> 3.01

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Task::POE::All

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Task-POE-All>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Task-POE-All>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-POE-All>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Task-POE-All>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Task-POE-All>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Task-POE-All>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Task-POE-All>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-POE-All>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-POE-All>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::POE::All>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-poe-all at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-POE-All>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-poe-taskall>

  git clone https://github.com/apocalypse/perl-poe-taskall.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
