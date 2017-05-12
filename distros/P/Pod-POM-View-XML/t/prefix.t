use strict;
use warnings;

use Test::More tests => 2;

use Pod::POM;
use Pod::POM::View::XML;

my $pom = Pod::POM->new->parse_text(<<'END_POD');
=head1 Hello there

Some random paragraph
END_POD

my $view = Pod::POM::View::XML->new(
    tag_prefix => 'other'
);

is $view->print($pom)."\n" => <<'END_XML', 'prefix changed';
<other_pod
><other_section head_level="1"
><other_title
>Hello there</other_title
><other_para
>Some random paragraph</other_para
></other_section
></other_pod
>
END_XML


$view = Pod::POM::View::XML->new(
    tag_prefix => undef
);

is $view->print($pom)."\n" => <<'END_XML', 'no prefix';
<pod
><section head_level="1"
><title
>Hello there</title
><para
>Some random paragraph</para
></section
></pod
>
END_XML
