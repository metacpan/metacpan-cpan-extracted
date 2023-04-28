package POE::Component::SmokeBox::Backend::Test::Loop;
$POE::Component::SmokeBox::Backend::Test::Loop::VERSION = '0.56';
#ABSTRACT: a backend to test looping output kills.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
	check => [ '-e', 1 ],
	index => [ '-e', 1 ],
	smoke => [ '-e', '$|=1; my $module = shift; while (1) { print $module, qq{\n}; }' ],
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::Test::Loop - a backend to test looping output kills.

=head1 VERSION

version 0.56

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::Test::Loop is a L<POE::Component::SmokeBox::Backend> plugin used during the
L<POE::Component::SmokeBox> tests.

It contains no moving parts.

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
