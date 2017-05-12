#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use warnings;

package SDLx::GUI::Debug;
# ABSTRACT: Centralized debug utility
$SDLx::GUI::Debug::VERSION = '0.002';
use DateTime;
use Exporter::Lite;
use Time::HiRes qw{ time };

our @EXPORT_OK = qw{ debug };



*debug = $ENV{SDLX_GUI_DEBUG} ? sub {
        my $now = DateTime->from_epoch( epoch => time() );
        my $ts = $now->hms . "." . $now->millisecond;
        my $sub = (caller 1)[3]; $sub =~ s/SDLx::GUI/SxG/;
        warn "[$ts] [$sub] @_";
    } : sub {};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI::Debug - Centralized debug utility

=head1 VERSION

version 0.002

=head1 DESCRIPTION

To facilitate debugging, this module provides a single function to log
traces. However, the C<debug()> function will not output anything unless
the environment variable C<SDLX_GUI_DEBUG> is set to a true value. If it
isn't set or set to a false value, then the function will be optimized
out.

=head1 METHODS

=head2 debug

    debug( @stuff );

Output C<@stuff> on C<STDERR>, with a timestamp and the caller sub.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
