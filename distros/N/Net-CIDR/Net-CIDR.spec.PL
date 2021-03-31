#$Revision: 1.9 $
do './lib/Net/CIDR.pm';

open (X, ">Net-CIDR.spec") || die "$!\n";

while (<DATA>)
{
    s/\@VERSION\@/$Net::CIDR::VERSION/e;
    print X;
}
close(X);
__END__

Summary: Net::CIDR Perl module
Name: perl-Net-CIDR
Version: @VERSION@
Release: 1.%{perl_version}%{?dist}
Source0: Net-CIDR-%{version}.tar.gz
License: Perl
Group: Development/Languages
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch: noarch
%define need_perl_generators %(if rpm -q fedora-release >/dev/null 2>/dev/null; then echo "1"; exit 0; fi; echo "1"; exit 1)

%if %need_perl_generators
BuildRequires: perl-interpreter
BuildRequires: perl-generators
%else
BuildRequires: perl
%endif
Requires:       perl(:MODULE_COMPAT_%(eval "`perl -V:version`"; echo $version))

%description
The Net::CIDR perl module manipulates IPv4/IPv6 netblocks in CIDR notation

%prep
%setup -q -n Net-CIDR-%{version}
%{__perl} Makefile.PL INSTALLDIRS=vendor
%build
%{make_build}

%install
rm -rf $RPM_BUILD_ROOT
%{__make} pure_install DESTDIR=$RPM_BUILD_ROOT INSTALLDIRS=vendor
find $RPM_BUILD_ROOT \( -name .packlist -o -name perllocal.pod \) -exec rm -f {} \;
%{_fixperms} %{buildroot}/*

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{perl_privlib}/vendor_perl/Net
%{_mandir}/man3/*

%changelog
* Wed Aug 13 2003 Mr. Sam <sam@email-scan.com>
- Use preferred BuildRoot

* Sun Mar 31 2002 Mr. Sam <sam@email-scan.com>
- Changed package name to perl-Net-CIDR

* Fri Nov  2 2001 Mr. Sam <mrsam@courier-mta.com>
- Changed package name to perl-net-cidr

* Tue Jun 26 2001 Mr. Sam <mrsam@courier-mta.com>
- Initial build.
