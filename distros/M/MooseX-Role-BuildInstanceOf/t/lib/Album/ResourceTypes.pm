package Album::ResourceTypes; {

    use Moose;
    use Class::MOP;
    use List::MoreUtils qw(uniq);
    use Moose::Util::TypeConstraints;

    subtype 'Album.ResourceTypes.ClassName',
    as 'ClassName';

    subtype 'Album.ResourceTypes.ArrayRefOfClassName',
    as 'ArrayRef[Album.ResourceTypes.ClassName]';


    coerce 'Album.ResourceTypes.ArrayRefOfClassName',
    from 'ArrayRef[Str]',
    via {
        Class::MOP::load_class($_) for @$_; $_
    };

    has resources => (
        is => 'ro',
        isa => 'Album.ResourceTypes.ArrayRefOfClassName',
        required => 1,
        auto_deref => 1,
        coerce => 1,
    );

    has allowed_types => (
        is => 'ro',
        init_arg => undef,
        isa => 'ArrayRef[Str]',
        lazy_build => 1,
        auto_deref => 1,
    );

    has resource_dispatch_table => (
        is => 'ro',
        init_arg => undef,
        isa => 'HashRef[ClassName]',
        lazy_build => 1,
    );

    sub _build_allowed_types {
        my $self = shift @_;
        return [uniq map {
            $_->supported_mime_types;
        } $self->resources];
    }

    sub _build_resource_dispatch_table {
        my $self = shift @_;
        my %dispatch_table;
        foreach my $resource (@{$self->resources}) {
            foreach my $type ($resource->supported_mime_types) {
                if($dispatch_table{$type}) {
                    warn "$type already has a handler";
                } else {
                    $dispatch_table{$type} = $resource;
                }
            }
        }
        return \%dispatch_table
    }

    sub process {
        my ($self, $asset) = @_;
        my $type = $asset->{mime_type};
        if(my $resource = $self->resource_dispatch_table->{$type}) {
            if(my $inflated = $resource->process($asset)) {
                return $inflated;
            } else {
                die "Couldn't inflate $asset->{title}";
            }
        } else {
            die "$asset->{title} has no resource";
        }
    }
}

1;
