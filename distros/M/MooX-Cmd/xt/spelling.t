#!perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval { require Test::Spelling }
      or plan skip_all => "Test::Spelling required for this test";
}

use Test::Spelling;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
ArrayRef
BOOL
BUILDARGS
CLI
CPAN
Celogeek
HashRef
Inkster
Jens
Lukas
Rehsack
Raudssus
Ricardo
Signes
Subcommand
Toplevel
argv
cli
cmd
eXtension
mauke
rehsack
subcommand
subcommands
tobyink
toplevel
