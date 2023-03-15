%define lowername  power-outlet

Name:           perl-Power-Outlet
Version:        0.48
Release:        1%{?dist}
Summary:        Control and query network attached power outlets
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Power-Outlet/
Source0:        http://www.cpan.org/modules/by-module/Power/Power-Outlet-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(Package::New)
BuildRequires:  perl(Package::Role::ini) >= 0.07
BuildRequires:  perl(HTTP::Tiny)
BuildRequires:  perl(JSON)
BuildRequires:  perl(URI)
BuildRequires:  perl(Path::Class)
BuildRequires:  perl(File::Spec)
BuildRequires:  perl(List::MoreUtils)
Requires:       perl(Net::SNMP)
Requires:       perl(Net::UPnP)
Requires:       perl(XML::LibXML::LazyBuilder)
Requires:       perl(Package::New)
Requires:       perl(Package::Role::ini) >= 0.07
Requires:       perl(HTTP::Tiny)
Requires:       perl(JSON)
Requires:       perl(URI)
Requires:       perl(Path::Class)
Requires:       perl(File::Spec)
Requires:       perl(List::MoreUtils)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Power::Outlet is a package for controlling and querying network attached
power outlets. Individual hardware drivers in this name space must provide
a common object interface for the controlling and querying of an outlet.
Common methods that every network attached power outlet must know are on,
off, query, switch and cycle. Optional methods might be implemented in some
drivers like amps and volts.

%package application-cgi
Summary:        Control multiple Power::Outlet devices from web browser
Requires:       %{name} = %{version}-%{release}
Requires:       perl(CGI)
Requires:       perl(Time::HiRes)
Requires:       perl(CGI::Carp)
Requires:       perl(Config::IniFiles)
Requires:       perl(JSON)
Requires:       perl(List::Util)
Requires:       perl(List::MoreUtils)
Requires:       perl(Parallel::ForkManager)

%package mqtt-listener
Summary:        Control Power::Outlet devices from MQTT
Requires:       %{name} = %{version}-%{release}
Requires:       perl(YAML::XS)
Requires:       perl(DateTime)
Requires:       perl(Net::MQTT::Simple)

%description application-cgi
power-outlet.cgi is a CGI application to control multiple Power::Outlet
devices. It was written to work on iPhone and look ok in most browsers.

%description mqtt-listener
power-outlet-mqtt-listener.pl is an MQTT listener for events that can be mapped to power-outlet devices.

%prep
%setup -q -n Power-Outlet-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

echo -ne "\n\n\nFiles Installed\n\n\n"
find $RPM_BUILD_ROOT
echo -ne "\n\n\nFiles in Tar Ball\n\n\n"
find
echo -ne "\n\n\n"

mkdir -p $RPM_BUILD_ROOT/%{_bindir}/
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/httpd/conf.d/
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%{lowername}/cgi-bin/
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%{lowername}/images/
mkdir -p $RPM_BUILD_ROOT/%{_unitdir}/
cp ./scripts/httpd/%{lowername}.conf $RPM_BUILD_ROOT/%{_sysconfdir}/httpd/conf.d/
cp ./scripts/images/btn-*.png       $RPM_BUILD_ROOT/%{_datadir}/%{lowername}/images/
cp ./scripts/conf/%{lowername}.ini   $RPM_BUILD_ROOT/%{_sysconfdir}/
cp ./scripts/%{lowername}.cgi        $RPM_BUILD_ROOT/%{_datadir}/%{lowername}/cgi-bin/
cp ./scripts/%{lowername}-json.cgi   $RPM_BUILD_ROOT/%{_datadir}/%{lowername}/cgi-bin/
cp ./scripts/conf/%{lowername}-mqtt-listener.yml $RPM_BUILD_ROOT/%{_sysconfdir}/
cp ./scripts/%{lowername}-mqtt-listener.pl       $RPM_BUILD_ROOT/%{_bindir}/
cp ./scripts/conf/%{lowername}-mqtt-listener.service  $RPM_BUILD_ROOT/%{_unitdir}/

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files application-cgi
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/httpd/conf.d/%{lowername}.conf
%dir %{_datadir}/%{lowername}
%dir %{_datadir}/%{lowername}/cgi-bin/
%dir %{_datadir}/%{lowername}/images/
%config(noreplace) %{_sysconfdir}/%{lowername}.ini
%attr(0755,root,root) %{_datadir}/%{lowername}/cgi-bin/%{lowername}.cgi
%attr(0755,root,root) %{_datadir}/%{lowername}/cgi-bin/%{lowername}-json.cgi
%{_datadir}/%{lowername}/images/btn-*.png

%files mqtt-listener
%defattr(-,root,root,-)
%attr(0755,root,root) %{_bindir}/%{lowername}-mqtt-listener.pl
%attr(0744,root,root) %config(noreplace) %{_sysconfdir}/%{lowername}-mqtt-listener.yml
%attr(0644,root,root) %{_unitdir}/%{lowername}-mqtt-listener.service
%{_mandir}/man1/%{lowername}-mqtt-listener.pl.1.gz

%files
%defattr(-,root,root,-)
%doc Changes LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_mandir}/man1/%{lowername}.1.gz
%attr(0755,root,root) %{_bindir}/%{lowername}

%post mqtt-listener
systemctl daemon-reload

%preun mqtt-listener
if [ $1 == 0 ]; then #uninstall
  systemctl unmask %{name}-mqtt-listener.service
  systemctl stop %{name}-mqtt-listener.service
  systemctl disable %{name}-mqtt-listener.service
fi

%postun mqtt-listener
if [ $1 == 0 ]; then #uninstall
  systemctl daemon-reload
  systemctl reset-failed
fi

%changelog
* Tue Nov 26 2013 Michael R. Davis (mrdvt92@yahoo.com) 0.01-1
- Specfile autogenerated by cpanspec 1.78.
