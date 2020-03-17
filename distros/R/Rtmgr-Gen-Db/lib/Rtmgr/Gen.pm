package Rtmgr::Gen;

use 5.006;
use strict;
use warnings;
use Data::Dump qw(dump);
use Config::File;

our @ISA= qw( Exporter );

use Rtmgr::Gen::Db qw(get_download_list create_db_table get_name get_tracker calc_scene insert_into_database_missing get_difference_between_server_and_database add_remove_extraneous_reccords);
use Exporter 'import';
our @EXPORT_OK = qw(get_download_list create_db_table get_name get_tracker calc_scene insert_into_database_missing get_difference_between_server_and_database add_remove_extraneous_reccords);

our @EXPORT = qw( run_create_db run_db_pop_id run_extraneous_reccords run_db_pop_torname run_db_pop_tracker run_db_pop_srrdb );

	
=head1 NAME

Rtmgr::Gen - Connect to rTorrent/ruTorrent installation and get a list of torrents, storing them to a database.!

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Connects to a rTorrent/ruTorrent installation.

=head1 SUBROUTINES/METHODS

#use Rtmgr::Gen qw( run_create_db run_db_pop_id run_extraneous_reccords run_db_pop_torname run_db_pop_tracker run_db_pop_srrdb );

---
Create a config file called '.config' in the directory you will be running the module from.

--- Content of .config file. ---

SEEDBOX_UN = username
SEEDBOX_PW = password
SEEDBOX_HN = host
SEEDBOX_PR = 443
SEEDBOX_EP = RPC2
DATABASE = database
SRRDB_UN = srrdb_username
SRRDB_PW = srrdb_password

--- ---

#/usr/bin/env perl

use Rtmgr::Gen;

# Create the database.
Rtmgr::Gen->run_create_db();

# Populate the database with torrent hashes.
Rtmgr::Gen->run_db_pop_id();

# Remove Extraneous Reccords from Database.
Rtmgr::Gen->run_extraneous_reccords();

# Populate the database with the names of the torrents.
Rtmgr::Gen->run_db_pop_torname();

# Populate the database with the trackers.
Rtmgr::Gen->run_db_pop_tracker();

# Populate the database with SRRDB Entry if available.
Rtmgr::Gen->run_db_pop_srrdb();

=head2 get

=cut

# Config file setup.
my $configuration_file = '.config';
# Check for existence of config file.
if (not -e $configuration_file) {
    print "The '.config' file does not exist!\n";
    exit;
}
my $cnf = Config::File::read_config_file($configuration_file);

sub run_print_config {
print "$cnf->{DATABASE}\n"; # Database
print "$cnf->{SEEDBOX_UN}\n"; # Username
print "$cnf->{SEEDBOX_PR}\n"; # Port
print "$cnf->{SEEDBOX_PW}\n"; # Password
print "$cnf->{SEEDBOX_HN}\n"; # Hostname
print "$cnf->{SEEDBOX_EP}\n"; # RPC2
print "$cnf->{SRRDB_PW}\n"; # SRRDB Password
print "$cnf->{SRRDB_UN}\n"; # SRRDB Username
}

sub run_create_db {
# Create Database.
my $create_db = create_db_table("$cnf->{DATABASE}");
print $create_db;
}

sub run_db_pop_id {
# Populate database with ID's 'HASH' of torrents.
my $dl_list_arr_ref = get_download_list("$cnf->{SEEDBOX_UN}","$cnf->{SEEDBOX_PW}","$cnf->{SEEDBOX_HN}","$cnf->{SEEDBOX_PR}","$cnf->{SEEDBOX_EP}","$cnf->{DATABASE}");
insert_into_database_missing($dl_list_arr_ref,"$cnf->{DATABASE}");
}

sub run_extraneous_reccords {
# Remove Extraneous Reccords from Database.
my $dl_list_ext_reccords = get_download_list("$cnf->{SEEDBOX_UN}","$cnf->{SEEDBOX_PW}","$cnf->{SEEDBOX_HN}","$cnf->{SEEDBOX_PR}","$cnf->{SEEDBOX_EP}","$cnf->{DATABASE}");
my $diff_list = get_difference_between_server_and_database($dl_list_ext_reccords,"$cnf->{DATABASE}");
add_remove_extraneous_reccords($diff_list,'database');
}
sub run_db_pop_torname {
# Populate database with Torrent Names.
my $get_name = get_name("$cnf->{SEEDBOX_UN}","$cnf->{SEEDBOX_PW}","$cnf->{SEEDBOX_HN}","$cnf->{SEEDBOX_PR}","$cnf->{SEEDBOX_EP}","$cnf->{DATABASE}");
print $get_name;
}

sub run_db_pop_tracker {
# Populate database with trackers.
my $get_tracker = get_tracker("$cnf->{SEEDBOX_UN}","$cnf->{SEEDBOX_PW}","$cnf->{SEEDBOX_HN}","$cnf->{SEEDBOX_PR}","$cnf->{SEEDBOX_EP}","$cnf->{DATABASE}");
print $get_tracker;
}

sub run_db_pop_srrdb {
# Check if release is a scene release by checking for entry in srrdb.
my $calc_scene = calc_scene("$cnf->{SRRDB_UN}","$cnf->{SRRDB_PW}","$cnf->{DATABASE}");
print $calc_scene;
}

=head1 AUTHOR

Clem Morton, C<< <clem at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rtmgr-gen-db at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rtmgr-Gen-Db>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rtmgr::Gen

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rtmgr-Gen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rtmgr-Gen>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rtmgr-Gen>

=item * Search CPAN

L<https://metacpan.org/release/Rtmgr-Gen>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Clem Morton.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Rtmgr::Gen
