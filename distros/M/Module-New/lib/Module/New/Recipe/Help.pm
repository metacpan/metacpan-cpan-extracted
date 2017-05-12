package Module::New::Recipe::Help;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Help;

flow {
  help;
};

1;

__END__

=head1 NAME

Module::New::Recipe::Help - show help

=head1 USAGE

From the shell/command line:

=over 4

=item module_new help

lists all the commands.

=item module_new help <command>

shows pod for the <command>.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
