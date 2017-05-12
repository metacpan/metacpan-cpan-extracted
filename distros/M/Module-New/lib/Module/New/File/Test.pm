package Module::New::File::Test;

use strict;
use warnings;
use Module::New::File;

file '{MAINFILE}' => content { return <<'EOT';
use strict;
use warnings;
use Test::More;

done_testing;
EOT
};

1;

__END__

=head1 NAME

Module::New::File::Test

=head1 DESCRIPTION

a template for a general test.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
