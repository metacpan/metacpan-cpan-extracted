package Sys::RevoBackup::Cmd::Command::backupcheck;
{
  $Sys::RevoBackup::Cmd::Command::backupcheck::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Cmd::Command::backupcheck::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: backup integrity check command

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
use Sys::RevoBackup::Utils;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';
# has ...
has 'host' => (
    'is'            => 'ro',
    'isa'           => 'Bool',
    'required'      => 1,
    'default'       => 0,
    'traits'        => [qw(Getopt)],
    'cmd_aliases'   => 'h',
    'documentation' => 'Host to check',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    # Helper method for monitoring, just look up the last status to the given hostname
    if ( Sys::RevoBackup::Utils::backup_status( $self->config(), $self->host() ) ) {
        print "1\n";
        return 1;
    }
    print "0\n";
    return 1;
}

sub abstract {
    return 'Check backup integrity';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Cmd::Command::backupcheck - backup integrity check command

=head1 METHODS

=head2 abstract

Workaround.

=head2 execute

Check the backup.

=head1 NAME

Sys::RevoBackup::Cmd::Command::backupcheck - check the backup integrity

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
