package Module::New::Log;

use strict;
use warnings;
use Log::Dump;
use Module::New::Meta;

methods {
  log       => sub { shift; __PACKAGE__->log(@_) },
  logger    => sub { shift; __PACKAGE__->logger(@_) },
  logfile   => sub { shift; __PACKAGE__->logfile(@_) },
  logfilter => sub { shift; __PACKAGE__->logfilter(@_) },
};

1;

__END__

=head1 NAME

Module::New::Log

=head1 DESCRIPTION

This is a singleton wrapper of L<Log::Dump>. See L<Log::Dump> for usage.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
