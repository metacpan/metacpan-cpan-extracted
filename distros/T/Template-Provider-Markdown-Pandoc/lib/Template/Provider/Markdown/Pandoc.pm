=head1 NAME

Template::Provider::Markdown::Pandoc - expand Markdown templates to HTML

=head1 SYNOPSIS

    use Template;
    use Template::Provider::Pandoc; # Use this instead.

=head1 DESCRIPTION

Template::Provider::Markdown::Pandoc was an extension to the Template Toolkit
which automatically converted Markdown files into HTML before they are
processed by TT.

It has now been obsoleted by the newer Template::Provider::Pandoc. Please
ise that instead.

=cut

package Template::Provider::Markdown::Pandoc;

use strict;
use warnings;
use 5.010;

use parent 'Template::Provider';

our $VERSION = '999.999.999';

1;

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Magnum Solutions Ltd. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<Pandoc>,
L<Template::Provider::Markdown>.

=cut
