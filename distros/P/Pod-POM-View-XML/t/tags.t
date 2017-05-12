use strict;
use warnings;

use Test::More tests => 1;

use Pod::POM;
use Pod::POM::View::XML;

my $view = Pod::POM::View::XML->new(
    tags => {
        pod => 'alpha',
        head1 => 'beta',
        head1_title => 'gamma',
        textblock => 'delta'
    },
);

my $pom = Pod::POM->new->parse_text(<<'END_POD');
=head1 Hello there

Some random paragraph
END_POD

is $view->print($pom)."\n" => <<'END_XML', 'tags changed';
<pod_alpha
><pod_beta head_level="1"
><pod_gamma
>Hello there</pod_gamma
><pod_delta
>Some random paragraph</pod_delta
></pod_beta
></pod_alpha
>
END_XML


