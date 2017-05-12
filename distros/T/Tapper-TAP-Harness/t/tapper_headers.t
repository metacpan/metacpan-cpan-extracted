#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use TAP::DOM;

# ============================================================

my $tap     = slurp ("t/tap_archive_headers_kvm.tap");
my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 4, "count sections");

# report meta
is($harness->parsed_report->{report_meta}{'suite-name'},    'Daily-Report',  "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.01',          "report meta suite version");
is($harness->parsed_report->{report_meta}{'machine-name'},  'kepek',         "report meta machine name");
is($harness->parsed_report->{report_meta}{'reportername'},  'sschwigo',      "report meta reportername");
is($harness->parsed_report->{report_meta}{'hardwaredb-systems-id'},  4711,   "report meta hardwaredb systems id");
is($harness->parsed_report->{report_meta}{'machine-description'},  'PC-Ware', "report meta machine-description");
is($harness->parsed_report->{report_meta}{'cpuinfo'},  '1x Family: 15, Model: 107, Stepping: 1', "report meta cpuinfo");
is($harness->parsed_report->{report_meta}{'ram'},  '3839 MB', "report meta ram");
is($harness->parsed_report->{report_meta}{'uptime'},  '21 hrs', "report meta uptime");
is($harness->parsed_report->{report_meta}{'bios'}, 'American Megatrends Inc., 0201, 10/15/2007', "report meta bios");

# report meta db
is($harness->parsed_report->{db_report_meta}{machine_name},          'kepek',   "db report meta machine name");
is($harness->parsed_report->{db_report_meta}{reportername},          'sschwigo', "db report meta reportername");
is($harness->parsed_report->{db_report_meta}{hardwaredb_systems_id}, 4711,      "db report meta hardwaredb systems id");
is($harness->parsed_report->{db_report_meta}{machine_description},   'PC-Ware', "db report meta machine-description");

is($harness->parsed_report->{db_report_reportcomment_meta}{reportcomment},   'Hot Funky Report', "db reportcomment meta comment");

# sections
is($harness->parsed_report->{tap_sections}[0]{section_name},'Metainfo',                     "section name 0");
is($harness->parsed_report->{tap_sections}[1]{section_name},'KVM-Metainfo',                 "section name 1");
is($harness->parsed_report->{tap_sections}[2]{section_name},'guest_1_ms_vista_32b_up_qcow', "section name 2");
is($harness->parsed_report->{tap_sections}[3]{section_name},'host',                         "section name 3");

# kvm meta
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'kvm-module-version'}, 'kvm-84-6620-ge3dbe3f', "section 1 meta kvm-module-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'kvm-userspace-version'}, 'kvm-84-488-gee8b55c', "section 1 meta kvm-userspace-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'kvm-base-os-description'}, 'Fedora release 10 (Cambridge)', "section 1 meta kvm-base-os-description");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'kvm-kernel'}, '2.6.27.21-170.2.56.fc10.x86_64 x86_64', "section 1 meta kvm-kernel");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'description'}, 'description affe 0', "section 1 meta description");

# kvm meta db
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{kvm_module_version}, 'kvm-84-6620-ge3dbe3f', "section 1 meta kvm-module-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{kvm_userspace_version}, 'kvm-84-488-gee8b55c', "section 1 meta kvm-userspace-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{kvm_base_os_description}, 'Fedora release 10 (Cambridge)', "section 1 meta kvm-base-os-description");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{kvm_kernel}, '2.6.27.21-170.2.56.fc10.x86_64 x86_64', "section 1 meta kvm-kernel");

# kvm guest meta
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'kvm-guest-description'}, '001-WinSST', "section 2 meta kvm-guest-description");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'kvm-guest-test'}, 'WinSST-4.7.4', "section 2 meta kvm-guest-test");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'kvm-guest-start'}, '2009-04-06 19:52:18', "section 2 meta kvm-guest-start");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'kvm-guest-flags'}, '-m 2304 -smp 1', "section 2 meta kvm-guest-flags");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'description'}, 'description affe 1', "section 2 meta description");

# ============================================================

