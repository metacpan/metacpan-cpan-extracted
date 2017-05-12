# $Id$
Summary: test rpm dependencies for perl-URPM test suite
BuildArch: noarch
Name: test-dep
Version: 1.0
Release: 1mdk
License: GPL
Group: Application/Development
BuildRoot: %{_tmppath}/%{name}-root
Requires: test-rpm
Conflicts: test-rpm
Obsoletes: test-rpm

%description
test rpm for dependencies

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


