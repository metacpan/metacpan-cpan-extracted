package Module::New::Meta;

use strict;
use warnings;
use Carp;
use Sub::Install 'reinstall_sub';

my $meta;

sub import {
  my $class  = shift;
  my $caller = caller;

  foreach my $type (qw( methods functions )) {
    reinstall_sub({
      as   => $type,
      into => $caller,
      code => sub ($) {
        my $href = shift;
        foreach my $name (keys %{ $href }) {
          $meta->{$caller}->{$name} = $href->{$name};
        }
      }
    });
  }

  reinstall_sub({
    as   => 'import',
    into => $caller,
    code => sub {
      my $class  = shift;
      my $caller = caller;

      return if $caller eq 'main';
      return if $caller =~ /^Test::/;

      my $my_meta = $meta->{$class};
      foreach my $name (keys %{ $my_meta }) {
        reinstall_sub({
          as   => $name,
          into => $caller,
          code => $my_meta->{$name},
        });
      }
    }
  });
}

1;

__END__

=head1 NAME

Module::New::Meta

=head1 DESCRIPTION

Used internally to install functions/methods.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
