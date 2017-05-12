package SHARYANTO::Log::Util;

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(@log_levels $log_levels_re);

our $VERSION = '0.77'; # VERSION

our @log_levels = (qw/trace debug info warn error fatal/);
our $log_levels_re = join("|", @log_levels);
$log_levels_re = qr/\A(?:$log_levels_re)\z/;

1;
# ABSTRACT: Log-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::Log::Util - Log-related utilities

=head1 VERSION

This document describes version 0.77 of SHARYANTO::Log::Util (from Perl distribution SHARYANTO-Utils), released on 2015-09-04.

=head1 SYNOPSIS

 use SHARYANTO::Log::Util qw(@log_levels $log_levels_re);

=head1 DESCRIPTION

=head1 VARIABLES

None are exported by default, but they are exportable.

=head2 @log_levels

Contains log levels, from lowest to highest. Currently these are:

 (qw/trace debug info warn error fatal/)

They can be used as method names to L<Log::Any> ($log->debug, $log->warn, etc).

=head2 $log_levels_re

Contains regular expression to check valid log levels.

=head1 SEE ALSO

L<SHARYANTO>

L<Log::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Utils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
