package Module::New::File::TravisYml;

use strict;
use warnings;
use Module::New::File;

file '.travis.yml' => content { return <<'EOT';
language: perl
perl:
  - 5.8
  - 5.10
  - 5.12
  - 5.14
  - 5.16
  - 5.18
  - 5.20
EOT
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::File::TravisYml

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
