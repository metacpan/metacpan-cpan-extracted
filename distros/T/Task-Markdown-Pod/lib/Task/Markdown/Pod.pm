#
#  This file is part of Task::Markdown::Pod.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
package Task::Markdown::Pod;

use strict qw(vars);
use vars qw($AUTHORITY $VERSION);
use warnings;

$AUTHORITY='cpan:ASPEER';
$VERSION='0.001';

1;

__END__

=head1 NAME

Task::Markdown::Pod - install the Markdown and DocBook to POD toolchain

=head1 SYNOPSIS

    cpanm Task::Markdown::Pod

=head1 DESCRIPTION

This Task distribution installs the Perl modules used to convert Markdown
sidecars to POD, convert DocBook through Markdown into the documentation
pipeline, and integrate both operations with ExtUtils::MakeMaker.

It provides no runtime functions of its own.

=head1 INSTALLED MODULES

=over

=item * Markdown::Pod::Embed

=item * Docbook::Convert

=item * ASPEER::MakeMaker::Markdown::Pod

=back

=head1 AUTHOR

Andrew Speer E<lt>andrew.speer@isolutions.com.auE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
