package Sys::RevoBackup::Plugin;
{
  $Sys::RevoBackup::Plugin::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Plugin::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for any revobackup plugin

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
# has ...
has 'parent' => (
    'is'    => 'rw',
    'isa'   => 'Sys::RevoBackup',
    'required' => 1,
);

has 'priority' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_priority',
);
# with ...
with qw(Log::Tree::RequiredLogger Config::Yak::RequiredConfig);
# initializers ...
sub _init_priority { return 0; }
# your code here ...
sub run_config_hook { return; }
sub run_prepare_hook { return; }
sub run_cleanup_hook { return; }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Plugin - baseclass for any revobackup plugin

=head1 METHODS

=head2 run_cleanup_hook

Run after the backup is finished.

=head2 run_config_hook

Run to configure all backups jobs. May supply additional backup jobs.

=head2 run_prepare_hook

Run before the backups are made but after the config hook was run.

=head1 NAME

Sys::RevoBackup::Plugin - Baseclass for any RevoBackup plugin.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
