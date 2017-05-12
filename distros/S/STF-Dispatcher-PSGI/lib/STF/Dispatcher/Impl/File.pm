package STF::Dispatcher::Impl::File;
use strict;
use HTTP::Date ();
use File::Copy ();
use File::Temp ();
use File::Spec;
use File::Path ();
use Plack::MIME;
use Class::Accessor::Lite
    ro => [ qw(buckets storage_path) ]
;

sub new {
    my ($class, %args) = @_;

    $args{storage_path} ||= File::Temp::tempdir( CLEANUP => 1 );

    bless{ buckets => {}, %args }, $class;
}

sub start_request {}
sub create_bucket {
    my ($self, $args) = @_;
    my $dir = File::Spec->catdir( $self->storage_path, $args->{bucket_name} );
    if ( ! -d $dir ) {
        if (! File::Path::make_path( $dir, { mode => 0755 } ) ) {
            Carp::croak( "Failed to create $dir: $!" );
        }
    }
    return 1;
}

sub get_bucket {
    my ($self, $args) = @_;
    my $dir = File::Spec->catdir( $self->storage_path, $args->{bucket_name} );
    return $dir if -d $dir;
}

sub delete_bucket {
    my ($self, $args) = @_;
    my $dir = $args->{bucket};
    return File::Path::remove_tree( $dir );
}

sub create_object {
    my ($self, $args) = @_;
    my $input = $args->{input};
    my $content = $args->{content};
    my $file = File::Spec->catfile( $args->{bucket}, $args->{object_name} );
    my $dir  = File::Basename::dirname( $file );
    if (! -d $dir ) {
        if (! File::Path::make_path( $dir, { mode => 0755 } ) ) {
            Carp::croak( "Failed to create directory $dir: $!" );
        }
    }

    open my $fh, '>', $file or
        Carp::croak( "Failed to open file $file for writing: $!" );
    print $fh $input ? do { local $/; <$input> } : $content;
    close ($fh);

    1;
}

sub is_valid_object {
    my ($self, $args) = @_;
    my $file = File::Spec->catfile( $args->{bucket}, $args->{object_name} );
    return -f $file;
}

sub get_object {
    my ($self, $args) = @_;
    my $file = File::Spec->catfile( $args->{bucket}, $args->{object_name} );
    return unless -f $file;

    my @stat = stat($file);
    if ( my $ims = $args->{request}->header('if-modified-since') ) {
        if ( $stat[9] > HTTP::Date::str2time( $ims ) ) {
            return STF::Dispatcher::PSGI::HTTPException->throw( 304, [], [] );
        }
    }

    open my $fh, '<', $file
        or Carp::croak("Failed to open file $file for reading: $!");

    return STF::Dispatcher::Impl::File::Object->new(
        modified_on => $stat[9],
        content_type => Plack::MIME->mime_type($file) || 'text/plain',
        content => do { local $/; <$fh> },
    );
}

sub modify_object {
    return 1;
}

sub delete_object {
    my ($self, $args) = @_;
    my $file = File::Spec->catfile( $args->{bucket}, $args->{object_name} );
    return unless -f $file;
    unlink $file;
}

sub rename_bucket {
    my ($self, $args) = @_;

    my $bucket = $args->{bucket};
    my $name   = $args->{name};
    my $source = File::Spec->catdir($bucket);
    my $destination = File::Spec->catdir($self->storage_path, $name);
    if (-e $destination) {
        return;
    }
    File::Copy::move( $source, $destination );
}

sub rename_object {
    my ($self, $args) = @_;

    my $source = File::Spec->catfile( $args->{source_bucket}, $args->{source_object_name} );
    my $dest   = File::Spec->catfile( $args->{destination_bucket}, $args->{destination_object_name } );
    my $dir  = File::Basename::dirname( $dest );
    if (! -d $dir ) {
        if (! File::Path::make_path( $dir, { mode => 0755 } ) ) {
            Carp::croak( "Failed to create directory $dir: $!" );
        }
    }

    if (! File::Copy::move( $source, $dest )) {
        Carp::croak("Failed to move from '$source' to '$dest': $!");
    }

    return 1;
}

package
    STF::Dispatcher::Impl::File::Object;
use strict;
use Class::Accessor::Lite
    new => 1,
    ro => [ qw(content_type content modified_on) ]
;

1;


__END__

=head1 NAME

STF::Dispatcher::Impl::File - STF Storage to store data in file

=head1 SYNOPSIS

    my $app = STF::Dispatcher::PSGI->new(
        impl => STF::Dispatcher::Impl::File->new(
            storage_path => '/tmp'
        )
    );

    builder {
        $app->to_app
    }

=cut
