package CustomFilters::USA::Okurahoma;

use strict;

sub fs_okurahoma {
    return 'okurahoma';
}

sub fd_tulsa {
    my ($context, @args) = @_;
    sub {
        my $text = shift;
        return $args[0] . $args[1] . $text;
    }
}








1;
