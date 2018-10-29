requires 'perl',           v5.28.0;
requires 'common::header', v0.1.2;

feature windows => sub {
    requires 'Win32::Console';
    requires 'Win32::Console::ANSI';
};

requires 'Variable::Magic';
requires 'B::Hooks::AtRuntime';
requires 'B::Hooks::EndOfScope::XS';
requires 'Const::Fast';
requires 'Clone';
requires 'Package::Stash::XS';

# Pcore::Core::Dump
requires 'PerlIO::Layers';
requires 'Sort::Naturally';

# OOP
requires 'Class::XSAccessor';
requires 'Type::Tiny';
requires 'Type::Tiny::XS';

# AnyEvent
requires 'EV',              v4.22.0;
requires 'AnyEvent',        v7.14.0;
requires 'Coro',            v6.52.0;
requires 'Guard',           v1.23.0;
requires 'IO::FDPass',      v1.2.0;
requires 'IO::AIO',         v4.6.0;
requires 'AnyEvent::AIO',   v1.1.0;
requires 'IO::Socket::SSL', v2.60.0;
requires 'Net::DNS::Resolver';

# Inline
requires 'Inline',      v0.80.0;
requires 'Inline::C',   v0.78.0;
requires 'Inline::CPP', v0.75.0;

# Pcore::App
requires 'Crypt::Argon2', v0.5.0;

# Pcore::Dist
requires 'Pod::Markdown';
requires 'Software::License';
requires 'Module::CPANfile';

# commond devel modules
on develop => sub {
    requires 'Module::Build::Tiny';
    requires 'CPAN::Changes';

    # debugging and profiling
    requires 'Devel::NYTProf';
    requires 'Devel::Cover';

    # suggests 'Devel::hdb';

    # PAR
    requires 'PAR::Packer';
    requires 'Filter::Crypto';
};

# Pcore::Handle::sqlite
requires 'DBI',         v1.641.0;
requires 'DBD::SQLite', v1.58.0;

# Pcore::HTTP
requires 'HTML::TreeBuilder::LibXML', v0.26.0;
requires 'HTTP::Parser::XS',          v0.17.0;
requires 'Protocol::HTTP2',           v1.9.0;
requires 'HTTP::Message',             v6.13.0;
feature linux => sub {    #
    requires 'IO::Uncompress::Brotli';
};

# Pcore::Src
requires 'Perl::Tidy';
on develop => sub {
    requires 'BerkeleyDB';
    requires 'Perl::Stripper';
    requires 'Perl::Strip';
    requires 'Perl::Critic';
    requires 'PPI::XS';
    requires 'JavaScript::Packer';
    requires 'CSS::Packer';
    requires 'HTML::Packer';

    # suggests 'Perl::Lint';    # Perl::Critic replacement
};

# Pcore::Util::Class
requires 'Sub::Util';

# Pcore::Util::Data
requires 'YAML::XS';
requires 'Cpanel::JSON::XS';
requires 'CBOR::XS';
requires 'XML::Hash::XS';
requires 'Crypt::CBC';
requires 'Crypt::DES';
requires 'Compress::Zlib';
requires 'MIME::Base64';

# Pcore::Util::Date
requires 'Time::Moment';
requires 'HTTP::Date';
requires 'Time::Zone';

# requires 'DateTime::TimeZone';

# Pcore::Util::Digest
requires 'Digest';
requires 'String::CRC32';
requires 'Digest::MD5';
requires 'Digest::SHA1';
requires 'Digest::SHA';
requires 'Digest::SHA3';

# Pcore::Util::File
requires 'File::Copy::Recursive';

# Pcore::Util::List
requires 'List::Util::XS';
requires 'List::AllUtils';

# Pcore::Util::Random
requires 'Net::SSLeay';

# Pcore::Util::Regexp
requires 'Regexp::Util';

# Pcore::Util::Scalar
requires 'Devel::Refcount';
requires 'Ref::Util';
requires 'Ref::Util::XS';

# Pcore::Util::Sys
requires 'Sys::CpuAffinity';
feature windows => sub {
    requires 'Win32::RunAsAdmin';
    requires 'Win32::Process';
};

# Pcore::Util::Term
requires 'Term::ReadKey';
requires 'Term::Size::Any';
feature windows => sub {
    requires 'Term::Size::Win32';
};

# Pcore::Util::Text
requires 'HTML::Entities';

# Pcore::Util::Tmpl
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';

# Pcore::Util::UUID
requires 'Data::UUID',     v1.221.0;
requires 'Data::UUID::MT', v1.1.0;

on test => sub {
    requires 'Test::More', '0.88';
};
