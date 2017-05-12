# $Id: test-rpm.spec 109 2006-06-21 14:47:24Z nanardon $
Summary: test rpm for perl-URPM test suite
BuildArch: noarch
Name: test-rpm
Version: 1.0
Release: 1mdk
License: GPL
Group: Application/Development
BuildRoot: %{_tmppath}/%{name}-root
Url: http://rpm4.zarb.org/
Source: http://rpm4.zarb.org/source.tar.gz

%description
test rpm

%prep

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%_sysconfdir

date >> $RPM_BUILD_ROOT%_sysconfdir/%name

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%config(noreplace) %_sysconfdir/%name

%changelog
* Thu Apr 22 2004 Olivier Thauvin <thauvin@aerov.jussieu.fr> 1-1mdk
- initial build 


