Name:           perl-Term-CLI
Version:        0.055002
Release:        1%{?dist}
Summary:        CLI interpreter based on Term::ReadLine
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Term-CLI/
Source0:        http://www.cpan.org/modules/by-module/Term/Term-CLI-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl >= 0:5.014_001
BuildRequires:  perl-generators
BuildRequires:  perl(Exporter) >= 5.64
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(File::Glob)
BuildRequires:  perl(File::Temp) >= 0.22
BuildRequires:  perl(File::Which) >= 1.09
BuildRequires:  perl(FindBin) >= 1.50
BuildRequires:  perl(Getopt::Long) >= 2.38
BuildRequires:  perl(List::Util) >= 1.23
BuildRequires:  perl(Locale::Maketext) >= 1.19
BuildRequires:  perl(Locale::Maketext::Lexicon::Gettext) >= 1.00
BuildRequires:  perl(Moo) >= 1.000001
BuildRequires:  perl(Moo::Role)
BuildRequires:  perl(namespace::clean) >= 0.25
BuildRequires:  perl(parent) >= 0.225
BuildRequires:  perl(Pod::Coverage::TrustPod)
BuildRequires:  perl(Pod::Text::Termcap) >= 2.06
BuildRequires:  perl(Scalar::Util) >= 1.23
BuildRequires:  perl(strict) >= 1.00
BuildRequires:  perl(subs) >= 1.00
BuildRequires:  perl(Term::ReadKey) >= 2.34
BuildRequires:  perl(Term::ReadLine) >= 1.07
BuildRequires:  perl(Term::ReadLine::Gnu) >= 1.24
BuildRequires:  perl(Test::Class)
BuildRequires:  perl(Test::Compile) >= 1.2.0
BuildRequires:  perl(Test::Exception) >= 0.35
BuildRequires:  perl(Test::MockModule) >= 0.171
BuildRequires:  perl(Test::More) >= 1.001002
BuildRequires:  perl(Test::Output) >= 1.03
BuildRequires:  perl(Test::Pod)
BuildRequires:  perl(Test::Pod::Coverage)
BuildRequires:  perl(Text::ParseWords) >= 3.27
BuildRequires:  perl(Types::Standard) >= 1.000005
BuildRequires:  perl(warnings) >= 1.00
BuildRequires:  make >= 4.0
Requires:       perl(Exporter) >= 5.64
Requires:       perl(File::Glob)
Requires:       perl(File::Which) >= 1.09
Requires:       perl(FindBin) >= 1.50
Requires:       perl(Getopt::Long) >= 2.38
Requires:       perl(List::Util) >= 1.23
Requires:       perl(Locale::Maketext) >= 1.19
Requires:       perl(Locale::Maketext::Lexicon::Gettext) >= 1.00
Requires:       perl(Moo) >= 1.000001
Requires:       perl(Moo::Role)
Requires:       perl(namespace::clean) >= 0.25
Requires:       perl(parent) >= 0.225
Requires:       perl(Pod::Text::Termcap) >= 2.06
Requires:       perl(Scalar::Util) >= 1.23
Requires:       perl(strict) >= 1.00
Requires:       perl(subs) >= 1.00
Requires:       perl(Term::ReadKey) >= 2.34
Requires:       perl(Term::ReadLine) >= 1.07
Requires:       perl(Term::ReadLine::Gnu) >= 1.24
Requires:       perl(Text::ParseWords) >= 3.27
Requires:       perl(Types::Standard) >= 1.000005
Requires:       perl(warnings) >= 1.00
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Implement an easy-to-use command line interpreter based on
Term::ReadLine(3p). Although primarily aimed at use with the
Term::ReadLine::Gnu(3p) implementation, it also supports
Term::ReadLine::Perl(3p).

%prep
%setup -q -n Term-CLI-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README.md Changes LICENSE Contributors CONTRIBUTING.md
%doc tutorial examples
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Mon Feb 14 2022 Steven Bakker <sb@monkey-mind.net> 0.055002-1
- New upstream release
* Mon Dec 27 2021 Steven Bakker <sb@monkey-mind.net> 0.054002-1
- New upstream release
* Mon Dec 27 2021 Steven Bakker <sb@monkey-mind.net> 0.053006-2
- New upstream release (small packaging fixes).
* Sun Dec 26 2021 Steven Bakker <sb@monkey-mind.net> 0.053006-1
- New upstream release.
* Thu Dec 23 2021 Steven Bakker <sbakker@cpan.org> 0.053005-1
- New upstream release.
* Thu Dec 23 2021 Steven Bakker <sbakker@cpan.org> 0.053004-1
- New upstream release.
* Thu Dec 23 2021 Steven Bakker <sbakker@cpan.org> 0.053003-1
- New upstream release.
* Wed May 19 2021 Steven Bakker <sbakker@cpan.org> 0.052002-1
- New upstream release.
* Fri Apr 30 2021 Steven Bakker <sbakker@cpan.org> 0.052001-1
- New upstream release.
* Mon Nov 18 2019 Steven Bakker <sbakker@cpan.org> 0.051007-1
- New upstream release.
* Wed Nov 6 2019 Steven Bakker <sbakker@cpan.org> 0.051005-1
- New upstream release.
* Tue Nov 5 2019 Steven Bakker <sbakker@cpan.org> 0.051004-2
- Fix BuildRequires and Provides
* Tue Nov 5 2019 Steven Bakker <sbakker@cpan.org> 0.051004-1
- New upstream release.
* Wed Jul 11 2018 Steven Bakker <sbakker@cpan.org> 0.051003-1
- New upstream release.
* Fri Mar 16 2018 Steven Bakker <sbakker@cpan.org> 0.051002-1
- New upstream release.
* Fri Mar 16 2018 Steven Bakker <sbakker@cpan.org> 0.05002-1
- New upstream release.
* Tue Mar 13 2018 Steven Bakker <sbakker@cpan.org> 0.04008-1
- New upstream release.
* Tue Mar 13 2018 Steven Bakker <sbakker@cpan.org> 0.04007-1
- New upstream release.
* Sat Mar 10 2018 Steven Bakker <sbakker@cpan.org> 0.04004-1
- New upstream release.
* Mon Feb 26 2018 Steven Bakker <sbakker@cpan.org> 0.03002-1
- New upstream release.
* Mon Feb 26 2018 Steven Bakker <sbakker@cpan.org> 0.03001-1
- New upstream release.
* Mon Feb 26 2018 Steven Bakker <sbakker@cpan.org> 0.03-1
- New upstream release.
* Sun Feb 25 2018 Steven Bakker <sbakker@cpan.org> 0.02-1
- Specfile autogenerated by cpanspec 1.78.
