package Album::Storage; {
    use Moose;
    with 'Album::Role::Storage';

    sub asset_info_from_path { die "abstract method" };
    sub items_in_source { die "abstract method" };
}

1;
