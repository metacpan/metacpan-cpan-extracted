package HTML::Escape::PurePerl;
use strict;
use warnings;
use utf8;

die qq{Don't use HTML::Escape::PurePerl directly, use HTML::Escape instead.\n} # ' for poor editors
        if caller() ne 'HTML::Escape';

package # do not index, pause.
    HTML::Escape;

our %_escape_table = ( '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', q{"} => '&quot;', q{'} => '&#39;', q{`} => '&#96;', '{' => '&#123;', '}' => '&#125;' );
sub escape_html {
    my $str = shift;
    return ''
        unless defined $str;
    $str =~ s/([&><"'`{}])/$_escape_table{$1}/ge; #' for poor editors
    return $str;
}

1;

