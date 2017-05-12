#$Revision: 1.9 $
do 'CIDR.pm';

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
Release: 1%(%{__perl} -e 'my $v=$^V; $v =~ s/(.)/".".ord($1)/ge;print "$v\n";')
Source0: Net-CIDR-%{version}.tar.gz
License: Perl
Group: Development/Languages
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch: noarch
BuildPreReq: perl

%description
The Net::CIDR perl module manipulates IPv4/IPv6 netblocks in CIDR notation

%prep
%setup -q -n Net-CIDR-%{version}
%{__perl} Makefile.PL PREFIX=$RPM_BUILD_ROOT%{_prefix}
%build
%{__make}

%install
rm -rf $RPM_BUILD_ROOT
%{__make} install
find $RPM_BUILD_ROOT \( -name .packlist -o -name perllocal.pod \) -exec rm -f {} \;

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{_prefix}/lib/perl5/site_perl/*/Net
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

