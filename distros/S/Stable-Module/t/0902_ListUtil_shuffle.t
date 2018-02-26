use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..3\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my @list = ();

eval {
    @list = shuffle('A'..'Z');
};

ok((scalar(@list) == 26), qq{scalare(\@list) == 26, $^X @{[__FILE__]}});
ok((join(',',@list) ne join(',','A'..'Z')), qq{join(',',\@list) ne join(',','A'..'Z') $^X @{[__FILE__]}});
ok((join(',',sort @list) eq join(',','A'..'Z')), qq{join(',',sort \@list) eq join(',','A'..'Z') $^X @{[__FILE__]}});

__END__
