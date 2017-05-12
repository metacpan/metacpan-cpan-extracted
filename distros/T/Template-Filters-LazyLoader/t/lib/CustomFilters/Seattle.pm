package CustomFilters::Seattle;


use strict;

sub fs_seattle {
    return 'seattle';
};

sub fd_seattle_cool {
    sub {
        return 'seattle_cool';
    }
}



1;
