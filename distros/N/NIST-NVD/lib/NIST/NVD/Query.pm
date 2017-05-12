package NIST::NVD::Query;

use warnings;
use strict;
use Carp;

=head1 NAME

NIST::NVD::Query - Query the NVD database

=head1 VERSION

Version 1.00.00

=cut

our $VERSION = '1.00.00';

=head1 SYNOPSIS

Query vulnerability data in the NVD database

    use NIST::NVD::Query;

    # use convert_nvdcve to generate db files from the XML dumps at
    # http://nvd.nist.gov/download.cfm

    my( $path_to_db, $path_to_idx_cpe ) = @ARGV;

    my $q = NIST::NVD::Query->new( store => $some_store,
                                   %args
                                  );

    # Given a Common Platform Enumeration urn, returns a list of known
    # CVE IDs

    my $cve_id_list = $q->cve_for_cpe( cpe => 'cpe:/a:zaal:tgt:1.0.6' );

    my @entry;

    foreach my $cve_id ( @$cve_id_list ){

      # Given a CVE ID, returns a CVE entry

      my $entry = $q->cve( cve_id => $cve_id );
      push( @entry, $entry );

      print $entry->{'vuln:summary'};
    }

=head1 SUBROUTINES/METHODS

=head2 new

=head3 Required arguments:

    database: path to BDB database of NVD entries
    idx_cpe:  path to BDB database of mappings from CPE URNs to CVE IDs

=head3 Example

    my $q = NIST::NVD::Query->new( database => $path_to_db,
                                   idx_cpe  => $path_to_idx_cpe,
                                  );

=head3 Return Value

    $q is an object reference of type NIST::NVD::Query

=cut

sub new {
    my ( $class, %args ) = @_;
    $class = ref $class || $class;

    my $store = $args{store} || "DB_File";

    my $db_class = "NIST::NVD::Store::$store";
    eval "use $db_class";

    croak "unable to use $db_class: $@" if $@;

    my $db = $db_class->new(
        $db_class->_get_default_args(),
        store    => $args{store},
        database => $args{database},
    );
    return unless $db;

    bless { store => $db }, $class;
}

=head2 cve_for_cpe

Returns a list of CVE IDs for a given CPE URN.

=head3 Required argument

    cpe: CPE URN  Example:

    'cpe:/a:zaal:tgt:1.0.6'

=head3 Return Value

Returns a reference to an array of CVE IDs.  Example:

    $cve_id_list = [
      'CVE-1999-1587',
      'CVE-1999-1588',
    ]

=head3 Example

    my $cve_id_list = $q->cve_for_cpe( cpe => 'cpe:/a:zaal:tgt:1.0.6' );

=cut

sub cve_for_cpe {
    my ( $self, %args ) = @_;

    unless ( exists $args{cpe} ) {
        confess qq{"cpe" is a required argument to __PACKAGE__::cve_for_cpe\n};
    }

    my $return = $self->{store}->get_cve_for_cpe(%args);

    return $return;
}

=head2 get_websec_by_cpe

=head3 Required argument

    cpe: CPE URN  Example:

    'cpe:/a:zaal:tgt:1.0.6'

=head3 Return Value

Returns a reference to a websec score object
    $result =
         {  websec_results => [
                {   category => 'Other',
                    score    => int(rand 10),
                    key      => 'A0',
                },
                {   category => 'Injection',
                    score    => 9.34,
                    key      => 'A1',
                },
                {   category => 'Cross-Site Scripting (XSS)',
                    score    => 8.11,
                    key      => 'A2',
                },
                {   category =>
                        'Broken Authentication and Session Management',
                    score    => 7,
                    key      => 'A3',
                },
                {   category => 'Insecure Direct Object References',
                    score    => 6,
                    key      => 'A4',
                },
                {   category => 'Cross-Site Request Forgery (CSRF)',
                    score    => 5,
                    key      => 'A5',
                },
                {   category => 'Security Misconfiguration',
                    score    => 4,
                    key      => 'A6',
                },
                {   category => 'Insecure Cryptographic Storage',
                    score    => 3,
                    key      => 'A7',
                },
                {   category => 'Failure to Restrict URL Access',
                    score    => 2,
                    key      => 'A8',
                },
                {   category => 'Insufficient Transport Layer Protection',
                    score    => 1,
                    key      => 'A9',
                },
                {   category => 'Unvalidated Redirects and Forwards',
                    score    => 0,
                    key      => 'A10',
                },
            ]
        }

