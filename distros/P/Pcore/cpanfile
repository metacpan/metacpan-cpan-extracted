requires 'perl',           v5.30.0;
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

# AnyEvent
requires 'EV',                 v4.22.0;
requires 'AnyEvent',           v7.14.0;
requires 'Coro',               v6.52.0;
requires 'Guard',              v1.23.0;
requires 'IO::FDPass',         v1.2.0;
requires 'IO::AIO',            v4.6.0;
requires 'AnyEvent::AIO',      v1.1.0;
requires 'IO::Socket::SSL',    v2.60.0;
requires 'Net::DNS::Resolver', v1.18.0;

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
    requires 'Filter::Crypto';
    requires 'PAR::Packer';

    # debugging and profiling
    requires 'Devel::NYTProf';

    # requires 'Devel::Cover';
    # suggests 'Devel::hdb';
};

# Pcore::Handle::sqlite
requires 'DBI',         v1.641.0;
requires 'DBD::SQLite', v1.58.0;

# Pcore::HTTP
# requires 'HTML::TreeBuilder::LibXML', v0.26.0;
requires 'HTML5::DOM',       v1.80.0;
requires 'HTTP::Parser::XS', v0.17.0;
requires 'Protocol::HTTP2',  v1.9.0;
requires 'HTTP::Message',    v6.13.0;
feature linux => sub {
    requires 'IO::Uncompress::Brotli';
};

# Pcore::API::Google::OAuth
requires 'Crypt::OpenSSL::RSA', v0.310.0;

# Pcore::API::SMTP
requires 'Authen::SASL', v2.16.0;

# TODO https://github.com/gbarr/perl-authen-sasl-xs/issues/1
feature linux => sub {
    requires 'Devel::CheckLib',  v1.13.0;
    suggests 'Authen::SASL::XS', v1.0.0;
};

# Pcore::Util::Class
requires 'Sub::Util', v1.50.0;

# Pcore::Util::Data
requires 'YAML::XS',              v0.76.0;
requires 'Cpanel::JSON::XS',      v4.7.0;
requires 'CBOR::XS',              v1.7.0;
requires 'XML::Hash::XS',         v0.53.0;
requires 'Crypt::CBC',            v2.33.0;
requires 'Crypt::DES',            v2.7.0;
requires 'Compress::Zlib',        v2.81.0;
requires 'MIME::Base64',          v3.15.0;
requires 'MIME::Base64::URLSafe', v0.1.0;
requires 'Text::CSV_XS',          v1.37.0;

# Pcore::Util::Date
requires 'Time::Moment', v0.44.0;
requires 'HTTP::Date',   v6.2.0;
requires 'Time::Zone',   v2.30.0;

# requires 'DateTime::TimeZone';

# Pcore::Util::Digest
requires 'Digest',        v1.17.0;
requires 'String::CRC32', v1.7.0;
requires 'Digest::MD5',   v2.55.0;
requires 'Digest::SHA1',  v2.13.0;
requires 'Digest::SHA',   v6.2.0;
requires 'Digest::SHA3',  v1.4.0;

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

# Pcore::Util::Src
requires 'Perl::Tidy';
on develop => sub {
    requires 'Perl::Stripper';
    requires 'Perl::Strip';
    requires 'Perl::Critic';
    requires 'PPI::XS';
    requires 'JavaScript::Beautifier', v0.25.0;
    requires 'JavaScript::Packer';
    requires 'CSS::Packer';
    requires 'HTML::Packer';

    # suggests 'Perl::Lint';    # Perl::Critic replacement
};

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
