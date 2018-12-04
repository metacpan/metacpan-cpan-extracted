package POE::Component::SmokeBox::Backend::Test::Idle;
$POE::Component::SmokeBox::Backend::Test::Idle::VERSION = '0.54';
#ABSTRACT: a backend to test idle kills.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
	check => [ '-e', 1 ],
	index => [ '-e', 1 ],
	smoke => [ '-e', '$|=1; my $module = shift; print $module, qq{\n}; sleep 60;' ],
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::Test::Idle - a backend to test idle kills.

=head1 VERSION

version 0.54

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::Test::Idle is a L<POE::Component::SmokeBox::Backend> plugin used during the
L<POE::Component::SmokeBox> tests.

It contains no moving parts.

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
