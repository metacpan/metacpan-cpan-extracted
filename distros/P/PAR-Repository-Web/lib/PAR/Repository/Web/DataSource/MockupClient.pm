package PAR::Repository::Web::DataSource::MockupClient;

use strict;
use warnings;
use base 'PAR::Repository::Query';

=head1 NAME

PAR::Repository::Web::DataSource::MockupClient - A mockup repository client for in-memory caching

=head1 SYNOPSIS

See L<PAR::Repository::Web>

=head1 DESCRIPTION

This class acts as a mockup of a real repository client. It's used
by the memory cached repository data source in order to be able
to intercept accesses to the DBM handles. This class inherits from
L<PAR::Repository::Query>.

=head1 METHODS

... are all private, sorry. (Well, more like protected, but you get the idea.)

=cut

sub verbose {}

sub new {
  my $class = shift;
  my $self = bless {
    modules => shift,
    scripts => shift,
  } => $class;

  return $self;
}

sub modules_dbm {
  my $self = shift;
  return ($self->{modules}, 'this is a mockup file name');
}

sub scripts_dbm {
  my $self = shift;
  return ($self->{scripts}, 'this is a mockup file name');
}

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
