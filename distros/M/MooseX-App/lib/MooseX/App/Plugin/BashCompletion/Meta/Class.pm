# ============================================================================
package MooseX::App::Plugin::BashCompletion::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Plugin::BashCompletion::Command;

around '_build_app_commands' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig(@_);
    $return->{bash_completion} ||= 'MooseX::App::Plugin::BashCompletion::Command';

    return $return;
};

1;