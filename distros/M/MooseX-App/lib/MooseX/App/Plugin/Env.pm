# ============================================================================
package MooseX::App::Plugin::Env;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    warn "MooseX::App Env plugin is deprecated. Functionality moved to core";
    return;
}

1;