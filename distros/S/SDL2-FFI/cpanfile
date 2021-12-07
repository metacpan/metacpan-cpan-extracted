requires 'perl' => '5.030000';
requires 'FFI::Platypus', '1.55';
requires 'FFI::C';

#requires 'File::Spec::Functions';
requires 'Exporter::Tiny';

#requires 'Path::Tiny';
requires 'File::Share';
requires 'Try::Tiny';
recommends 'B::Deparse';
requires 'Path::Tiny';
requires 'FFI::ExtractSymbols', '0.06';
#
requires 'Data::Dump';
on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::V0';
    requires 'Test::NeedsDisplay', '1.07';
};
on configure => sub {
    requires 'IO::Socket::SSL';
    requires 'Capture::Tiny';
    requires 'Devel::CheckBin';
    requires 'Module::Build::Tiny', '0.039';
    requires 'HTTP::Tiny';
    requires 'Path::Tiny';
    requires 'Archive::Extract';
    requires 'FFI::ExtractSymbols', '0.06';
    requires 'FFI::Build';
    requires 'ExtUtils::CBuilder';
    requires 'HTTP::Tiny';

    # Thanks, Windows!
    #requires 'Alien::MSYS';
    requires 'Alien::gmake';

    #requires 'Alien::autoconf';
    #requires 'Alien::automake';
    requires 'Archive::Zip' if $^O eq 'MSWin32';
    #
    requires 'Data::Dump';
    requires 'Carp::Always';
};
on development => sub {
    requires 'Software::License::Artistic_2_0';
    requires 'Minilla';
    requires 'Code::TidyAll';
    requires 'Code::TidyAll::Plugin::PodTidy';
    requires 'Perl::Tidy';
    requires 'Pod::Tidy';
    requires 'Code::TidyAll::Plugin::ClangFormat';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod' => 1.41;
    requires 'Test::Spellunker';
};
