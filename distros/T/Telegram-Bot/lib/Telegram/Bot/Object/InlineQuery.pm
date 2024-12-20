package Telegram::Bot::Object::InlineQuery;
$Telegram::Bot::Object::InlineQuery::VERSION = '0.027';
# ABSTRACT: The base class for Telegram 'Invoice' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Mojo::JSON ();
use Telegram::Bot::Object::Location;
use Telegram::Bot::Object::User;

has 'id';
has 'from';        # User
has 'query';
has 'offset';
has 'chat_type';
has 'location';    # Location

sub fields {
    return {
        scalar                            => [qw/id query offset chat_type/],
        'Telegram::Bot::Object::User'     => [qw/from/],
        'Telegram::Bot::Object::Location' => [qw/location/],
    };
}


sub reply {
    my $self    = shift;
    my $results = shift // [];
    my $args    = shift // {};

    return $self->_brain->answerInlineQuery(
        {
            inline_query_id => $self->id,
            results         => Mojo::JSON::encode_json($results),
            %$args
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::InlineQuery - The base class for Telegram 'Invoice' type objects

=head1 VERSION

version 0.027

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#inlinequery> for details of the
attributes available for L<Telegram::Bot::Object::InlineQuery> objects.

=head1 METHODS

=head2

A convenience method to reply to an inline query with an array of Perl objects.

Takes two arguments:

=over

=item C<$results>

An optional array reference of results. Defaults to the empty array ref. See L<https://core.telegram.org/bots/api#inlinequeryresult>.

=item C<$args>

An optional hash references of optional arguments.

=over

=item C<cache_time>

The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300 if not present.

=item C<is_personal>

Pass True if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query.

=item C<next_offset>

Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don't support pagination. Offset length can't exceed 64 bytes.

=item C<button>

A JSON-serialized object describing a button to be shown above inline query results

=over

=over

Will return true.

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
