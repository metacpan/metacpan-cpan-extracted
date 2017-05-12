use 5.008;
use strict;
use warnings;

package Task::BeLike::RJRAY;

our $VERSION = '0.009';

1;

__END__

=pod

=head1 NAME

Task::BeLike::RJRAY - RJRAY's frequently-used and favorite modules

=head1 TASK CONTENTS

=head2 Apps

=head3 L<App::Ack>

=head3 L<App::Changelog2x>

=head3 L<App::cpanminus>

=head3 L<App::gh>

=head3 L<App::Uni>

#=head3 L<Bundle::CPAN>

=head3 L<CPAN::Uploader>

=head3 L<Code::TidyAll>

=head3 L<Module::CPANTS::Analyse>

=head2 CLI Tools

=head3 L<Daemon::Control>

=head3 L<Daemon::Daemonize>

=head3 L<Getopt::Lucid>

=head3 L<Pod::Usage>

=head2 Filesystem Tools

=head3 L<File::Find::Rule>

=head3 L<File::Find::Rule::Perl>

=head3 L<File::Slurp>

=head3 L<File::pushd>

=head3 L<Path::Class>

=head3 L<Path::Class::Rule>

=head3 L<Path::Iterator::Rule>

=head3 L<Path::Tiny>

=head3 L<Unicode::UTF8>

=head2 Database Modules

=head3 L<CPAN::SQLite>

=head3 L<DBI>

=head3 L<DBD::SQLite>

=head2 Data Manipulation

=head3 L<Const::Fast>

=head3 L<JSON>

=head3 L<JSON::XS>

=head3 L<List::MoreUtils>

=head3 L<Regexp::Common>

=head3 L<XML::LibXML>

=head3 L<XML::LibXSLT>

=head3 L<XML::Parser>

=head3 L<XML::RSS>

=head3 L<XML::Simple>

=head3 L<YAML>

=head3 L<YAML::Any>

=head3 L<YAML::XS>

=head2 Development Tools

=head3 L<Archive::Tar>

=head3 L<Archive::Tar::Wrapper>

=head3 L<Archive::Zip>

=head3 L<Data::Dump>

=head3 L<Data::Dump::Streamer>

=head3 L<Data::Dump::XML>

=head3 L<Devel::Cover>

=head3 L<Devel::Leak>

=head3 L<Devel::Modlist>

=head3 L<Devel::NYTProf>

=head3 L<Devel::Cycle>

=head3 L<Devel::StackTrace>

=head3 L<Devel::StackTrace::AsHTML>

=head3 L<Devel::Symdump>

=head3 L<Git::PurePerl>

=head3 L<PPI>

=head3 L<PPI::HTML>

=head3 L<PPI::Prettify>

=head3 L<PPI::XS>

=head3 L<PPIx::Regexp>

=head3 L<PadWalker>

=head3 L<Perl::Critic>

=head3 L<Perl::Critic::Bangs>

=head3 L<Perl::Tidy>

=head3 L<Perl::Version>

=head3 L<Pod::Coverage>

=head3 L<Pod::Checker>

=head3 L<XXX>

=head3 L<namespace::autoclean>

=head3 L<superclass>

=head3 L<version>

=head2 Moose

=head3 L<Moo>

=head3 L<Moose>

=head3 L<MooseX::Aliases>

=head3 L<MooseX::Types>

=head3 L<MooseX::Types::Common>

=head3 L<MooseX::Types::Perl>

=head3 L<Throwable>

=head2 Email Tools

=head3 L<Email::MIME>

=head3 L<Email::Sender>

=head3 L<Email::Sender::Simple>

=head3 L<Email::Simple>

=head2 Net Stuff

=head3 L<Net::Daemon>

=head3 L<Net::HTTP>

=head3 L<Net::OAuth>

=head3 L<Net::Server>

=head2 Web Stuff

=head3 L<Bundle::LWP>

=head3 L<LWP::Protocol::https>

=head3 L<HTTP::Tiny>

=head3 L<HTTP::CookieJar>

=head3 L<Mojolicious>

=head3 L<Mozilla::CA>

=head3 L<Net::SSLeay>

=head3 L<Net::Twitter>

=head3 L<Net::Twitter::Lite>

=head3 L<IO::Socket::SSL>

=head3 L<RPC::XML>

=head3 L<URI>

=head3 L<WWW::Mechanize>

=head2 System Interaction

=head3 L<autodie>

=head3 L<Capture::Tiny>

=head3 L<IPC::Run3>

=head3 L<IPC::System::Simple>

=head3 L<Time::HiRes>

=head2 Templating

=head3 L<Template>

=head3 L<Template::Mustache>

=head3 L<Text::Template>

=head2 Testing Modules

=head3 L<Test::AgainstSchema>

=head3 L<Test::CPAN::Meta>

=head3 L<Test::Deep>

=head3 L<Test::Differences>

=head3 L<Test::Fatal>

=head3 L<Test::More>

=head3 L<Test::MinimumVersion>

=head3 L<Test::Output>

=head3 L<Test::Perl::Critic>

=head3 L<Test::Pod>

=head3 L<Test::Pod::Coverage>

=head2 Tools

=head3 L<Git::Wrapper>

=head3 L<Net::GitHub>

=head3 L<Vi::QuickFix>

=head2 Work-Related

=head3 L<EV>

=head3 L<Params::Validate>

=head2 Miscellaneous

=head3 L<Config::Any>

=head3 L<Config::General>

=head3 L<Config::GitLike>

=head3 L<Config::Tiny>

=head3 L<Crypt::OpenPGP>

=head3 L<DateTime::Format::ISO8601>

=head3 L<DateTime::Format::Strptime>

=head3 L<Image::Size>

=head3 L<MCE>

=head3 L<Math::Random::MT>

=head3 L<Pod::S5>

=head3 L<Readonly>

=head3 L<Readonly::XS>

=head3 L<Task::Weaken>

=head3 L<Text::Textile>

=head3 L<Text::Textile::Plaintext>

=head3 L<Try::Tiny>

=head1 LICENSE AND COPYRIGHT

This file and the code within are copyright (c) 2013-2014 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).

=head1 AUTHOR

Randy J. Ray E<lt>rjray@blackperl.comE<gt>
