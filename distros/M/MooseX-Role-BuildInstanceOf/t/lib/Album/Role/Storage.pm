package Album::Role::Storage; {

    use Moose::Role;
    use Perl6::Junction qw(any);

    requires 'asset_info_from_path', 'items_in_source';

    has source => (
        is => 'ro',
        required => 1,
    );

    has allowed_types => (
        is => 'ro',
        isa => 'ArrayRef[Str]',
        required => 1,
        auto_deref => 1,
    );

    sub available_assets {
        my ($self) = @_;
        my @assets;
        foreach my $path ($self->items_in_source) {
            if(my $info = $self->asset_info_from_path($path)) {
                if($self->is_type_allowed($info->{mime_type})) {
                    push @assets, $info;
                }
            }
        }
        return @assets;
    }

    sub  is_type_allowed {
        my ($self, $type) = @_;
        return any($self->allowed_types) eq $type ? 1:0;
    }
}

1;
