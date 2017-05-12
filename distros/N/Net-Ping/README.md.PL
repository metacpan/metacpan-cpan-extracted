use strict;
use warnings;
use CPAN::Meta;
use Text::Template;

my $meta = CPAN::Meta->load_file('META.json');
my $template = Text::Template->new( TYPE => 'ARRAY', SOURCE => [<DATA>] );
open my $readme, '>', shift or die $!;
$template->fill_in( HASH => $meta->as_struct, OUTPUT => $readme )
    or die $Text::Template::ERROR;
close $readme;

__DATA__
# {$name}

{$name} - {$abstract}

## DOWNLOAD AND INSTALLATION

Download a release from CPAN using your favorite tool, such as cpanm, or else
from https://metacpan.org/release/{$name} and then unpack the tar.gz file.

You're most welcome to contribute, in which case cloning or forking the git
repo at { $resources{repository}{web} } is a good place to start.

To build and install, just incant the typical mantra:

    perl Makefile.PL
    make
    make test
    make install
