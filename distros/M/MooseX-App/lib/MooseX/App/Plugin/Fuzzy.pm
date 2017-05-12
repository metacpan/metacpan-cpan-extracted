# ============================================================================
package MooseX::App::Plugin::Fuzzy;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    warn "MooseX::App Fuzzy plugin is deprecated. Use Typo instead";
    return;
}

1;

