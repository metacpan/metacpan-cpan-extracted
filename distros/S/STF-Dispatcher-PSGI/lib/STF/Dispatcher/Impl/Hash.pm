package STF::Dispatcher::Impl::Hash;
use strict;
use HTTP::Date ();
use Class::Accessor::Lite
    ro => [ qw(buckets) ]
;

sub new {
    my ($class, %args) = @_;
    bless{ buckets => {}, %args }, $class;
}

sub start_request {}
sub create_bucket {
    my ($self, $args) = @_;
    my $name = $args->{bucket_name};
    $self->buckets->{$name} = {
        name => $name,
        objects => {},
    }
}

sub get_bucket {
    my ($self, $args) = @_;
    return $self->buckets->{$args->{bucket_name}};
}

sub delete_bucket {
    my ($self, $args) = @_;
    delete $self->buckets->{$args->{bucket}->{name}};
}

sub create_object {
    my ($self, $args) = @_;

    my $object_name = $args->{object_name};
    my $input       = $args->{input};
    my $content     = $args->{content};
    my $object = {
        modified_on => time(),
        content => $input ?
            do { local $/; <$input> } :
            $content,
    };
    $object->{content_type} = $args->{content_type} if $args->{content_type};
    $args->{bucket}->{ $object_name } = STF::Dispatcher::Impl::Hash::Object->new(
        %$object
    )
}

sub is_valid_object {
    my ($self, $args) = @_;
    return exists $args->{bucket}->{ $args->{object_name} };
}

sub get_object {
    my ($self, $args) = @_;
    my $object = $args->{bucket}->{ $args->{object_name} };
    return if (! $object );

    if ( my $ims = $args->{request}->header('if-modified-since') ) {
        if ( $object->modified_on > HTTP::Date::str2time( $ims ) ) {
            STF::Dispatcher::PSGI::HTTPException->throw( 304, [], [] );
        }
    }
    return $object;
}

sub modify_object {
    return 1;
}

sub delete_object {
    my ($self, $args) = @_;
    delete $args->{bucket}->{ $args->{object_name} };
}

sub rename_bucket {
    my ($self, $args) = @_;

    my $bucket = $args->{bucket};
    my $name   = $args->{name};

    if ( $self->buckets->{ $name }) {
        return;
    }
    $self->buckets->{ $name } = delete $self->buckets->{ $bucket->{name} };
}

sub rename_object {
    my ($self, $args) = @_;
    $args->{ destination_bucket }->{ $args->{ destination_object_name } } =
        delete $args->{source_bucket}->{ $args->{source_object_name} };
}

package
    STF::Dispatcher::Impl::Hash::Object;
use strict;
use Class::Accessor::Lite
    new => 1,
    ro => [ qw(content_type content modified_on) ]
;

1;

__END__

=head1 NAME

STF::Dispatcher::Impl::Hash - STF Storage to store data in hash

=head1 SYNOPSIS

    my $app = STF::Dispatcher::PSGI->new(
        impl => STF::Dispatcher::Impl::Hash->new()
    );

    builder {
        $app->to_app
    }

=cut

