use Perlmazing qw(croak);
use File::Spec;

sub main {
    my $path = shift;
    croak "$path doesn't exist or can't be read" unless -e $path;
    croak "$path is not a valid directory" unless -d $path;
    my $item_count = _clean_level($path);
    $item_count += CORE::rmdir($path) or die "Can't remove $path: $!";
    return $item_count;
}

sub _clean_level {
    my $path = shift;
    my $item_count = 0;
    opendir my $dir, $path or die "Can't open directory $path for reading: $!";
    while (my $item = readdir $dir) {
        next if $item =~ /^\.{1,2}$/;
        my $full_item = File::Spec->catdir($path, $item);
        next if $full_item eq $path;
        if (-d $full_item and not readlink $full_item) {
            _clean_level($full_item);
            $item_count += CORE::rmdir($full_item);
        } else {
            unlink $full_item or die "Cannot remove $full_item: $!";
            $item_count++;
        }
    }
    closedir $dir;
    return $item_count;
}

1;
