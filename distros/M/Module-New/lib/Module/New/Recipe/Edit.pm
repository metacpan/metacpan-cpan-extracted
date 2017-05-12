package Module::New::Recipe::Edit;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;

available_options ();

flow {
  guess_root;

  loop {
    set_file;

    edit_mainfile;
  };
};

1;

__END__

=head1 NAME

Module::New::Recipe::Edit - edit a file

=head1 USAGE

From the shell/command line:

=over 4

=item module_new edit Module::Name

opens C<lib/Module/Name.pm> with an editor.

=item module_new edit t/test.t

opens C<t/test.t> with an editor.

=back

=head1 OPTIONS

=over 4

=item in

  module_new edit Test::Module --in t

opens C<t/lib/Test/Module.pm>, not <lib/Test/Module.pm>.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