$tap     = slurp ("t/tap_archive_headers_xen.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 5, "count sections");

is($harness->parsed_report->{report_meta}{'suite-name'},    'Daily-Report',   "report meta suite-name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.01',           "report meta suite-version");
is($harness->parsed_report->{report_meta}{'machine-name'},  'irida',          "report meta machine-name");
is($harness->parsed_report->{report_meta}{'hardwaredb-systems-id'}, 4712,     "report meta hardwaredb systems id");
is($harness->parsed_report->{report_meta}{'machine-description'},  'PC-Ware', "report meta machine-description");
is($harness->parsed_report->{report_meta}{'cpuinfo'},  '1x Family: 15, Model: 107, Stepping: 1', "report meta cpuinfo");
is($harness->parsed_report->{report_meta}{'ram'},  '3967 MB', "report meta ram");
is($harness->parsed_report->{report_meta}{'uptime'},  '96 hrs', "report meta uptime");

# sections
is($harness->parsed_report->{tap_sections}[0]{section_name},'Metainfo',                                 "section name 0");
is($harness->parsed_report->{tap_sections}[1]{section_name},'XEN-Metainfo',                             "section name 1");
is($harness->parsed_report->{tap_sections}[2]{section_name},'guest_1_redhat_rhel4u8_beta_32b_up_qcow',  "section name 2");
is($harness->parsed_report->{tap_sections}[3]{section_name},'guest_2_redhat_rhel4u8_beta_32b_smp_qcow', "section name 3");
is($harness->parsed_report->{tap_sections}[4]{section_name},'dom0',                                     "section name 4");

# xen meta
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'xen-version'}, '3.2.3', "section 1 meta xen-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'xen-changeset'}, '17040:6fc6ca3c393a', "section 1 meta xen-changeset");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'xen-base-os-description'}, 'SUSE Linux Enterprise Server 10 SP2 (i586)', "section 1 meta xen-base-os-description");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'xen-dom0-kernel'}, '2.6.18.8-xen i686', "section 1 meta xen-dom0-kernel");

# xen meta db
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{xen_version}, '3.2.3', "db section 1 meta xen-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{xen_changeset}, '17040:6fc6ca3c393a', "db section 1 meta xen-changeset");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{xen_base_os_description}, 'SUSE Linux Enterprise Server 10 SP2 (i586)', "db section 1 meta xen-base-os-description");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{xen_dom0_kernel}, '2.6.18.8-xen i686', "db section 1 meta xen-dom0-kernel");

# xen guest meta
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-description'}, '001-CTCS', "section 2 meta xen-guest-description");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-test'}, 'CTCS-1.3.1pre1', "section 2 meta xen-guest-test");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-start'}, '2009-04-06 17:54:57 CEST', "section 2 meta xen-guest-start");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-flags'}, 'acpi=1; apic=1; memory=2048; pae=1; shadow_memory=20; timer_mode=2; vcpus=1', "section 2 meta xen-guest-flags");

# ============================================================

$tap     = slurp ("t/tap_archive_headers_simnow.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 5, "count sections");

is($harness->parsed_report->{report_meta}{'suite-name'},    'Daily-Report',   "report meta suite-name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.01',           "report meta suite-version");
is($harness->parsed_report->{report_meta}{'machine-name'},  'irida',          "report meta machine-name");
is($harness->parsed_report->{report_meta}{'hardwaredb-systems-id'}, 4712,     "report meta hardwaredb systems id");
is($harness->parsed_report->{report_meta}{'machine-description'},  'PC-Ware', "report meta machine-description");
is($harness->parsed_report->{report_meta}{'cpuinfo'},  '1x Family: 15, Model: 107, Stepping: 1', "report meta cpuinfo");
is($harness->parsed_report->{report_meta}{'ram'},  '3967 MB', "report meta ram");
is($harness->parsed_report->{report_meta}{'uptime'},  '96 hrs', "report meta uptime");

# sections
is($harness->parsed_report->{tap_sections}[0]{section_name},'Metainfo',                                 "section name 0");
is($harness->parsed_report->{tap_sections}[1]{section_name},'SimNow-Metainfo',                          "section name 1");
is($harness->parsed_report->{tap_sections}[2]{section_name},'guest_1_redhat_rhel4u8_beta_32b_up_qcow',  "section name 2");
is($harness->parsed_report->{tap_sections}[3]{section_name},'guest_2_redhat_rhel4u8_beta_32b_smp_qcow', "section name 3");
is($harness->parsed_report->{tap_sections}[4]{section_name},'dom0',                                     "section name 4");

# simnow meta
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-version'},                  '4.6.1', "section 1 meta simnow-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-svn-version'},              '17050', "section 1 meta simnow-svn-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-svn-repository'},           'svn+ssh://svdcsvn1/proj/svn/smn/simnow/trunk', "section 1 meta simnow-svn-repository");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-device-interface-version'}, '16384', "section 1 meta simnow-device-interface-version");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-bsd-file'},                 'vp_bd_phase2', "section 1 meta simnow-bsd-file");
is($harness->parsed_report->{tap_sections}[1]{section_meta}{'simnow-image-file'},               'openSUSE11.1', "section 1 meta simnow-image-file");

# simnow meta db
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_version'},                  '4.6.1', "db section 1 meta simnow-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_svn_version'},              '17050', "db section 1 meta simnow-svn-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_svn_repository'},           'svn+ssh://svdcsvn1/proj/svn/smn/simnow/trunk', "db section 1 meta simnow-svn-repository");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_device_interface_version'}, '16384', "db section 1 meta simnow-device-interface-version");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_bsd_file'},                 'vp_bd_phase2', "db section 1 meta simnow-bsd-file");
is($harness->parsed_report->{tap_sections}[1]{db_section_meta}{'simnow_image_file'},               'openSUSE11.1', "db section 1 meta simnow-image-file");

# xen guest meta
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-description'}, '001-CTCS', "section 2 meta xen-guest-description");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-test'}, 'CTCS-1.3.1pre1', "section 2 meta xen-guest-test");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-start'}, '2009-04-06 17:54:57 CEST', "section 2 meta xen-guest-start");
is($harness->parsed_report->{tap_sections}[2]{section_meta}{'xen-guest-flags'}, 'acpi=1; apic=1; memory=2048; pae=1; shadow_memory=20; timer_mode=2; vcpus=1', "section 2 meta xen-guest-flags");

# ============================================================

done_testing();
