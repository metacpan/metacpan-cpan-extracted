package Module::New::File::Plain;

use strict;
use warnings;
use Module::New::File;

file '{MAINFILE}' => content { return ''; };

1;

__END__

=head1 NAME

Module::New::File::Plain

=head1 DESCRIPTION

a template for a plain text (actually a blank file).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
