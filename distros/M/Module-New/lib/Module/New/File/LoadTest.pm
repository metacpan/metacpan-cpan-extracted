package Module::New::File::LoadTest;

use strict;
use warnings;
use Module::New::File;

file 't/00_load.t' => content { return <<'EOT';
use strict;
use warnings;
use Test::UseAllModules;

BEGIN { all_uses_ok(); }
EOT
};

1;

__END__

=head1 NAME

Module::New::File::LoadTest

=head1 DESCRIPTION

a template for a load test (which uses L<Test::UseAllModules>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
