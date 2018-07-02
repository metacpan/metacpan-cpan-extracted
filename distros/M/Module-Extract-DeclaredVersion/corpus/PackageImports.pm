use v5.10;
use URI;
use CGI qw(:standard);
use LWP::Simple 1.23 qw(getstore);
use File::Basename ('basename', 'dirname');
use File::Spec::Functions qw(catfile rel2abs);
use autodie ':open';
use strict q'refs';
use warnings q<redefine>;
use Buster "brush";
use Mimi qq{string};

my $cat = 'Buster';

1;
