use strict;
use warnings;

package Task::BeLike::AMD;
# git description: v0.004-2-g9581580

BEGIN {
  $Task::BeLike::AMD::AUTHORITY = 'cpan:AMD';
}
{
  $Task::BeLike::AMD::VERSION = '4.1.0';
}
# ABSTRACT: Modules AMD uses


1;

__END__
=pod

=head1 NAME

Task::BeLike::AMD - Modules AMD uses

=head1 VERSION

version 4.1.0

=head1 TASK CONTENTS

=head2 Applications

=head3 L<App::Ack>

=head3 L<App::Nopaste>

=head3 L<App::Software::License>

=head3 L<App::cpanminus>

=head3 L<CPAN::Mini>

=head3 L<CPAN::Mini::Devel>

=head3 L<CPAN::Uploader>

=head2 Optional Dependencies Of Other Modules

=head3 L<Task::Moose>

=head3 L<Term::ReadLine::Gnu>

=head2 Development Tools

=head3 L<bareword::filehandles>

=head3 L<Carp::Always>

=head3 L<Carp::Always::Color>

=head3 L<Carp::REPL>

=head3 L<Devel::bt>

=head3 L<Devel::Cover>

=head3 L<Devel::NYTProf>

=head3 L<Dist::Zilla>

=head3 L<Dist::Zilla::PluginBundle::AMD>

=head3 L<indirect>

=head3 L<Module::Install> 0.95

=head3 L<Module::Install::AuthorRequires>

=head3 L<Module::Install::AuthorTests>

=head3 L<Module::Install::CheckConflicts>

=head3 L<Module::Install::ExtraTests>

=head3 L<multidimensional>

=head3 L<Perl::Version> 1.010

=head3 L<Pod::Coverage::TrustPod>

=head3 L<Pod::Weaver::PluginBundle::AMD>

=head3 L<Test::Aggregate>

=head3 L<Test::Pod>

=head3 L<Test::Pod::Coverage>

=head3 L<V>

=head3 L<Task::Pinto>

=head2 Modules I use a lot

=head3 L<App::Cmd>

=head3 L<Bundle::CPAN>

=head3 L<Bundle::libnet>

=head3 L<Bundle::LWP>

=head3 L<CHI>

=head3 L<Cache::Cache>

=head3 L<Cache::FileCache>

=head3 L<Data::DPath>

=head3 L<Data::Visitor>

=head3 L<Data::YAML>

=head3 L<DateTime>

=head3 L<DateTime::Format::Builder>

=head3 L<DateTime::Format::Mail>

=head3 L<DateTime::Format::MySQL>

=head3 L<DateTime::Format::Pg>

=head3 L<DateTime::Format::Natural>

=head3 L<DateTime::Format::Strptime>

=head3 L<DBD::mysql>

=head3 L<DBD::SQLite>

=head3 L<DBD::Pg>

=head3 L<DBI>

=head3 L<DBIx::Class>

=head3 L<DBIx::Class::Schema::Loader>

=head3 L<DBIx::Class::Schema::Versioned>

=head3 L<DBIx::Class::TimeStamp>

=head3 L<Devel::Backtrace>

=head3 L<Digest::SHA1>

=head3 L<Directory::Scratch>

=head3 L<File::ShareDir>

=head3 L<File::Slurp>

=head3 L<File::Type>

=head3 L<Function::Parameters>

=head3 L<Hash::Merge>

=head3 L<Hash::Merge::Simple>

=head3 L<JSON>

=head3 L<JSON::Syck>

=head3 L<JSON::XS>

=head3 L<List::AllUtils>

=head3 L<List::MoreUtils>

=head3 L<Log::Log4perl>

=head3 L<Method::Signatures>

=head3 L<Method::Signatures::Simple>

=head3 L<MIME::Lite>

=head3 L<MIME::Tools>

=head3 L<MIME::Types>

=head3 L<Module::Install>

=head3 L<Module::Starter>

=head3 L<Moose>

=head3 L<Moose::Autobox>

=head3 L<MooseX::Daemonize>

=head3 L<MooseX::Declare>

=head3 L<MooseX::LazyRequire>

=head3 L<MooseX::Log::Log4perl>

=head3 L<MooseX::Method::Signatures>

=head3 L<MooseX::Types::Common>

=head3 L<MooseX::Types::DateTime>

=head3 L<MooseX::Types::Email>

=head3 L<MooseX::Types::LoadableClass>

=head3 L<MooseX::Types::Path::Class>

=head3 L<MooseX::Types::URI>

=head3 L<Net::Daemon>

=head3 L<Net::Server>

=head3 L<Net::Server::PreForkSimple>

=head3 L<Net::SSH>

=head3 L<Net::SSH::Expect>

=head3 L<Net::TFTP>

=head3 L<Parse::RecDescent>

=head3 L<Regexp::Common>

=head3 L<SQL::Translator>

=head3 L<String::Diff>

=head3 L<Sub::Exporter>

=head3 L<TAP::DOM>

=head3 L<TAP::Formatter::HTML>

=head3 L<TAP::Parser::Aggregator>

=head3 L<Task::Catalyst>

=head3 L<Template>

=head3 L<Term::ReadLine::Perl>

=head3 L<Test::Deep>

=head3 L<Test::Fixture::DBIC::Schema>

=head3 L<Test::MockModule>

=head3 L<Test::WWW::Mechanize::Catalyst>

=head3 L<TryCatch>

=head3 L<URI>

=head3 L<URI::Escape>

=head3 L<XML::Generator>

=head3 L<XML::Simple>

=head3 L<YAML>

=head3 L<YAML::Syck>

=head3 L<YAML::XS>

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

