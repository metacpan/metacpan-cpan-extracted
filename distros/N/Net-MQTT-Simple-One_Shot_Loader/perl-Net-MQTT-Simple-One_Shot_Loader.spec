Name:           perl-Net-MQTT-Simple-One_Shot_Loader
Version:        0.03
Release:        1%{?dist}
Summary:        Perl package to add one_shot method to Net::MQTT::Simple
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Net-MQTT-Simple-One_Shot_Loader/
Source0:        http://www.cpan.org/modules/by-module/Net/Net-MQTT-Simple-One_Shot_Loader-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Net::MQTT::Simple) >= 1.24
BuildRequires:  perl(IO::Socket::IP)
BuildRequires:  perl(Time::HiRes)
Requires:       perl(Net::MQTT::Simple) >= 1.24
Requires:       perl(IO::Socket::IP)
Requires:       perl(IO::Socket::SSL)
Requires:       perl(Time::HiRes)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This package loads the one_shot method into the Net::MQTT::Simple name
space to provide a well tested remote procedure call (RPC) via MQTT. Many
IoT devices only support MQTT as a protocol so, in order to query state or
settings these properties need to be requested by sending a message on one
queue and receiving a response on another queue.

%prep
%setup -q -n Net-MQTT-Simple-One_Shot_Loader-%{version}

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
%doc LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