=head3 Example

  my $result = $store->get_websec_by_cpe( 'cpe:/a:apache:tomcat:6.0.28' );
  while( my $websec = shift( @{$result->{websec_results}} ) ){
    print( "$websec->{key} - $websec->{category}: ".
           "$websec->{score}\n" );
  }

=cut

sub get_websec_by_cpe {
    my ($self) = @_;

    my %result = $self->{store}->get_websec_by_cpe(@_);

    return %result if wantarray;
    return \%result;
}

=head2 get_cwe_ids

  $result = $self->get_cwe_ids();
  while( my( $cwe_id, $cwe_pkey_id ) = each %$result ){
    ...
  }

=cut

sub get_cwe_ids {
    my ($self) = @_;

    my $result = $self->{store}->get_cwe_ids(@_);

    return $result;
}

=head2 cwe_for_cpe

Returns a list of CWE IDs for a given CPE URN.

=head3 Required argument

    cpe: CPE URN  Example:

    'cpe:/a:zaal:tgt:1.0.6'

=head3 Return Value

Returns a reference to an array of CWE IDs.  Example:

    $cwe_id_list = [
      'CWE-1999-1587',
      'CWE-1999-1588',
    ]

=head3 Example

    my $cwe_id_list = $q->cwe_for_cpe( cpe => 'cpe:/a:zaal:tgt:1.0.6' );

=cut

sub cwe_for_cpe {
    my ( $self, %args ) = @_;

    unless ( exists $args{cpe} ) {
        carp qq{"cpe" is a required argument to __PACKAGE__::cwe_for_cpe\n};
    }

    my $return = $self->{store}->get_cwe_for_cpe(%args);

    return $return;
}

=head2 cve

Returns a CVE for a given CPE URN.

=head3 Example

    my $nvd_cve_entry = $q->cve( cve_id => 'CVE-1999-1587' );

=head3 Required argument

    cve_id: CPE URN  Example:

    'CVE-1999-1587'

=head3 Return Value

Returns a reference to a hash representing a CVE entry:

 my $nvd_cve_entry = {
     'vuln:vulnerable-configuration' => [ ... ],
     'vuln:vulnerable-software-list' => [ ... ],
     'vuln:cve-id'                   => 'CVE-1999-1587',
     'vuln:discovered-datetime'      => '...',
     'vuln:published-datetime'       => '...',
     'vuln:last-modified-datetime'   => '...',
     'vuln:cvss'                     => {...},
     'vuln:cwe'                      => 'CWE-ID',
     'vuln:references'               => [
         {
             attr => {...},
             'vuln:references' => [ {...}, ... ],
             'vuln:source'     => ...,
         },
         ...
     ],
     'vuln:summary'                  => ...,
     'vuln:security-protection'      => ...,
     'vuln:assessment_check'         => {
         'check0 name' => 'check0 value',
         ...,
     },
     'vuln:scanner',                 => [ {
				 'vuln:definition' => {
             'vuln attr0 name' => 'vuln attr0 value',
             ...,
         }
     }, ..., ],
 };

=cut

sub cve {
    my ( $self, %args ) = @_;

    return $self->{store}->get_cve( (%args) );
}

=head2 cwe

Returns a CWE for a given CPE URN.

=cut

sub cwe {
    my ( $self, %args ) = @_;

    return $self->{store}->get_cwe( (%args) );
}

=head1 AUTHOR

C.J. Adams-Collier, C<< <cjac at f5.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2012 F5 Networks, Inc.

CVE(r) and CWE(tm) are marks of The MITRE Corporation and used here with
permission.  The information in CVE and CWE are copyright of The MITRE
Corporation and also used here with permission.

Please include links for CVE(r) <http://cve.mitre.org/> and CWE(tm)
<http://cwe.mitre.org/> in all reproductions of these materials.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of NIST::NVD::Query
