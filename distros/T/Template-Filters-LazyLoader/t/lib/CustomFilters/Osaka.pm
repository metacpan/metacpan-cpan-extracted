package CustomFilters::Osaka;
use strict;

sub fs_osaka {
    my $s      = shift;
    my $string = shift;

    return 'osaka' ;
}

sub fs_sukiyanen_osaka {
    return "sukiyanen_osaka";
}

sub fd_dynamic_osaka {
    return sub {
        'dynamic_osaka';
    }
}

sub donot_use_osaka {
    return 'donot_use_osaka';
}
1;
