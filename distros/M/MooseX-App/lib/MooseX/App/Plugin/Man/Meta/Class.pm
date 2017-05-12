# ============================================================================
package MooseX::App::Plugin::Man::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Plugin::Man::Command;

around '_build_app_commands' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig(@_);
    $return->{man} ||= 'MooseX::App::Plugin::Man::Command';

    return $return;
};

1;