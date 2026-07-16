package TestS3Client;

use strictures 2;

use Class::Tiny qw(
    objects uploads deletes ranges fail_upload fail_delete short_range on_delete
);

sub BUILD {
    my ($self) = @_;
    $self->{objects} ||= {};
    $self->{uploads} ||= [];
    $self->{deletes} ||= [];
    $self->{ranges} ||= [];
    return;
}

sub upload_file {
    my ($self, %args) = @_;
    die "injected upload failure\n" if $self->fail_upload;

    open my $fh, '<:raw', $args{path} or die "cannot read $args{path}: $!";
    local $/;
    my $body = <$fh>;
    close $fh or die "cannot close $args{path}: $!";

    $self->objects->{$args{key}} = {
        body         => $body,
        content_type => $args{content_type},
        sha256       => $args{sha256},
    };
    push @{$self->uploads}, {%args};
    return 1;
}

sub head {
    my ($self, $key) = @_;
    my $object = $self->objects->{$key};
    return unless defined $object;
    return {size => length $object->{body}};
}

sub get_range {
    my ($self, $key, $start, $end) = @_;
    push @{$self->ranges}, [$key, $start, $end];
    my $object = $self->objects->{$key};
    return unless defined $object;

    my $body = substr($object->{body}, $start, $end - $start + 1);
    chop $body if $self->short_range && length $body;
    return $body;
}

sub delete {
    my ($self, $key) = @_;
    push @{$self->deletes}, $key;
    $self->on_delete->($key) if ref($self->on_delete) eq 'CODE';
    die "injected delete failure\n" if $self->fail_delete;
    return exists $self->objects->{$key}
        ? !!delete $self->objects->{$key}
        : 0;
}

1;
