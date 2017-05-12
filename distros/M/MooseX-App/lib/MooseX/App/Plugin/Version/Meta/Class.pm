# ============================================================================
package MooseX::App::Plugin::Version::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Plugin::Version::Command;

around '_build_app_commands' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig(@_);
    $return->{version} ||= 'MooseX::App::Plugin::Version::Command';

    return $return;
};

1;