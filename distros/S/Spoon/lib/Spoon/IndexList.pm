package Spoon::IndexList;
use Spiffy -selfless;
use IO::All;
use DB_File;

sub index_list {
    my $list = io(shift);
    my $index = io($list . '.db')->dbm('DB_File')->rdonly;
    unless ($index->exists) {
        $index->assert->open;
        $index->close;
    }
    unless ($list->exists) {
        my $mtime = $index->mtime;
        $list->print('');
        for (sort keys %$index) {
            $list->print("$_\n");
        }
        $index->close;
        $list->close;
        $list->utime($mtime - 1);
    }
    if ($list->mtime > $index->mtime) {
        my %copy = %$index;
        $index->close;
        $index->rdonly(0)->rdwr(1)->open;
        for my $key ($list->chomp->slurp) {
            $key =~ s/^\s*(.*?)\s*$/$1/;
            next unless $key;
            $index->{$key} = 1;
            delete $copy{$key};
        }
        for my $key (keys %copy) {
            delete $index->{$key};
        }
        $index->rdonly(1)->rdwr(0)->close;
    }
    return $index;
}
