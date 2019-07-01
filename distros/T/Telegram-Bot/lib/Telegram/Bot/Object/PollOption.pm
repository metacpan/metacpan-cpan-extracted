package Telegram::Bot::Object::PollOption;
$Telegram::Bot::Object::PollOption::VERSION = '0.021';
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

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#polloption> for details of the
attributes available for L<Telegram::Bot::Object::PollOption> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
