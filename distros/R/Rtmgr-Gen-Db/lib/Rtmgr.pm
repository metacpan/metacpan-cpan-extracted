package Rtmgr;

use 5.006;
use strict;
use warnings;
use Data::Dump qw(dump);
use Config::File;

our @ISA= qw( Exporter );

use Rtmgr::Gen::Db qw(get_download_list create_db_table get_name get_tracker calc_scene insert_into_database_missing get_difference_between_server_and_database add_remove_extraneous_reccords);
use Rtmgr::Gen qw( run_create_db run_db_pop_id run_extraneous_reccords run_db_pop_torname run_db_pop_tracker run_db_pop_srrdb );

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





=head2 get

=cut



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
