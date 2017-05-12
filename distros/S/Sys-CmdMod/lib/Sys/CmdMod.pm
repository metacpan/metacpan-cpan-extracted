package Sys::CmdMod;
{
  $Sys::CmdMod::VERSION = '0.18';
}
BEGIN {
  $Sys::CmdMod::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Command mutators.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
use Try::Tiny;

# extends ...
# has ...
# with ...
with 'Config::Yak::OrderedPlugins' => { -version => 0.18 };

sub _plugin_base_class { return 'Sys::CmdMod::Plugin'; }
# initializers ...

# your code here ...
sub cmd {
    my ($self, $cmd) = @_;

    foreach my $Plugin (@{$self->plugins()}) {
        $self->logger()->log( message => 'Executing plugin '.ref($Plugin), level => 'debug', );
        try {
            $cmd = $Plugin->cmd($cmd);
        } catch {
            $self->logger()->log( message => 'Failed to execute plugin '.ref($Plugin).' w/ error: '.$_, level => 'notice', );
        };
    }

    return $cmd;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::CmdMod - Command mutators.

=head1 SYNOPSIS

    use Sys::CmdMod;
    my $Mod = Sys::CmdMod::->new();
    my $cmd = 'echo 1';
    $cmd = $Mod->cmd($cmd);

=head1 NAME

Sys::CmdMod - Command mutators.

=head1 SUBROUTINES/METHODS

=head2 cmd

Accumulate all command prefixes.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
