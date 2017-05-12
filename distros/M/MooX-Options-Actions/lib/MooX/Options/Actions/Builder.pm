package MooX::Options::Actions::Builder;

use strict;
use warnings;

use base qw/ Exporter /;

our @EXPORT_OK = qw/ new_with_actions /;

=head1 NAME

MooX::Options::Actions::Builder - Builder class for MooX::Options::Actions

=head1 SYNOPSIS

  use Moo;
  use MooX::Options::Actions::Builder qw/ new_with_actions /;

=head1 DESCRIPTION

Used for holding the main builder code for MooX::Options::Actions - can
also be used to set up a simple commandline application using Moo classes.

=cut

sub new_with_actions {
  my $class = shift;

  my $self = $class->new_with_options(@_);

  my ( $cmd, @extra ) = @ARGV;

  die "Must supply a command\n" unless $cmd;
  die "Extra commands found - Please provide only one!\n" if @extra;
  die "No such command ${cmd} \n" unless $self->can("cmd_${cmd}");

  $self->${\"cmd_${cmd}"};

  return $self;
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 COPYRIGHT

Copyright 2017- Tom Bloor

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MooX::Options::Actions>

=cut

1;
