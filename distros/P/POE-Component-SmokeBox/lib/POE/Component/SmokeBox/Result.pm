package POE::Component::SmokeBox::Result;
$POE::Component::SmokeBox::Result::VERSION = '0.54';
#ABSTRACT: object defining SmokeBox job results.

use strict;
use warnings;

sub new {
  my $package = shift;
  return bless [ ], $package;
}

sub add_result {
  my $self = shift;
  my $result = shift || return;
  return unless ref $result eq 'HASH';
  push @{ $self }, $result;
}

sub results {
  return @{ $_[0] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Result - object defining SmokeBox job results.

=head1 VERSION

version 0.54

=head1 DESCRIPTION

POE::Component::SmokeBox::Result is a class encapsulating the job results that are returned by
L<POE::Component::SmokeBox::Backend> and L<POE::Component::SmokeBox>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Component::SmokeBox::Result object.

=back

=head1 METHODS

=over

=item C<add_result>

Expects one argument, a hashref, representing a job result.

=item C<results>

Returns a list of hashrefs representing job results.

=back

=head1 SEE ALSO

L<POE::Component::SmokeBox>

L<POE::Component::SmokeBox::Backend>

L<POE::Component::SmokeBox::JobQueue>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
