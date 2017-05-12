package Module::New::Recipe::NextVersion;

use strict;
use warnings;
use Module::New::Recipe;
use Module::New::Command::Basic;
use Module::New::Command::Version;

available_options ();

flow {
  guess_root;

  update_versions;
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::Recipe::NextVersion - update VERSIONs

=head1 USAGE

From the shell/command line:

=over 4

=item module_new next_version [version]

updates VERSIONs

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
