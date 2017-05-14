%define fedora 4
%define rhel 0
#define dist .fc

Summary: 	perl/Qt4 libraries
Name: 		perl-QtGui
Version: 	4.004
Release: 	0%{?dist}

Group: 		User Interface/Development
License: 	GPL
URL: 		http://klv.lg.ua/~vadim/perlqt4/
Source: 	QtGui-%{version}.tar.bz2

BuildRoot: 	%{_tmppath}/%{name}-%{version}-root-%(%{__id_u} -n)

BuildRequires: 	perl qt4-devel perl-QtCore = %{version}
Requires:	perl qt4 perl-QtCore = %{version}


%description
perl Qt4 QtGui


%prep
rm -rf $RPM_BUILD_ROOT
%setup -q -n QtGui-%{version}


%build
CFLAGS="$RPM_OPT_FLAGS" %{__perl} Makefile.PL -qc ../QtCore-%{version} INSTALLDIRS=vendor 
make %{?_smp_mflags} OPTIMIZE="$RPM_OPT_FLAGS"


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
chmod -R u+w $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc AUTHORS Changes README TODO
%{perl_vendorarch}/*


%changelog
* Mon Feb 04 2008 Vadim Likhota <vadim-lvv@yandex.ru> 4.004
- update ver

* Wed Nov 26 2007 Vadim Likhota <vadim-lvv@yandex.ru> 4.000
- create this file
