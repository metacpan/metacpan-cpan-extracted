%define zname <% $zilla->name %>
Name: perl-%{zname}
Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
Release: 1

Summary: <% $zilla->abstract %>
License: GPL+ or Artistic
Group: Applications/CPAN
BuildArch: noarch
URL: <% $zilla->license->url %>
Vendor: <% $zilla->license->holder %>
Source: <% $archive %>

BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD

%description
<% $zilla->abstract %>

%prep
%setup -q -n %{zname}-%version

%build
perl Makefile.PL PREFIX=/usr
make test

%install
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
make install DESTDIR=%{buildroot}

if [ "%{buildroot}" != "/" ] ; then
    rm -Rf %{buildroot}/usr/lib64/perl5
fi

rm -f %{_tmppath}/filelist
touch %{_tmppath}/filelist

find %{buildroot}/usr/share/man/man3 -type d | sed -e 's#%{buildroot}##' >> %{_tmppath}/filelist
# will be gzipped later on
find %{buildroot}/usr/share/man/man3 -type f | sed -e 's#%{buildroot}##' |sed -e 's#$#.gz#' >> %{_tmppath}/filelist

find %{buildroot}/usr/share/perl5/Net | sed -e 's#%{buildroot}##' >> %{_tmppath}/filelist

cat %{_tmppath}/filelist

%clean
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
rm -f %{_tmppath}/filelist

%files -f %{_tmppath}/filelist
%defattr(-,root,root)
