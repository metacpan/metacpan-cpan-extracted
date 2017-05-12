package Prancer::Plugin::Log4perl;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.01';

use Prancer::Plugin;
use parent qw(Prancer::Plugin Exporter);

use Log::Log4perl ();
use Try::Tiny;
use Carp;

our @EXPORT_OK = qw(logger);
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub load {
    my $class = shift;

    # initialize the logger if necessary
    if (!Log::Log4perl->initialized()) {
        Log::Log4perl->init(\qq|
            log4perl.rootLogger = INFO, stdout
            log4perl.appender.stdout = Log::Dispatch::Screen
            log4perl.appender.stdout.stderr = 0
            log4perl.appender.stdout.layout = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.stdout.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %5p [%c{1}:%M:%L] - %m%n
        |);
    }

    return bless({}, $class);
}

sub logger {
    my $package = (caller())[0];
    return Log::Log4perl->get_logger($package);
}

1;

=head1 NAME

Prancer::Plugin::Log4perl

=head1 SYNOPSIS

This plugin connects your L<Prancer> application to L<Log::Log4perl> and
exports a keyword to access the configured logger. You don't I<need> this
module to log things but it certainly makes it easier.

There is very minimal configuration required to get started with this module.
To enable the logger you only need to do this:

    use Prancer::Plugin::Log4perl qw(logger);

    Prancer::Plugin::Log4perl->load();

    logger->info("hello, logger here");
    logger->fatal("something done broke");

By default, this plugin will initialize L<Log::Log4perl> with a very basic
configuration to avoid warnings when used. You can override the configuration
by loading your own before calling C<load> on this plugin. This plugin's
C<load> implementation simply calls C<Log::Log4perl-E<gt>initialized()> to see
if it should load its own. For example, you might do this:

    use Prancer::Plugin::Log4perl qw(logger);

    Log::Log4perl::init('/etc/log4perl.conf');
    Prancer::Plugin::Log4perl->load();

The C<logger> keyword gets you direct access to an instance of the logger and
you can always call static methods on L<Log::Log4perl> and interact with the
logger that way, too.

=head1 COPYRIGHT

Copyright 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Prancer>

=item

L<Log::Log4perl>

=item

L<Log::Dispatch>

=item

L<Log::Dispatch::Screen>

=back

=cut
