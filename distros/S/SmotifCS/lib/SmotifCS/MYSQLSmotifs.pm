package SmotifCS::MYSQLSmotifs;

use 5.10.1 ;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.05";

    #$AUTHOR  = "Vilas Menon(vilas\@fiserlab.org )";
    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT_OK = qw(
      connect_to_mysql
      getnid
    );

    @EXPORT = qw(
      connect_to_mysql
      getnid
      get_matching_AR_or_JA_smotifs
      get_matching_smotifs
      );    # symbols to export on request
}

our @EXPORT_OK;

use Data::Dumper;
use DBI;
use Carp;
use Config::Simple;

our $VERSION = '0.05';

# accessing a block of an ini-file;
my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};

croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set" unless $config_file;

my $cfg = new Config::Simple($config_file);
my $db = $cfg->param( -block => 'mysql' );

my $host     = $db->{'host'};
my $user     = $db->{'user'};
my $database = $db->{'database'};
my $password = $db->{'password'};
my $port     = $db->{'port'};

die "MYSQL hostname is required" unless $host;
die "MYSQL username is required" unless $user;
die "MYSQL database is required" unless $database;
die "MYSQL password is required" unless $password;
die "MYSQL port is required"     unless $port;


=head1 NAME

MYSQLSmotifs - Routines to access a Smotifs MySQL database!

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MYSQLSmotifs;

    my $foo = MYSQLSmotifs->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 connect_to_mysql 

   subroutine to connect to the mysql database

=cut
my $ldbh;
sub connect_to_mysql {

    my $dsn = "DBI:mysql:$database:$host:$port";
    $ldbh = DBI->connect( $dsn, $user, $password, { PrintError => 1 } );
    my $try = 0;
    while ( !$ldbh ) {
        die "Could not connect to MYSQL Server" if $try == 20;
        sleep(5);
        $ldbh = DBI->connect( $dsn, $user, $password, { PrintError => 1 } );
        $try++;
    }
    return $ldbh;
}

sub disconnect_to_mysql {
    $ldbh->disconnect();
}

=head2  getnid

    subroutine to obtain smotif data, given an nid number
    input 1 : $$proptable - nid number
    output 1: @$idtable   - smotif info (pdb ID, chain, start residue, ss1 length, ss2 length, loop length, nid, smotif type, sequence)

=cut
sub getnid {
    my ( $proptable, $idtable ) = @_;

    my $nid_number = $$proptable[0];
    croak "nid_number is not defined"
      unless $nid_number;

    # Connect to mysql
    my $ldbh = connect_to_mysql();

    my $query = qq{ 
		SELECT DISTINCT pdbid, chain, start, ss1length, ss2length, length, nid, type, seq 
		FROM 
		loop_descriptors 
		WHERE nid = ?
        };
    my $sth = $ldbh->prepare($query);
    $sth->bind_param( 1, $nid_number );
    $sth->execute();

    my @info = $sth->fetchrow_array();
    return 0 unless @info;

    push( @$idtable, @info );
    $sth->finish();
    $ldbh->disconnect();
    return 1;
}

=head2 get_matching_AR_or_JA_smotifs
    
    subroutine to get AR and JA matching smotifs from
    the database.
    input:
    
    loop_length    = loop length
    lenlimit       = cut-off criteria for loop length
    ss_length_limit= cut-off criteria for secondary structure length
    ss1_length     = secondary structure1 length 
    ss2_length     = secondary structure2 length
    pdb_code       = 4-letter pdb code

    return an array reference containing:
    nid, delta, theta, rho, pdbid, chain, start, ss1length, length, seq, theta,ss2length,acc 
