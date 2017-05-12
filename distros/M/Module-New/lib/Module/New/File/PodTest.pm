package Module::New::File::PodTest;

use strict;
use warnings;
use Module::New::File;

file 'xt/99_pod.t' => content { return <<'EOT';
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.18";
plan skip_all => 'Test::Pod 1.18 required' if $@;
plan skip_all => 'set RELEASE_TESTING to enable this test' unless $ENV{RELEASE_TESTING};
all_pod_files_ok();
EOT
};

1;

__END__

=head1 NAME

Module::New::File::PodTest

=head1 DESCRIPTION

a template for a L<Test::Pod> test.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
