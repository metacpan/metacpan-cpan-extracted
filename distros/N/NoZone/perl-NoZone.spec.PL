use strict;

die unless (scalar @ARGV == 1);

open SRC, "lib/NoZone.pm"
    or die "lib/NoZone.pm: $!";

our $VERSION;
while (<SRC>) {
    if (/\$VERSION\s*=\s*'(.*)'/) {
        $VERSION=$1;
    }
}
close SRC;

die "missing VERSION" unless defined $VERSION;

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$VERSION/g;

open SPEC, ">$ARGV[0]" or die "$!";
print SPEC $_;
close SPEC;
__DATA__
# Automatically generated by perl-NoZone.spec.PL

Name:           perl-NoZone
Version:        @VERSION@
Release:        1%{?dist}
Summary:        A Bind DNS zone generator
License:        GPLv3+
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/NoZone/
Source0:        http://www.cpan.org/modules/by-module/NoZone/NoZone-%{version}.tar.gz
BuildArch:      noarch
BuildRequires:  perl(YAML)
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(File::Spec::Functions)
BuildRequires:  perl(File::Temp)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Pod)
BuildRequires:  perl(Test::Pod::Coverage)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
NoZone is a tool for simplifying the management of Bind DNS Zone files, by
eliminating the need to write them directly. NoZone defines a simple,
structured configuration file, from which Bind DNS zone files are
generated. For cases where there are many domains sharing the same basic
DNS records, it will greatly reduce the duplication of information. Use of
a higher level configuration format, protects the administrator from many
of the potential pitfalls inherent in the archaic Bind zone format.

%prep
%setup -q -n NoZone-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc AUTHORS CHANGES etc LICENSE META.json README
%config(noreplace) %{_sysconfdir}/nozone.yml
%{_bindir}/nozone
%{perl_vendorlib}/*
%{_mandir}/man3/NoZone*.3*
%{_mandir}/man1/nozone.1*

%changelog
