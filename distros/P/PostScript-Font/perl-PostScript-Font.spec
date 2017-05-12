Summary: PostScript::Font analyzes PostScript fonts
%define module PostScript-Font
Name: perl-%{module}
Version: 1.09
Release: 1
Source: %{module}-%{version}.tar.gz
Copyright: Artistic
Group: Utilities/Printing
Packager: Johan Vromans <jvromans@squirrel.nl>
BuildRoot: /usr/tmp/%{name}-buildroot
Requires: perl >= 5.6.0

%description
This package contains a couple of modules to get information for and
from PostScript fonts and associated metrics files. Also included is a
module to facilitate basic typesetting, a program to make font
samples, and programs to handle the conversion of font data to
PostScript binary (.pfb) and ASCII (.pfa) formats. Example program
shows how basic typesetting can be obtained.

Optionally, it can also handle True Type fonts.

%prep
%setup -n %{module}-%{version}

%build
perl Makefile.PL
make all
make test

%install
rm -fr $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr
make install PREFIX=$RPM_BUILD_ROOT/usr

# Remove some unwanted files
find $RPM_BUILD_ROOT -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -name perllocal.pod -exec rm -f {} \;

# Compress manual pages
test -x /usr/lib/rpm/brp-compress && /usr/lib/rpm/brp-compress

# Build distribution list
( cd $RPM_BUILD_ROOT ; find * -type f -printf "/%p\n" ) > files

%files -f files
%doc README CHANGES examples
