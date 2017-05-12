package Module::New::File::ShipIt;

use strict;
use warnings;
use Module::New::File;

file '.shipit' => content { return <<'EOT';
steps = FindVersion, ChangeVersion, CheckChangeLog, DistTest, Commit, Tag, MakeDist, UploadCPAN

# if directory, where the normal "make dist" puts its file.
#MakeDist.destination = ~/shipit-dist
#svn.tagpattern = ShipIt-%v
EOT
};

1;

__END__

=head1 NAME

Module::New::File::ShipIt

=head1 DESCRIPTION

a template for a C<.shipit> file.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
