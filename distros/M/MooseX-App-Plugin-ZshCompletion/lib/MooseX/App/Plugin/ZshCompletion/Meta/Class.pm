package MooseX::App::Plugin::ZshCompletion::Meta::Class;
# ABSTRACT: Meta class for MooseX::App::Plugin::ZshCompletion
use namespace::autoclean;
use Moose::Role;

use 5.010;
our $VERSION = '0.003'; # VERSION



use MooseX::App::Plugin::ZshCompletion::Command;

around '_build_app_commands' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig(@_);
    $return->{zsh_completion} ||= 'MooseX::App::Plugin::ZshCompletion::Command';

    return $return;
};

1;

__END__

=head1 NAME

MooseX::App::Plugin::ZshCompletion::Meta::Class - Meta class for MooseX::App::Plugin::ZshCompletion

