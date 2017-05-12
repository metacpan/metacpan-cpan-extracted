package Module::New::Recipe::File;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;

available_options qw( edit|e type|t=s );

flow {
  guess_root;

  loop {
    set_file;

    create_files('{ANY_TYPE}');

    edit_mainfile;
  };

  create_manifest;
};

1;

__END__

=head1 NAME

Module::New::Recipe::File - create a file

=head1 USAGE

From the shell/command line:

=over 4

=item module_new file Module::Name

creates C<lib/Module/Name.pm> (with C<::File::Module> template).

=item module_new file t/test.t

creates C<t/test.t> (with C<::File::Test> template).

=item module_new file bin/script

creates C<bin/script> (with C<::File::Script> template).

=back

=head1 OPTIONS

=over 4

=item type

  module_new file --type=MainModule Main::Module

You can explicitly specify a file type (actually a template module under the C<::File> namespace) with this option.

=item in

  module_new file Test::Module --in t

creates C<t/lib/Test/Module.pm>, not <lib/Test/Module.pm>.

=item edit

  module_new file Test::Module --edit

If set to true, you can edit the file you created.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
