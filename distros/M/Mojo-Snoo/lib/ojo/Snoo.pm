package ojo::Snoo;
use Moo;

use Mojo::Snoo::Multireddit;
use Mojo::Snoo::Subreddit;
use Mojo::Snoo::Link;
use Mojo::Snoo::Comment;
use Mojo::Snoo::User;

use Mojo::Util ();

sub import {
    my $caller = caller;
    Mojo::Util::monkey_patch(
        $caller,    #
        c  => sub { Mojo::Snoo::Comment->new(@_)     },
        l  => sub { Mojo::Snoo::Link->new(@_)        },
        mr => sub { Mojo::Snoo::Multireddit->new(@_) },
        sr => sub { Mojo::Snoo::Subreddit->new(@_)   },
        u  => sub { Mojo::Snoo::User->new(@_)        },
    );
}

1;

__END__

=head1 NAME

ojo::Snoo - one-liner Mojo functions for the Reddit API

=head1 DESCRIPTION

L<ojo::Snoo> provides shortcut functions to the L<Mojo::Snoo> modules.

=head1 SYNOPSIS

    perl -Mojo::Snoo -E 'su("perl")->links->each(sub { say $_->author })

=head1 METHODS

=head2 c

Returns a L<Mojo::Snoo::Comment> object.

=head2 l

Returns a L<Mojo::Snoo::Link> object.

=head2 mr

Returns a L<Mojo::Snoo::Multireddit> object.

=head2 sr

Returns a L<Mojo::Snoo::Subreddit> object.

=head2 u

Returns a L<Mojo::Snoo::User> object.

=head1 API DOCUMENTATION

Please see the official L<Reddit API documentation|http://www.reddit.com/dev/api>
for more details regarding the usage of endpoints. For a better idea of how
OAuth works, see the L<Quick Start|https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example>
and the L<full documentation|https://github.com/reddit/reddit/wiki/OAuth2>. There is
also a lot of useful information of the L<redditdev subreddit|http://www.reddit.com/r/redditdev>.

=head1 LICENSE

The (two-clause) FreeBSD License. See LICENSE for details.
