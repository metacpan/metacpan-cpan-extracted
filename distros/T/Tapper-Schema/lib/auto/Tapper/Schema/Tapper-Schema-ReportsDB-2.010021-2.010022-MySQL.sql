-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010021-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010022':;

BEGIN;

ALTER TABLE reportsection DROP COLUMN test_was_on_guest,
                          DROP COLUMN test_was_on_hv,
                          ADD COLUMN uptime VARCHAR(50),
                          ADD COLUMN xen_version VARCHAR(255),
                          ADD COLUMN xen_guest_test VARCHAR(255),
                          ADD COLUMN xen_guest_start VARCHAR(255),
                          ADD COLUMN kvm_kernel text,
                          ADD COLUMN kvm_base_os_description text,
                          ADD COLUMN kvm_guest_description text,
                          ADD COLUMN kvm_module_version VARCHAR(255),
                          ADD COLUMN kvm_userspace_version VARCHAR(255),
                          ADD COLUMN kvm_guest_flags VARCHAR(255),
                          ADD COLUMN kvm_guest_test VARCHAR(255),
                          ADD COLUMN kvm_guest_start VARCHAR(255),
                          CHANGE COLUMN language_description language_description text;


COMMIT;

