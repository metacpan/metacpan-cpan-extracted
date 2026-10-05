#
#  This file is part of Task::Markdown::Publish.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
package Task::Markdown::Publish;

use strict qw(vars);
use vars qw($AUTHORITY $VERSION);
use warnings;

$AUTHORITY='cpan:ASPEER';
$VERSION='0.003';

1;

__END__

=head1 NAME

Task::Markdown::Publish - install the documentation conversion and publishing toolchain

=head1 SYNOPSIS

    cpanm Task::Markdown::Publish

=head1 DESCRIPTION

This Task distribution installs Task::Markdown::Pod plus the reusable Markdown
site publisher and its ExtUtils::MakeMaker integration.

It provides no runtime functions of its own.

=head1 INSTALLED MODULES

=over

=item * Task::Markdown::Pod

=item * Markdown::Pod::Embed

=item * Docbook::Convert

=item * ASPEER::MakeMaker::Markdown::Pod

=item * Markdown::Publish

=item * ASPEER::MakeMaker::Markdown::Publish

=back

=head1 AUTHOR

Andrew Speer E<lt>andrew.speer@isolutions.com.auE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
