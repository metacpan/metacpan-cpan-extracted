package Module::New::Recipe::Manifest;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;

available_options (qw( edit|e ));

flow {
  guess_root;

  create_manifest;

  edit_mainfile optional => 1, file => 'MANIFEST';
};

1;

__END__

=head1 NAME

Module::New::Recipe::Manifest - update MANIFEST

=head1 USAGE

From the shell/command line:

=over 4

=item module_new manifest

updates MANIFEST.

=back

=head1 OPTIONS

=over 4

=item edit

If set to true, you can edit the updated MANIFEST.

=item force

If set to true, MANIFEST will be removed at first (to remove unwanted/missing entries).

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
