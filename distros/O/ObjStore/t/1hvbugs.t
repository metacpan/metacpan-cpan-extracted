#-*-perl-*-
use Test;
BEGIN { plan tests=>5, todo => [1,2]; }

use ObjStore;
use lib './t';
use test;

&open_db;    
begin 'update', sub {
    my $john = $db->root('John');
    die 'no john' if !$john;
    
    my $xr = $john->{nest}{rat} = {};  #autovivify doesn't work for tied hashes
    ok(tied %$xr);
    
    $xr->{blat} = 69;
    ok( ($john->{nest}{rat}{blat} or 0) == 69);
    
    delete $john->{nest}{rat}{blat};
    delete $john->{nest}{rat};
    delete $john->{nest};
    
    ok(! defined $john->{nest});
};
die if $@;

sub zero {
    my $h = shift;
    $h->{''} = 'zero';
    ok($h->{''} eq 'zero');
}

begin 'update', sub {
    my $john = $db->root('John');
    zero($john);
#    zero($john->{dict});  BROKEN XXX
};
die if $@;
