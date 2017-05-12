package t::SporkHilite;
use Test::Base 0.43 -Base;

use Spork::Hilite;

filters {
    code => [qw(-trim prep hilite)],
    html => 'expand',
};

package t::SporkHilite::Filter;
use Test::Base::Filter -base;

my $code = '';

sub prep {
    $code .= shift;
}

sub hilite {
    my $wafl = Spork::Hilite::Wafl->new;
    $wafl->text(shift);
    $wafl->to_html;
}

sub expand {
    $_ = shift;
    s/RRR/<span class="hilite_red">/g;
    s/GGG/<span class="hilite_green">/g;
    s/BBB/<span class="hilite_blue">/g;
    s/YYY/<span class="hilite_yellow">/g;
    s/CCC/<span class="hilite_cyan">/g;
    s/MMM/<span class="hilite_magenta">/g;
    s/WWW/<span class="hilite_white">/g;
    s!///!</span>!g;
    return "<pre>\n$_</pre>\n";
}
