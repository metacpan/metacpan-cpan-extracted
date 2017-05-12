package Monitoring::Spooler::Cmd::Command;
$Monitoring::Spooler::Cmd::Command::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for and CLI command

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
use DBI;
use Config::Yak;
use Log::Tree;
use Monitoring::Spooler::DB;

# extends ...
extends 'MooseX::App::Cmd::Command';
# has ...
has '_config' => (
    'is'    => 'rw',
    'isa'   => 'Config::Yak',
    'lazy'  => 1,
    'builder' => '_init_config',
    'accessor' => 'config',
);

has '_logger' => (
    'is'    => 'rw',
    'isa'   => 'Log::Tree',
    'lazy'  => 1,
    'builder' => '_init_logger',
    'accessor' => 'logger',
);

has '_dbh' => (
    'is'    => 'rw',
    'isa'   => 'Monitoring::Spooler::DB',
    'lazy'  => 1,
    'builder' => '_init_dbh',
    'accessor' => 'dbh',
);
# with ...
# initializers ...
sub _init_dbh {
    my $self = shift;

    my $DBH = Monitoring::Spooler::DB::->new({
        'config'        => $self->config(),
        'logger'        => $self->logger(),
    });

    return $DBH;
}

sub _init_config {
    my $self = shift;

    my $Config = Config::Yak::->new({
        'locations'     => [qw(conf /etc/mon-spooler)],
    });

    return $Config;
}

sub _init_logger {
    my $self = shift;

    my $Logger = Log::Tree::->new('mon-spooler');

    return $Logger;
}

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command - baseclass for and CLI command

=head1 NAME

Monitoring::Spooler::Cmd::Command - Base class for any command.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
