use strict;
use warnings;
use Path::Class;

my $t = Path::Class::Dir->new('t');
for my $file ($t->children) {
    next if $file->is_dir;
    next if $file->basename =~ /^.+\-pp\.t$/;
    next if $file->basename =~ /^9.+\.t$/;
    next unless $file->basename =~ /^\d.+\.t$/;
    my $new_name = $file->basename;
    $new_name =~ s/\.t$/-pp.t/;

    my $data = $file->slurp;
    my $fh = $t->file($new_name)->openw;
    print $fh "BEGIN{ \$ENV{STRING_DIFF_PP} = 1; }\n$data";
    close $fh;
}
