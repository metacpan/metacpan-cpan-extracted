use strict;
use warnings;
package Pod::Eventual::Simple 0.094003;
use Pod::Eventual;
BEGIN { our @ISA = 'Pod::Eventual' }
# ABSTRACT: just get an array of the stuff Pod::Eventual finds

#pod =head1 SYNOPSIS
#pod
#pod   use Pod::Eventual::Simple;
#pod
#pod   my $output = Pod::Eventual::Simple->read_file('awesome.pod');
#pod
#pod This subclass just returns an array reference when you use the reading methods.
#pod The arrayref contains all the Pod events and non-Pod content.  Non-Pod content
#pod is given as hashrefs like this:
#pod
#pod   {
#pod     type       => 'nonpod',
#pod     content    => "This is just some text\n",
#pod     start_line => 162,
#pod   }
#pod
#pod For just the POD events, grep for C<type> not equals "nonpod"
#pod
#pod =for Pod::Coverage new
#pod
#pod =cut

sub new {
  my ($class) = @_;
  bless [] => $class;
}

sub read_handle {
  my ($self, $handle, $arg) = @_;
  $self = $self->new unless ref $self;
  $self->SUPER::read_handle($handle, $arg);
  return [ @$self ];
}

sub handle_event {
  my ($self, $event) = @_;
  push @$self, $event;
}

BEGIN {
  *handle_blank  = \&handle_event;
  *handle_nonpod = \&handle_event;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Eventual::Simple - just get an array of the stuff Pod::Eventual finds

=head1 VERSION

version 0.094003

=head1 SYNOPSIS

  use Pod::Eventual::Simple;

  my $output = Pod::Eventual::Simple->read_file('awesome.pod');

This subclass just returns an array reference when you use the reading methods.
The arrayref contains all the Pod events and non-Pod content.  Non-Pod content
is given as hashrefs like this:

  {
    type       => 'nonpod',
    content    => "This is just some text\n",
    start_line => 162,
  }

For just the POD events, grep for C<type> not equals "nonpod"

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=for Pod::Coverage new

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
