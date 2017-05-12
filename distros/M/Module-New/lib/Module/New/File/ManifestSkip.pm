package Module::New::File::ManifestSkip;

use strict;
use warnings;
use Module::New::File;

file 'MANIFEST.SKIP' => content { return <<'EOT';
(^|/)\.
(^|/)\.svn/
(^|/)\.git/
(^|/)\$~
(^|/)~
(^|/)blib/
(^|/)logs?/
(^|/)data/
(^|/)tmp/
(^|/)Makefile$
\.old$
\.bak$
\.SKIP$
(^|/)pm_to_blib
^cover_db/
^nytprof/
nytprof.out
MYMETA\.
EOT
};

1;

__END__

=head1 NAME

Module::New::File::ManifestSkip

=head1 DESCRIPTION

a template for C<MANIFEST.SKIP>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
