use 5.006;
use strict;
use warnings;

package Test::CPAN::Changes::ReallyStrict;

our $VERSION = '1.000004';

#ABSTRACT: Ensure a Changes file looks exactly like it would if it was machine generated.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use CPAN::Changes 0.17;
use Test::Builder;
use Test::CPAN::Changes::ReallyStrict::Object;

my $TEST = Test::Builder->new();

sub import {
  my ( undef, @args ) = @_;

  my $caller = caller;
  {
    ## no critic (ProhibitNoStrict);
    no strict 'refs';
    *{ $caller . '::changes_ok' }      = \&changes_ok;
    *{ $caller . '::changes_file_ok' } = \&changes_file_ok;
  }
  $TEST->exported_to($caller);
  $TEST->plan(@args);
  return 1;
}













sub changes_ok {
  my (@args) = @_;
  return changes_file_ok( undef, @args );
}

# For testing.
sub _real_changes_ok {
  my ( $tester, $state ) = @_;
  return _real_changes_file_ok( $tester, $state );
}















sub changes_file_ok {
  my ( $file, $config ) = @_;
  $file ||= 'Changes';
  $config->{filename} = $file;
  my $changes_obj = Test::CPAN::Changes::ReallyStrict::Object->new(
    {
      testbuilder => $TEST,
      %{$config},
    },
  );
  return $changes_obj->changes_ok;
}

# Factoring design split so testing can inject a test::builder dummy

sub _real_changes_file_ok {
  my ( $tester, $state ) = @_;
  my $changes_obj = Test::CPAN::Changes::ReallyStrict::Object->new(
    {
      testbuilder => $tester,
      %{$state},
    },
  );
  return $changes_obj->changes_ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::CPAN::Changes::ReallyStrict - Ensure a Changes file looks exactly like it would if it was machine generated.

=head1 VERSION

version 1.000004

=head1 SYNOPSIS

  use Test::More;
  eval 'use Test::CPAN::Changes::ReallyStrict';
  plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
  changes_ok();
  done_testing();

=head1 DESCRIPTION

This module is for people who want their Changes file to be 1:1 Identical to how it would be
if they'd generated it programmatically with CPAN::Changes.

This is not for the faint of heart, and will whine about even minor changes of white-space.

You are also at upstream's mercy as to what a changes file looks like, and in order to keep this test
happy, you'll have to update your whole changes file if upstream changes how they format things.

=head1 EXPORTED FUNCTIONS

=head2 changes_ok

  changes_ok();

  changes_ok({
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=head2 changes_file_ok

  changes_file_ok();

  changes_file_ok('ChangeLog');

  changes_ok('ChangeLog', {
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
