package Module::New::Recipe::Prove;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;
use Module::New::Command::Test;

available_options ();

flow {
  guess_root;

  prove;
};

1;

__END__

=head1 NAME

Module::New::Recipe::Prove - run tests

=head1 USAGE

From the shell/command line:

=over 4

=item module_new prove -lv t/*.t

executes the C<prove> command regardless of the current directory (it first changes directory to the distribution root by itself).

=back

=head1 OPTIONS

You can pass any options and arguments 'prove' accepts.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
