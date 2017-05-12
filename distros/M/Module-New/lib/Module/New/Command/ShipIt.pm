package Module::New::Command::ShipIt;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;

functions {
  shipit => sub (;%) {
    my %options = @_;
    Module::New::Queue->register(sub {
      my $self = shift;
      my $context = Module::New->context;
      return if $options{optional} && !$context->config('shipit');
      $context->files->add('ShipIt');
    })
  }
};

1;

__END__

=head1 NAME

Module::New::Command::ShipIt

=head1 FUNCTIONS

=head2 shipit

adds C<.shipit> file to the distribution.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
