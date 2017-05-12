%define perl_vendorlib %(eval "`perl -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`perl -V:installvendorarch`"; echo $installvendorarch)
%define svn_revision %(svn info . | grep Revision | awk '{print $NF;}')

%define real_name Pinwheel

Name: perl-Pinwheel
Summary: A Perl framework for building web applications
Version: 0.2.7
Release: %{svn_revision}
License: Internal BBC use only
Group: Applications/CPAN
Source: Pinwheel-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
BuildRequires: perl

%description
A Rails-like framework for building dynamic web applications in Perl.

%prep
%setup -n %{real_name}-%{version}

%build
%{__perl} Build.PL
%{__perl} Build

%install
%{__rm} -rf %{buildroot}
PERL_INSTALL_ROOT="%{buildroot}" %{__perl} Build install installdirs="vendor"

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(0644, root, root, 0755)
%doc NEWS README
%{perl_vendorlib}/Pinwheel.pm
%{perl_vendorlib}/Pinwheel/Cache.pm
%{perl_vendorlib}/Pinwheel/Cache/Hash.pm
%{perl_vendorlib}/Pinwheel/Cache/Memcached.pm
%{perl_vendorlib}/Pinwheel/Cache/Null.pm
%{perl_vendorlib}/Pinwheel/Commands/Console.pm
%{perl_vendorlib}/Pinwheel/Commands/Routes.pm
%{perl_vendorlib}/Pinwheel/Commands/Server.pm
%{perl_vendorlib}/Pinwheel/Context.pm
%{perl_vendorlib}/Pinwheel/Controller.pm
%{perl_vendorlib}/Pinwheel/Database.pm
%{perl_vendorlib}/Pinwheel/Database/Base.pm
%{perl_vendorlib}/Pinwheel/Database/Mysql.pm
%{perl_vendorlib}/Pinwheel/Database/Sqlite.pm
%{perl_vendorlib}/Pinwheel/Helpers.pm
%{perl_vendorlib}/Pinwheel/Helpers/Core.pm
%{perl_vendorlib}/Pinwheel/Helpers/DateTime.pm
%{perl_vendorlib}/Pinwheel/Helpers/List.pm
%{perl_vendorlib}/Pinwheel/Helpers/SSI.pm
%{perl_vendorlib}/Pinwheel/Helpers/Tag.pm
%{perl_vendorlib}/Pinwheel/Helpers/Text.pm
%{perl_vendorlib}/Pinwheel/Mapper.pm
%{perl_vendorlib}/Pinwheel/Model.pm
%{perl_vendorlib}/Pinwheel/Model/Base.pm
%{perl_vendorlib}/Pinwheel/Model/Date.pm
%{perl_vendorlib}/Pinwheel/Model/DateBase.pm
%{perl_vendorlib}/Pinwheel/Model/Time.pm
%{perl_vendorlib}/Pinwheel/ModperlHandler.pm
%{perl_vendorlib}/Pinwheel/View/Data.pm
%{perl_vendorlib}/Pinwheel/View/Data.pod
%{perl_vendorlib}/Pinwheel/View/ERB.pm
%{perl_vendorlib}/Pinwheel/View/String.pm
%{perl_vendorlib}/Pinwheel/View/Wrap.pm
%{perl_vendorlib}/Pinwheel/View/Wrap/Array.pm
%{perl_vendorlib}/Pinwheel/View/Wrap/Scalar.pm


################################################################################

%package devel
Summary: A Perl framework for building web applications - development files.
Group: Applications/CPAN
Requires: perl-Pinwheel = %{version}-%{release}

%description devel
Perl Modules required for Pinwheel application development.

%files devel
%defattr(0644, root, root, 0755)
%doc NEWS README
%doc %{_mandir}/man3/*
%{perl_vendorlib}/Pinwheel/DocTest.pm
%{perl_vendorlib}/Pinwheel/Fixtures.pm
%{perl_vendorlib}/Pinwheel/TagSelect.pm
%{perl_vendorlib}/Pinwheel/TestHelper.pm
%{perl_vendorlib}/Module/Build/PinwheelApp.pm


%changelog
* Wed May 13 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.7
- Added 'difference' method to the Pinwheel::Model::Date class. 

* Mon Apr 27 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.6
- Fixed database reconnection bug.

* Wed Apr 15 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.5
- Added documentation for the Pinwheel::Cache module
- The caching backend is now an object and should implement the Cache::Cache API
- Wrote three built-in caching backend modules: Null, Cache, Memcached
- Added new 'test' and 'setup_test_db' actions to Pinweel application build scripts.

* Thu Mar 12 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.4
- Added JSON with HTML syntax highlighting to data view.

* Sat Mar  7 2009 Paul Clifford <paul.clifford@bbc.co.uk> - 0.2.3
- Single table inheritance bugfixes.

* Wed Feb 25 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.2
- Fixed bug where redirects wouldn't work under mod_perl if non-port 80 was used.

* Thu Feb 19 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.1
- Split off a separate devel package

* Thu Feb 12 2009 Nicholas Humfrey <nicholas.humfrey@bbc.co.uk> - 0.2.0
- Changed to Module::Build
- Updated to release 0.2.0

* Mon Dec 22 2008 Paul Clifford <paul.clifford@bbc.co.uk> - 0.1.0
- Initial spec file.

