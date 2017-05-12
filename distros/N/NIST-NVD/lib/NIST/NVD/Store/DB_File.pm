package NIST::NVD::Store::DB_File;

use NIST::NVD::Store::Base;
use base qw{NIST::NVD::Store::Base};

use warnings;
use strict;

our $VERSION = '1.00.00';

use Carp;

use Storable qw(nfreeze thaw);
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use IO::Compress::Bzip2 qw(bzip2 $Bzip2Error);

use DB_File;

=head2 new

    my $NVD_Storage_ORACLE = NIST::NVD::Store::DB_File->new(
        store     => 'DB_File',
        database  => '/path/to/nvd.db',
        cwe       => '/path/to/cwe.db',
        'idx_cpe' => '/path/to/idx_cpe.db'
        'idx_cwe' => '/path/to/idx_cwe.db'
        mode      => $mode, # perldoc DB_File
    );

=cut

sub new {
    my ( $class, %args ) = @_;
    $class = ref $class || $class;

    my $args = {
        filename => [qw{ database idx_cpe idx_cwe cwe }],
        database => [qw{ database idx_cpe idx_cwe cwe }],
        required => [qw{ database }],
    };

		unless( exists $args{idx_cpe} ){
			($args{idx_cpe} = $args{database}) =~ s/(\.db)$/.idx_cpe$1/;
		}

		unless( exists $args{idx_cwe} ){
			($args{idx_cwe} = $args{database}) =~ s/(\.db)$/.idx_cwe$1/;
		}

		unless( exists $args{cwe} ){
			($args{cwe} = $args{database}) =~ s:/(nvd\.db)$:cwec_v2.2.db:;
		}

    $args{mode} //= O_RDONLY;

    my $fail = 0;
    foreach my $req_arg ( @{ $args->{required} } ) {
        unless ( $args{$req_arg} ) {
            carp "'$req_arg' is a required argument to __PACKAGE__::new\n";
            $fail++;
        }
    }
    return if $fail;

    my $self = { vuln_software => {} };
    foreach my $arg ( keys %args ) {
        if ( grep { $_ eq $arg } @{ $args->{filename} } ) {

            unless ( ( $args{mode} & O_CREAT ) == O_CREAT || -f $args{$arg} ) {
                carp "$arg file '$args{$arg}' does not exist\n";
                $fail++;
            }
        }
        if ( grep { $_ eq $arg } @{ $args->{database} } ) {
            my %tied_hash;
            $self->{$arg} = \%tied_hash;
            $self->{"$arg.db"} = tie %tied_hash, 'DB_File', $args{$arg},
              $args{mode};

            unless ( $self->{"$arg.db"} ) {
                carp "failed to open database '$args{$arg}': $!";
                $fail++;
            }
        }
    }
    return if $fail;

    bless $self, $class;

}

=head2 get_cve_for_cpe

=cut

sub get_cve_for_cpe {
    my ( $self, %args ) = @_;

    my $frozen;

    my $result = $self->{'idx_cpe.db'}->get( $args{cpe}, $frozen );

    my $cve_ids = [];

    unless ( $result == 0 ) {
        return $cve_ids;
    }

    $cve_ids = eval { thaw $frozen };
    if (@$) {
        carp "Storable::thaw had a major malfunction: $@";
        return;
    }

    return $cve_ids;
}

=head2 get_cve


=cut

sub get_cve {
    my ( $self, %args ) = @_;

    my $compressed;

    my $result = $self->{'database.db'}->get( $args{cve_id}, $compressed );

    unless ( $result == 0 ) {
        carp "failed to retrieve CVE '$args{cve_id}': $!\n";
        return;
    }

    my $frozen;

    my $status = bunzip2( \$compressed, \$frozen );
    unless ($status) {
        carp "bunzip2 failed: $Bunzip2Error\n";
        return;
    }

    my $entry = eval { thaw $frozen };
    if (@$) {
        carp "Storable::thaw had a major malfunction.";
        return;
    }

    return $entry;
}

=head2 put_cve_idx_cpe

  $NVD_Storage_ORACLE->put_cve_idx_cpe( $cpe_urn, $value )

=cut

sub put_cve_idx_cpe {
    my ( $self, $vuln_software ) = @_;

    foreach my $cpe_urn ( keys %$vuln_software ) {
        my $frozen;

        $self->{'idx_cpe.db'}->get( $cpe_urn, $frozen );

        if ($frozen) {
            my $thawed = thaw($frozen);
            next unless ref $thawed eq 'ARRAY';

            my @vuln_list = ();

            @vuln_list = @{ $self->{vuln_software}->{$cpe_urn} }
              if ref $self->{vuln_software}->{$cpe_urn} eq 'ARRAY';

            # Combine previous results with these results
            $vuln_software->{$cpe_urn} = [ @vuln_list, @{$thawed} ];
        }

        $frozen = nfreeze( $vuln_software->{$cpe_urn} );

        $self->{'idx_cpe.db'}->put( $cpe_urn, $frozen );
    }
}

=head2 put_nvd_entries

  $NVD_Storage_ORACLE->put_nvd_entries( $entries )

=cut

sub put_nvd_entries {
    my ( $self, $entries ) = @_;

    while ( my ( $cve_id, $entry ) = ( each %$entries ) ) {

        my $frozen = nfreeze($entry);

        my $compressed;

        bzip2 \$frozen => \$compressed
          or die "bzip2 failed: $Bzip2Error\n";

        $self->{'database.db'}->put( $cve_id, $compressed );
    }
}

sub _get_default_args {
    return ( mode => O_CREAT | O_RDWR );

}

1;
