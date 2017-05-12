package t::Util;
use strict;
use warnings FATAL => "all";
use Exporter 'import';
our @EXPORT = qw(tempdir slurp spew catdir catfile);

use File::Spec::Functions qw(catdir catfile);
use File::Temp ();
sub tempdir { File::Temp::tempdir( CLEANUP => 1 ); }
sub slurp { open my $fh, "<:utf8", $_[0] or die; join "", <$fh>    }
sub spew  { open my $fh, ">:utf8", $_[0] or die; print {$fh} $_[1] }

1;
