package MooX::Options::Actions;

use strict;
use warnings;

use Import::Into;

our $VERSION = '0.001';

=head1 NAME

MooX::Options::Actions - Instant one class CLI App

=head1 SYNOPSIS

In MyApp::Script:
  
  package MyApp::Script;

  use MooX::Options::Actions;

  option 'boo' => (
    is => 'ro',
    format => 's',
    required => 1,
    doc => "Surprise!"
  );

  sub cmd_dump {
    my ( $self ) = @_;

    print "Message: [" . $self->boo . "]\n";
  }

  1;

In script.pl:

  #! /usr/bin/env perl

  use strict;
  use warnings;

  use MyApp::Script;

  MyApp::Script->new_with_actions;

On the command line:

  $ ./script.pl dump --boo Hello
  Message: [Hello]

=head1 DESCRIPTION

MooX::Options::Actions is a set of packages designed to make setting up and
creating command line applications really easy. It automatically imports Moo,
MooX::Options, namespace::clean, and a
L<MooX::Options::Actions::Builder/new_with_actions> function to set up the top
level commands. this means you only need to include this one module, and then
you can set up options as from L<MooX::Options>, and set up commands to act on
those options by creating subroutines with the C<cmd_> prefix.

=cut

sub import {
  my $target = caller;
  Moo->import::into($target);
  MooX::Options->import::into($target, protect_argv => 0 );
  namespace::clean->import::into(
    $target,
    -except => [ qw/ _options_data _options_config / ],
  );
  MooX::Options::Actions::Builder->import::into($target, qw/ new_with_actions /);
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 COPYRIGHT

Copyright 2017- Tom Bloor

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MooX::Options> L<Import::Into>

=cut

1;
