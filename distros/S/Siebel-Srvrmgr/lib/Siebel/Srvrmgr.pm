package Siebel::Srvrmgr;

use warnings;
use strict;
use Log::Log4perl 1.41;
use Carp;
our $VERSION = '0.29'; #VERSION

=pod

=head1 NAME

Siebel::Srvrmgr - utilities to be used with the Siebel srvrmgr program

=head1 DESCRIPTION

The distribution Siebel-Srvrmgr was created to define a set of tools to interact with the C<srvrmgr> program from Siebel.

It was started initially to create a parser for the project Siebel Monitoring Tools (L<http://code.google.com/p/siebel-monitoring-tools/>) and later was grown to a 
set of more generic functionality, thus making sense to be published at CPAN.

This package used to be only Pod, but since release 0.09 it has a logging feature. See logging_cfg for details.

B<Since release 0.15, this distribution breaks API compabitility with previous releases. Consider yourself warned.>

=head1 CLASS METHODS

=head2 logging_cfg

Returns a string with the configuration to be used by a L<Log::Log4perl> instance.

The configuration of L<Log::Log4perl> is available after the C<__DATA__> code block of this package. Logging is disabled by default, but it can be enabled by
only commenting the line:

    log4perl.threshold = OFF

with the default "#" Perl comment character.

Logging is quite flexible (see L<Log::Log4perl> for details) but the default configuration uses only FATAL level printing messages to STDOUT.

It is also possible to set a different L<Log::Log4perl> configuration file by setting the environment variable SIEBEL_SRVRMGR_DEBUG with the complete location to the
configuration file. This module will look first for this variable configuration and if found, will try to use the configuration from there.

=cut

sub logging_cfg {

    my $cfg = undef;

    local $/;

    if ( $ENV{SIEBEL_SRVRMGR_DEBUG} ) {

        if (    ( -e $ENV{SIEBEL_SRVRMGR_DEBUG} )
            and ( -f $ENV{SIEBEL_SRVRMGR_DEBUG} ) )
        {

            open( my $in, '<', $ENV{SIEBEL_SRVRMGR_DEBUG} )
              or confess "Cannot read $ENV{SIEBEL_SRVRMGR_DEBUG}: $!";
            $cfg = <$in>;
            close($in);

        }
        else {

            confess
"SIEBEL_SRVRMGR_DEBUG is defined ($ENV{SIEBEL_SRVRMGR_DEBUG}) but the value does not exists in the filesystem or is not a file";

        }

    }
    else {

        $cfg = <Siebel::Srvrmgr::DATA>;

    }

    return $cfg;

}

=pod

=head2 gimme_logger

This method returns a L<Log::Log4perl::Logger> object as defined by the C<logging_cfg> method.

It expects as parameters the following items:

=over

=item *

package: string with the name of the package that wants a logger. This is a required parameter.

=back

The configuration will B<not> be read again after initialization.

=cut

sub gimme_logger {

    my $class   = shift;
    my $package = shift;

    if ( Log::Log4perl->initialized() ) {

        return Log::Log4perl->get_logger($package);

    }

    confess 'package parameter must be defined'
      unless ( ( defined($package) ) and ( $package =~ /^[\w\:]+$/ ) );

    confess "Could not start logging facilities"
      unless ( Log::Log4perl->init_once( \$class->logging_cfg() ) );

    return Log::Log4perl->get_logger($package);

}

=pod

=head1 SEE ALSO

The classes below might give you a introduction of the available classes and features:

=over

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

The project web page at L<https://github.com/glasswalk3r/siebel-monitoring-tools/> contains more information about project features and state.

=item *

PPM package: if you are a Active Perl user, you might be happy to know that there are PPM packages created automatically from this distribution
at L<https://code.activestate.com/ppm/Siebel-Srvrmgr/>.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

__DATA__
log4perl.appender.A1=Log::Log4perl::Appender::Screen
log4perl.appender.A1.stderr=0
log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n
log4perl.logger.Siebel.Srvrmgr.Daemon=FATAL, A1
log4perl.logger.Siebel.Srvrmgr.ListParser=FATAL, A1
