package POE::Component::SmokeBox::Backend::CPANPLUS::YACSmoke;
$POE::Component::SmokeBox::Backend::CPANPLUS::YACSmoke::VERSION = '0.58';
#ABSTRACT: a backend for CPANPLUS::YACSmoke smokers.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
	check  => [ '-MCPANPLUS::YACSmoke', '-e', 1 ],
	index  => [ '-MCPANPLUS::Backend', '-e', 'CPANPLUS::Backend->new()->reload_indices( update_source => 1 );' ],
	smoke  => [ '-MCPANPLUS::YACSmoke', '-e', 'my $module = shift; my $smoke = CPANPLUS::YACSmoke->new(); $smoke->test($module);' ],
  digest => qr/^\[MSG\] CPANPLUS is prefering/,
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::CPANPLUS::YACSmoke - a backend for CPANPLUS::YACSmoke smokers.

=head1 VERSION

version 0.58

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::CPAN::Reporter is a L<POE::Component::SmokeBox::Backend> plugin that defines the
C<check>, C<index> and C<smoke> commands for L<CPANPLUS::YACSmoke> based smokers.

=head1 METHODS

=over

=item C<check>

Returns [ '-MCPANPLUS::YACSmoke', '-e', 1 ]

=item C<index>

Returns [ '-MCPANPLUS::Backend', '-e', 'CPANPLUS::Backend->new()->reload_indices( update_source => 1 );' ]

=item C<smoke>

Returns [ '-MCPANPLUS::YACSmoke', '-e', 'my $module = shift; my $smoke = CPANPLUS::YACSmoke->new(); $smoke->test($module);' ]

=item C<digest>

Returns the following regexp:

  qr/^\[MSG\] CPANPLUS is prefering/

=back

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
