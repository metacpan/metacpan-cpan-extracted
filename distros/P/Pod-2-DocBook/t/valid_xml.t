use strict;
use warnings;

use Test::More;

BEGIN {
    eval "require XML::LibXML" or plan skip_all => 'test requires XML::LibXML';
    plan tests => 2;
    use_ok 'Pod::2::DocBook';
}

my $parser = Pod::2::DocBook->new(
    title             => 'My Article',
    doctype           => 'article',
    fix_double_quotes => 1,
    spaces            => 3,
    header            => 1
);

my $doc;
open my $output_fh, '>', \$doc or die;

$parser->parse_from_filehandle( *DATA, $output_fh );

my $dom = eval { XML::LibXML->new->parse_string($doc) };

ok !$@, "XML::LibXML doesn't complain";
diag $@ if $@;

__DATA__

=head1 My Title

=over

=item Eeney

=item Meeney

=item Moe

=back

