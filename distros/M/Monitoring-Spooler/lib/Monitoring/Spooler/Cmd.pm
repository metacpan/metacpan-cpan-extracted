package Monitoring::Spooler::Cmd;
$Monitoring::Spooler::Cmd::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: CLI for Monitoring::Spooler

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

# extends ...
extends 'MooseX::App::Cmd';
# has ...
# with ...
# initializers ...

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd - CLI for Monitoring::Spooler

=head1 SYNOPSIS

    use Monitoring::Spooler::Cmd;
    my $Mod = Monitoring::Spooler::Cmd::->new();

=head1 DESCRIPTION

This class is the CLI for Monitoring::Spooler.

It is a mere requirement by App::Cmd. Don't mess with it.

=head1 NAME

Monitoring::Spooler::Cmd - CLI class.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
