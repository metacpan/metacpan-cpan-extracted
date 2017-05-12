requires 'perl', v5.24.1;

# Pcore::Core
requires 'multidimensional';

feature windows => sub {
    requires 'Win32::Console';
    requires 'Win32::Console::ANSI';
};

requires 'Import::Into';
requires 'Variable::Magic';
requires 'B::Hooks::AtRuntime';
requires 'B::Hooks::EndOfScope::XS';
requires 'Const::Fast';
requires 'Clone';
requires 'Package::Stash';
requires 'Package::Stash::XS';

# Pcore::Core::Dump
requires 'PerlIO::Layers';
requires 'Sort::Naturally';

# OOP
requires 'Moo';
requires 'MooX::TypeTiny';
requires 'Class::XSAccessor';    # optional
requires 'Type::Tiny';
requires 'Type::Tiny::XS';

# AnyEvent
requires 'EV';
requires 'AnyEvent';
requires 'Net::DNS::Resolver';
requires 'Guard';
feature linux => sub {
    requires 'AnyEvent::AIO';
    requires 'IO::AIO';
};

# Inline
requires 'Inline';
requires 'Inline::C';

# Handle
requires 'BerkeleyDB';

# Pcore::App
requires 'Crypt::Argon2';

# Pcore::Dist
requires 'Pod::Markdown';
requires 'Software::License';
requires 'Module::CPANfile';
requires 'Filter::Crypto';

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
};

# Pcore::HTTP
requires 'HTTP::Parser::XS';
requires 'HTTP::Message';

# Pcore::Src
requires 'Perl::Tidy';
on develop => sub {
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
requires 'JSON::XS';
requires 'CBOR::XS';
requires 'XML::Hash::XS';
requires 'Crypt::CBC';
requires 'Crypt::DES';
requires 'Compress::Zlib';
requires 'URI::Escape::XS';
requires 'MIME::Base64';
requires 'Convert::Ascii85';

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

# Pcore::Util::IDN
requires 'Net::LibIDN';

# Pcore::Util::List
requires 'List::Util::XS';
requires 'List::AllUtils';

# Pcore::Util::Mail
requires 'Mail::IMAPClient';

# Pcore::Util::PM
feature windows => sub {
    requires 'Win32::Process';
};

# Pcore::Util::Random
requires 'Net::SSLeay';

# Pcore::Util::Scalar
requires 'Devel::Refcount';

# Pcore::Util::Sys
requires 'Sys::CpuAffinity';
feature windows => sub {
    requires 'Win32::RunAsAdmin';
};

# Pcore::Util::Term
requires 'Term::ReadKey';
requires 'Term::Size::Any';
feature windows => sub {
    requires 'Term::Size::Win32';
};

# Pcore::Util::Text
requires 'HTML::Entities';

# Pcore::Util::Template
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';

# Pcore::Util::UUID
requires 'Data::UUID';

on test => sub {
    requires 'Test::More', '0.88';
};
