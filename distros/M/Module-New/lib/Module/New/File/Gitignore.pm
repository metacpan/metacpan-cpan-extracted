package Module::New::File::Gitignore;

use strict;
use warnings;
use Module::New::File;

file '.gitignore' => content { return <<'EOT';
pm_to_blib
Makefile
/blib/
/.build/
/_build/
/.carton/
/local/
/Build
/tmp/
/nytprof/
/cover_db/
MYMETA.*
dll.*
*.old
*.bak
*.bat
*.o
*.obj
*.bs
*.swp
*.def
*.out
*~
EOT
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::File::Gitignore

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
