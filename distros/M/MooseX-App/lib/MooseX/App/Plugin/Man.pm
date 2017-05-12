# ============================================================================
package MooseX::App::Plugin::Man;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;

    return {
        class   => ['MooseX::App::Plugin::Man::Meta::Class'],
    }
}

around 'initialize_command_class' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig(@_);
    if (blessed $return
        && $return->isa('MooseX::App::Plugin::Man::Command')) {
        return $return->man($self);
    }

    return $return;
};
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Man - Adds a command to display the full manual

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Man);

In your shell

 bash$ myapp man somecommand

=head1 DESCRIPTION

This plugin adds a command to display the full manpage/perldoc of your
application.

=cut
