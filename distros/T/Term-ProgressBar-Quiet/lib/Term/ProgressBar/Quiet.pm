package Term::ProgressBar::Quiet;
use strict;
use warnings;
use IO::Interactive qw(is_interactive);
use Term::ProgressBar;
use Test::MockObject;
our $VERSION = '0.31';

sub new {
    my $class = shift;
    if ( is_interactive ) {
        return Term::ProgressBar->new(@_);
    } else {
        my $mock = Test::MockObject->new();
        $mock->set_true('update');
        $mock->set_true('message');
        return $mock;
    }
}

1;

__END__

=head1 NAME

Term::ProgressBar::Quiet - Provide a progress meter if run interactively

=head1 SYNOPSIS

  use Term::ProgressBar::Quiet;
  my @todo     = ( 'x' x 10 );
  my $progress = Term::ProgressBar::Quiet->new(
      { name => 'Todo', count => scalar(@todo), ETA => 'linear' } );

  my $i = 0;
  foreach my $todo (@todo) {

      # do something with $todo
      $progress->update( ++$i );
  }
  $progress->message('All done');

=head1 DESCRIPTION

L<Term::ProgressBar> is a wonderful module for showing progress bars
on the terminal. This module acts very much like that module when it
is run interactively. However, when it is not run interactively (for
example, as a cron job) then it does not show the progress bar.
  
=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 COPYRIGHT

Copyright (c) 2007 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

