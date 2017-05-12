package Qudo::Plugin::Logger;
use strict;
use warnings;
use base 'Qudo::Plugin';

our $VERSION = '0.01';

use Log::Dispatch::Configurator::Any;
use Log::Dispatch::Config;

sub plugin_name { 'logger' }

sub load {
    my ($class, $option) = @_;

    my $any = Log::Dispatch::Configurator::Any->new($option);
    Log::Dispatch::Config->configure($any);

    $class->register(
        Log::Dispatch::Config->instance
    );
}

1;

__END__

=head1 NAME

Qudo::Plugin::Logger - logger for qudo.

=head1 SYNOPSIS

    my $manager = Qudo->new(...)->manager;
    $manager->register_plugins(
        +{
            name => 'Qudo::Plugin::Logger',
            option => +{
                dispatchers => ['screen'],
                screen => {
                    class     => 'Log::Dispatch::Screen',
                    min_level => 'debug',
                    stderr    => 0,
                },
            },
        }
    );
    $manager->plugins->{logger}->debug('debug message here.');

=head1 DESCRIPTION

Qudo::Plugin::Logger is Log::Dispatch wrapper for qudo.

=head1 AUTHOR

id:lamanotrama

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