=cut
sub get_matching_AR_or_JA_smotifs {
    my ( $loop_length, $lenlimit, $ss_length_limit, $ss1_length, $ss2_length, $pdb_code ) =
      @_;
    die "Not connected to MySQL db" unless $ldbh;
    die                             unless $loop_length;
    die                             unless $lenlimit;
    die                             unless $ss_length_limit;
    die                             unless $ss1_length;
    die                             unless $ss2_length;
    die                             unless $pdb_code;

    my $loop_length_minus_lenlimit = $loop_length - $lenlimit;
    my $loop_length_plus_lenlimit  = $loop_length + $lenlimit;
    my $ss1_lenght_minus_ll        = $ss1_length - $ss_length_limit;
    my $ss1_lenght_plus_ll         = $ss1_length + $ss_length_limit;
    my $ss2_lenght_minus_ll        = $ss2_length - $ss_length_limit;
    my $ss2_lenght_plus_ll         = $ss2_length + $ss_length_limit;

    my $ldbh  = connect_to_mysql();
    my $query = qq{ 
	SELECT loop_descriptors.nid, delta, theta, rho, pdbid, chain, start, ss1length, length, seq, theta,ss2length,acc 
	FROM loop_descriptors 
	INNER join loops2geom ON loop_descriptors.nid=loops2geom.nid 
	WHERE 
        length > ? AND length < ? AND 
	(type='AR' or type='JA') AND 
	ss1length > 3 AND 
	ss1length > ? AND 
	ss1length < ? AND 
	ss2length > 3 AND 
	ss2length > ? AND 
	ss2length < ? AND 
	pdbid != ?
        };

    my $sth = $ldbh->prepare($query);
    $sth->bind_param( 1, $loop_length_minus_lenlimit );
    $sth->bind_param( 2, $loop_length_plus_lenlimit );
    $sth->bind_param( 3, $ss1_lenght_minus_ll );
    $sth->bind_param( 4, $ss1_lenght_plus_ll );
    $sth->bind_param( 5, $ss2_lenght_minus_ll );
    $sth->bind_param( 6, $ss2_lenght_plus_ll );
    $sth->bind_param( 7, $pdb_code );
    $sth->execute();

    my $aref = $sth->fetchall_arrayref([]);
    $sth->finish();
    $ldbh->disconnect();
    return $aref;
}

=head2 get_matching_smotifs 
    
    subroutine to get matching smotifs of a given type from
    the database.
    input:
    
    loop_length    = loop length
    lenlimit       = cut-off criteria for loop length
    ss_length_limit= cut-off criteria for secondary structure length
    ss1_length     = secondary structure1 length 
    ss2_length     = secondary structure2 length
    pdb_code       = 4-letter pdb code
    type           = type of smotif [HH, HE, EH, EE] 

    return an array reference containing:
    nid, delta, theta, rho, pdbid, chain, start, ss1length, length, seq, theta,ss2length,acc 
=cut

sub get_matching_smotifs {
    my ( $loop_length, $lenlimit, $ss_length_limit, $ss1_length, $ss2_length, $pdb_code,
        $type )
      = @_;
    die "Not connected to MySQL db" unless $ldbh;
    die                             unless $loop_length;
    die                             unless $lenlimit;
    die                             unless $ss_length_limit;
    die                             unless $ss1_length;
    die                             unless $ss2_length;
    die                             unless $pdb_code;
    die                             unless $type;
   
    $type = uc $type;
    croak "unknown smotif type"  
        unless (
            $type eq 'HH' ||
            $type eq 'HE' ||
            $type eq 'EH' ||
            $type eq 'EE' 
        );

    my $loop_length_minus_lenlimit = $loop_length - $lenlimit;
    my $loop_length_plus_lenlimit  = $loop_length + $lenlimit;
    my $ss1_lenght_minus_ll        = $ss1_length - $ss_length_limit;
    my $ss1_lenght_plus_ll         = $ss1_length + $ss_length_limit;
    my $ss2_lenght_minus_ll        = $ss2_length - $ss_length_limit;
    my $ss2_lenght_plus_ll         = $ss2_length + $ss_length_limit;

    my $ldbh  = connect_to_mysql();
    my $query = qq{ 
	SELECT loop_descriptors.nid, delta, theta, rho, pdbid, chain, start, ss1length, length, seq, theta,ss2length,acc 
	FROM loop_descriptors 
	INNER join loops2geom ON loop_descriptors.nid=loops2geom.nid 
	WHERE 
        length > ? AND length < ? AND 
	type = ? AND 
	ss1length > 3 AND 
	ss1length > ? AND 
	ss1length < ? AND 
	ss2length > 3 AND 
	ss2length > ? AND 
	ss2length < ? AND 
	pdbid != ?
        };

    my $sth = $ldbh->prepare($query);
    $sth->bind_param( 1, $loop_length_minus_lenlimit );
    $sth->bind_param( 2, $loop_length_plus_lenlimit );
    $sth->bind_param( 3, $type );
    $sth->bind_param( 4, $ss1_lenght_minus_ll );
    $sth->bind_param( 5, $ss1_lenght_plus_ll );
    $sth->bind_param( 6, $ss2_lenght_minus_ll );
    $sth->bind_param( 7, $ss2_lenght_plus_ll );
    $sth->bind_param( 8, $pdb_code );
    $sth->execute();

    my $aref = $sth->fetchall_arrayref([]);
    $sth->finish();
    $ldbh->disconnect();
    return $aref;
}

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MYSQLSmotifs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Fiserlab Members .

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MYSQLSmotifs
