package TestSplit;
use v5.36;

use Exporter 'import';
our @EXPORT_OK = qw/fill_splits with_first_lines/;

use Review::Helper::Sheet;
use Review::Helper::Split;

# Fill the split items of the latest iteration, as the agent would. $pick
# gets each split item's 'about' and returns its sections, or undef to skip
# it. Sections may leave out first_line and old_first_line: they are taken
# from the file. Returns fill's result.
sub fill_splits($repo, $db, $pick, %params) {
    my $sheet = Review::Helper::Sheet->new(repo => $repo, db => $db);
    my $data  = $sheet->sheet(all => $params{all});

    my @items;
    for my $item (grep { $_->{type} eq 'split' } @{$data->{items}}) {
        my $sections = $pick->($item->{about}) // next;
        $item->{fields}->{sections} = with_first_lines($repo, $db, $item->{about}, $sections);
        push @items => $item;
    }

    return $sheet->fill({%$data, items => \@items});
}

# Copies of the sections with their first lines filled in from the file.
sub with_first_lines($repo, $db, $about, $sections) {
    my $commit = $about->{commit};
    my ($parent) = $db->dbh->selectrow_array('SELECT parent FROM commit_entry WHERE revision = ? ORDER BY iteration DESC LIMIT 1', undef, $commit);

    my %lines;
    my $line = sub ($side, $n) {
        $lines{$side} //= do {
            my $rev  = $side eq 'new' ? $commit        : $parent;
            my $path = $side eq 'new' ? $about->{path} : $about->{old_path} // $about->{path};
            Review::Helper::Split->lines(defined($rev) ? $repo->file($rev, $path) // '' : '');
        };
        return $lines{$side}->[$n - 1];
    };

    my @out;
    for my $s (@$sections) {
        my %copy = %$s;
        $copy{first_line}     //= $line->(new => (sort { $a <=> $b } map { $_->[0] } @{$s->{lines}})[0])     if @{$s->{lines}     // []};
        $copy{old_first_line} //= $line->(old => (sort { $a <=> $b } map { $_->[0] } @{$s->{old_lines}})[0]) if @{$s->{old_lines} // []};
        push @out => \%copy;
    }
    return \@out;
}

1;
