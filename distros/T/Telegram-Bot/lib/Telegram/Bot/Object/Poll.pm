package Telegram::Bot::Object::Poll;
$Telegram::Bot::Object::Poll::VERSION = '0.027';
# ABSTRACT: The base class for Telegram 'Poll' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::PollOption;


has 'id';
has 'question';
has 'options'; # Array of PollOption
has 'is_closed';

sub fields {
  return { scalar                              => [qw/id question is_closed/],
           'Telegram::Bot::Object::PollOption' => [qw/options /],

         };
}

sub arrays {
  qw/options/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Poll - The base class for Telegram 'Poll' type objects

=head1 VERSION

version 0.027

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#poll> for details of the
attributes available for L<Telegram::Bot::Object::Poll> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=item *

Julien Fiegehenn <simbabque@cpan.org>

=item *

Jess Robinson <jrobinson@cpan.org>

=item *

Albert Cester <albert.cester@web.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
