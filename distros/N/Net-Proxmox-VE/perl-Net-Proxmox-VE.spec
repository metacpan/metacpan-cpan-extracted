%define upstream_name 	 Net-Proxmox-VE
%define upstream_version 0.33

%{?perl_default_filter}

Name:       perl-%{upstream_name}
Version:    %{upstream_version}
Release:    1

Summary:    API to access ProxMox VE
License:    GPL+ or Artistic
Group:      Development/Perl
Url:        https://github.com/mrproper/proxmox-ve-api-perl
Source0:    https://github.com/mrproper/proxmox-ve-api-perl/archive/v0.33.tar.gz

BuildArch:  noarch

%description
This Class provides the framework for talking to Proxmox VE 2.0
API instances. This just provides a get/delete/put/post abstraction layer as
methods on Proxmox VE REST API This also handles the ticket headers required
for authentication

More details on the API can be found here:
http://pve.proxmox.com/wiki/Proxmox_VE_API http://pve.proxmox.com/pve2-api-doc/

This class provides the building blocks for someone wanting to use PHP to talk
to Proxmox 2.0. Relatively simple piece of code, just provides a
get/put/post/delete abstraction layer as methods on top of Proxmox's REST API,
while also handling the Login Ticket headers required for authentication.

%prep
%setup -q -n proxmox-ve-api-perl-%{upstream_version}

%build


%install
mkdir -p $RPM_BUILD_ROOT/%{perl_vendorlib}
cp -r lib/Net $RPM_BUILD_ROOT/%{perl_vendorlib}/
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/perl-%{upstream_name}
cp -r README.pod Changes $RPM_BUILD_ROOT/usr/share/doc/perl-%{upstream_name}/
cp -r examples $RPM_BUILD_ROOT/usr/share/doc/perl-%{upstream_name}/

%files
%doc /usr/share/doc/perl-%{upstream_name}/README.pod
%doc /usr/share/doc/perl-%{upstream_name}/Changes
/usr/share/doc/perl-%{upstream_name}/examples
%{perl_vendorlib}/Net

%changelog
* Tue Mar 26 2019 eric bollengier <eric@baculasystems.com> 0.33
- 0.33
