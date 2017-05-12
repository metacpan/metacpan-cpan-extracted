package Module::New::Command::Test;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;

functions {
  prove => sub () { Module::New::Queue->register(sub {
    my ($self, @args) = @_;

    eval "require App::Prove";
    unless ( $@ ) {
    my $app = App::Prove->new;
       $app->process_args(@args);
       $app->run;
    }
    else {
      exec( 'prove', @args );
    }
  })},
};

1;

__END__

=head1 NAME

Module::New::Command::Test

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 prove

executes C<prove> command (from L<Test::Harness>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
