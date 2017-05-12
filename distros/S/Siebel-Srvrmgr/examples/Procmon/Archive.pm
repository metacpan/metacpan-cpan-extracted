package Archive;

use Moose;
use Set::Tiny;
use DB_File;
use Digest::MD5 qw(md5_base64);

has 'dbm_path' =>
  ( is => 'ro', isa => 'Str', reader => 'get_dbm_path', required => 1 );

with 'Siebel::Srvrmgr::Log::Enterprise::Archive';

sub BUILD {

    my $self = shift;
    my %log_entries;
    tie %log_entries, 'DB_File', $self->get_dbm_path();

    $self->set_archive( \%log_entries );

    $self->_init_last_line();

}

sub reset {

    my $self = shift;
    %{ $self->get_archive() } = ();

}

sub has_digest {

    my $self = shift;
    return exists( $self->get_archive()->{DIGEST} );

}

sub get_digest {

    shift->get_archive()->{DIGEST};

}

sub _set_digest {

    my ( $self, $value ) = @_;
    $self->get_archive()->{DIGEST} = $value;

}

sub add {

    my ( $self, $pid, $comp_alias ) = @_;
    $self->get_archive()->{$pid} = $comp_alias;

}

sub remove {

    my ( $self, $pid ) = @_;
    my $archive = $self->get_archive();
    delete( $archive->{$pid} );

}

sub get_alias {

    my ( $self, $pid ) = @_;
    my $archive = $self->get_archive();

    if ( exists( $archive->{$pid} ) ) {

        return $archive->{$pid};

    }
    else {

        return undef;

    }

}

sub get_set {

    my $self = shift;

    my $archive = $self->get_archive();

    return Set::Tiny->new( keys( %{$archive} ) );

}

sub validate_archive {

    my $self        = shift;
    my $header      = shift;
    my $curr_digest = md5_base64($header);

    if ( $self->has_digest() ) {

        unless ( $self->get_digest() eq $curr_digest ) {

            # different log file
            $self->reset();
            $self->_set_digest($curr_digest);

        }

    }
    else {

        $self->_set_digest($curr_digest);

    }

}

__PACKAGE__->meta->make_immutable;
