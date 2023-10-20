package Telegram::Bot::Object::PollOption;
$Telegram::Bot::Object::PollOption::VERSION = '0.024';
# ABSTRACT: The base class for Telegram 'PollOption' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'text';
has 'voter_count';

sub fields {
  return { scalar  => [qw/text voter_count/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::PollOption - The base class for Telegram 'PollOption' type objects

=head1 VERSION

version 0.024

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#polloption> for details of the
attributes available for L<Telegram::Bot::Object::PollOption> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
