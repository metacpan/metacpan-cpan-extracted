Name:           perl-PHP-Decode
Version:        0.303
Release:        1%{?dist}
Summary:        Parse and transform obfuscated php code
License:        GPL-1.0-or-later OR Artistic-1.0-Perl
URL:            https://metacpan.org/dist/PHP-Decode
Source0:        https://cpan.metacpan.org/authors/id/B/BD/BDZ/PHP-Decode-%{version}.tar.gz
BuildArch:      noarch
BuildRequires:  make
BuildRequires:  perl-generators
BuildRequires:  perl-interpreter
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Tie::IxHash)
BuildRequires:  perl(Digest::SHA)
BuildRequires:  perl(Compress::Zlib)
BuildRequires:  perl(HTML::Entities)
BuildRequires:  perl(URI::Escape)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(bignum)

%description
PHP::Decode parses php code files and tries to apply all possible static
transformations for php variables and values defined in the script.
The php_decode tool prints the decoded file to stdout.

%prep
%setup -q -n PHP-Decode-%{version}

%build
perl Makefile.PL INSTALLDIRS=vendor NO_PACKLIST=1 NO_PERLLOCAL=1
%make_build

%install
make pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -delete

%check
make test

%files
%doc Changes README
%{_bindir}/php_decode
%{perl_vendorlib}/PHP/
%{_mandir}/man1/php_decode.1*
%{_mandir}/man3/PHP::Decode*.3*

%changelog
* Thu Sep 04 2025 Barnim Dzwillo <dzwillo@strato.de> - 0.303-1
- initial package
