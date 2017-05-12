package Mojolicious::Plugin::TweetButton;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

our $VERSION = '0.0003';

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $app->renderer->add_helper(
        tweet_button => sub {
            my $c    = shift;
            my %args = @_;

            $args{url}     ||= $conf->{url};
            $args{count}   ||= $conf->{count} || 'vertical';
            $args{via}     ||= $conf->{via};
            $args{related} ||= $conf->{related};
            $args{lang}    ||= $conf->{lang};

            my $attrs = '';
            foreach my $name (qw/url text count via related lang/) {
                $attrs .= qq/ data-$name="$args{$name}"/ if $args{$name};
            }

            my $tag = <<"EOF";
<a href="http://twitter.com/share" class="twitter-share-button"$attrs>Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
EOF
            return Mojo::ByteStream->new($tag);
        }
    );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::TweetButton - TweetButton Helper Plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('tweet_button');

    # Mojolicious::Lite
    plugin 'tweet_button';
    plugin 'tweet_button' => {via => 'vtivti'};

=head1 DESCRIPTION

L<Mojolicous::Plugin::TweetButton> adds a C<tweet_button> helper to
L<Mojolicious>.
It is compatible with the button described on twitter page
L<http://twitter.com/goodies/tweetbutton>.

=head2 Helper

    <%= tweet_button %>

Generate tweet button.

=head2 Arguments

All the arguments can be set globally (when loading a plugin) or locally (in the
template).

=over 4

=item count

    <%= tweet_button count => 'horizontal' %>

Location of the tweet count box (can be "vertical", "horizontal" or "none";
"vertical" by default).

=item url

    <%= tweet_button url => 'http://example.com' %>

The URL you are sharing (HTTP Referrer by default).

=item text

    <%= tweet_button url => 'Wow!' %>

The text that will appear in the tweet (Content of the <title> tag by default).

=item via

    <%= tweet_button via => 'vtivti' %>

The author of the tweet (no default).

=item related

    <%= tweet_button related => 'kraih:A robot' %>

Related twitter accounts (no default).

=item lang

    <%= tweet_button lang => 'fr' %>

The language of the tweet (no default).

=back

=head1 METHODS

L<Mojolicious::Plugin::TweetButton> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register helper in L<Mojolicious> application.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/mojolicious-plugin-tweet_button

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

In alphabetical order:

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
