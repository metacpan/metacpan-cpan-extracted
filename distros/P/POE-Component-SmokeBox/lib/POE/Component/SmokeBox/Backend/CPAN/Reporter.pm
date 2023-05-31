package POE::Component::SmokeBox::Backend::CPAN::Reporter;
$POE::Component::SmokeBox::Backend::CPAN::Reporter::VERSION = '0.58';
#ABSTRACT: a backend for CPAN/CPAN::Reporter smokers.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
        check => [ '-MCPAN::Reporter', '-e', 1 ],
        index => [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ],
        smoke => [ '-MCPAN', '-e', 'my $module = shift; $CPAN::Config->{test_report} = 1; CPAN::Index->reload; $CPAN::META->reset_tested; test($module);' ],
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::CPAN::Reporter - a backend for CPAN/CPAN::Reporter smokers.

=head1 VERSION

version 0.58

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::CPAN::Reporter is a L<POE::Component::SmokeBox::Backend> plugin that defines the
C<check>, C<index> and C<smoke> commands for L<CPAN>/L<CPAN::Reporter> based smokers.

=head1 METHODS

=over

=item C<check>

Returns [ '-MCPAN::Reporter', '-e', 1 ]

=item C<index>

Returns [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ]

=item C<smoke>

Returns [ '-MCPAN', '-e', 'my $module = shift; $CPAN::Config->{test_report} = 1; CPAN::Index->reload; $CPAN::META->reset_tested; test($module);' ]

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
