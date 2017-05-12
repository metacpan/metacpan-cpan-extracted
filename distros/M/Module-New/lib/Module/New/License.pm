package Module::New::License;

use strict;
use warnings;
use Carp;
use Sub::Install 'reinstall_sub';
use Module::Find;

my %LICENSES;

sub _install_dsl {
  my $class = shift;

  return if $class eq 'main';
  return if $class =~ /^Test::/;

  reinstall_sub({
    as   => 'object',
    into => $class,
    code => sub {
      my ($self, $type, $args) = @_;

      croak "unknown license type: $type" unless $LICENSES{$type};
      $LICENSES{$type}->new($args);
    }
  });
}

BEGIN { _install_dsl(__PACKAGE__); }

sub import {
  my ($class, $flag) = @_;

  _install_dsl(caller) if $flag && $flag eq 'base';

  for my $module (sort {$b cmp $a} usesub 'Software::License') {
    next unless $module->can('meta_name');
    $LICENSES{$module->meta_name}  ||= $module;
    $LICENSES{$module->meta2_name} ||= $module;
  }
}

1;

__END__

=head1 NAME

Module::New::License

=head1 SYNOPSIS

  use Module::New::License;
  Module::New::License->render('perl');

=head1 DESCRIPTION

This is used internally to render a license text. At the moment, only perl license is supported.

=head1 METHOD

=head2 render

takes a license name and render the text.

=head1 CREATE OTHER LICENSES

  package Your::Module::New::License;
  use Module::New::License 'base';

  license 'license name' => content { my @args = @_; return <<"EOT";
  blah blah blah...
  EOT
  };

With a C<base> flag, domain specific C<license> and C<content> functions will be installed to define custom licenses.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
