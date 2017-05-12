$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 3;
use Stable::Module;

my @list = ();

eval {
    @list = shuffle('A'..'Z');
};

ok((scalar(@list) == 26), qq{scalare(\@list) == 26, $^X @{[__FILE__]}});
ok((join(',',@list) ne join(',','A'..'Z')), qq{join(',',\@list) ne join(',','A'..'Z') $^X @{[__FILE__]}});
ok((join(',',sort @list) eq join(',','A'..'Z')), qq{join(',',sort \@list) eq join(',','A'..'Z') $^X @{[__FILE__]}});

__END__
