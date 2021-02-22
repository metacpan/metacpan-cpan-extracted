use v5.16;

package Module::Release::PAUSE;

use strict;
use warnings;
use Exporter qw(import);

use Carp qw(croak);

our @EXPORT = qw();

our $VERSION = '2.127';

=encoding utf8

=head1 NAME

Module::Release::PAUSE - Interact with the Perl Authors Upload Server (PAUSE)

=head1 SYNOPSIS

=head1 DESCRIPTION

The release script automatically loads this module if it thinks that you
want to upload to PAUSE by noticing the C<cpan_user> configuration
directive.

There's nothing here yet.

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2021, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
