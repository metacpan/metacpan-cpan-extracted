use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Task::BeLike::DCANTRELL',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Task-BeLike-DCANTRELL',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Task-BeLike-DCANTRELL/issues'
        },
    },
    VERSION_FROM => 'lib/Task/BeLike/DCANTRELL.pm',
    PREREQ_PM => {
        map { ($_ =~ s/^\s+|\s+$//gr) => 0 } <DATA>
    },
);

__DATA__
Color::ANSI::Util
CPAN::DistnameInfo
Data::Dumper::Concise
Date::Roman
Email::Valid
File::cd
File::Slurp
File::Slurper
Graphics::ColorNames
HTTP::Date
HTTP::Tiny
JSON
JSON::Parse
LWP::Protocol::https
LWP::UserAgent
MIME::Lite
MIME::Types
Net::DNS
Parse::CPAN::Packages::Fast
Path::Tiny
Sort::Naturally
Template
WWW::Mechanize
YAML::XS
Algorithm::Diff::JSON
App::ptimeout
Class::CanBeA
Class::Mockable
CPAN::FindDependencies
CPAN::ParseDistribution
CPU::Emulator::Memory
CPU::Emulator::Z80
Data::CompactReadonly
Data::Compare
Data::Hexdumper
Data::Transactional
DBIx::Class::QueryLog::WithStackTrace
DBIx::Class::SingletonRows
DBM::Deep
Devel::Caller::IgnoreNamespaces
Devel::CheckOS
Devel::Deprecations::Environmental
Devel::Hide
File::Find::Rule::Permissions
MooseX::Types::StrictScalarTypes
Number::Phone
Number::Phone::UK::DetailedLocations
Params::Validate::Dependencies
Params::Validate::Dependencies::all_or_none_of
Scalar::Type
Sort::MultipleFields
Statistics::ChiSquare
Statistics::SerialCorrelation
String::Binary::Interpolation
Sub::Attribute
Sub::WrapPackages
Test::Differences
Test::Mojo::Role::HTTPstatus
Test::Most
Tie::Hash::Vivify
Tie::STDOUT
XML::DoubleEncodedEntities
Devel::NYTProf
Devel::Cover
