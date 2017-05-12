package POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker;
$POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker::VERSION = '0.52';
#ABSTRACT: a backend for CPAN::Reporter::Smoker smokers.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
        check => [ '-e', 'use CPAN::Reporter::Smoker 0.17;' ],
        index => [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ],
        smoke => [ '-MCPAN::Reporter::Smoker', '-e', 'my $module = shift; start( list => [ $module ] );' ],
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker - a backend for CPAN::Reporter::Smoker smokers.

=head1 VERSION

version 0.52

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker is a L<POE::Component::SmokeBox::Backend> plugin that defines the
C<check>, C<index> and C<smoke> commands for L<CPAN::Reporter::Smoker> based smokers.

=head1 METHODS

=over

=item C<check>

Returns [ '-e', 'use CPAN::Reporter::Smoker 0.17;' ]

=item C<index>

Returns [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ]

=item C<smoke>

Returns [ '-MCPAN::Reporter::Smoker', '-e', 'my $module = shift; start( list => [ $module ] );' ]

=back

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

L<CPAN::Reporter::Smoker>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
