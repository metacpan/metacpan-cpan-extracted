package Monitoring::Reporter::Cmd::Command::actions;
{
  $Monitoring::Reporter::Cmd::Command::actions::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Cmd::Command::actions::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: enable all actions from the CLI

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use Data::Dumper;

# extends ...
extends 'Monitoring::Reporter::Cmd::Command';
# has ...
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    my $status = $self->mr()->enable_actions();

    return 1;
}

sub abstract {
    return 'Enable all actions';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Cmd::Command::actions - enable all actions from the CLI

=head1 METHODS

=head2 execute

List all triggers.

=head2 abstract

Workaround.

=head1 NAME

Monitoring::Reporter::Cmd::Command::list - list all triggers from the CLI

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
