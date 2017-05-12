package String::Filter;

use strict;
use warnings;

use Regexp::Assemble;

our $VERSION = '0.01';

sub new {
    my $klass = shift;
    my $args = @_ == 1 ? $_[0] : +{ @_ };
    my $self = bless {
        rules        => [],
        default_rule => $args->{default_rule} || sub { $_[0] },
        _ra          => Regexp::Assemble->new(),
        _re          => undef,
    };
    $self->add_rule(@{$args->{rules}})
        if $args->{rules};
    return $self;
}

sub add_rule {
    my $self = shift;
    die "# of arguments is not even"
        unless @_ % 2 == 0;
    while (@_) {
        my $pattern = shift;
        my $subref = shift;
        $self->{_ra}->add($pattern);
        push @{$self->{rules}}, [ qr/^$pattern/, $subref ];
        $self->{_re} = undef;
    }
}

sub default_rule {
    my $self = shift;
    $self->{default_rule} = shift
        if @_;
    return $self->{default_rule};
}

sub filter {
    my ($self, $text) = @_;
    $self->{_re} ||= do {
        my $assembled = $self->{_ra}->re;
        qr/($assembled)/;
    };
    my @ret;
    for my $token (split /$self->{_re}/, $text) {
        next if $token eq '';
        # FIXME do we have to do this O(n) every time?
        for my $rule (@{$self->{rules}}) {
            if ($token =~ /$rule->[0]/) {
                push @ret, $rule->[1]->($token);
                goto NEXT_TOKEN;
            }
        }
        push @ret, $self->{default_rule}->($token);
    NEXT_TOKEN:
        ;
    }
    return join '', @ret;
}

1;
__END__

=head1 NAME

String::Filter - a regexp-based string filter

=head1 SYNOPSIS

    # define the rules that convert tweets to HTML
    # (handles url, @user, #hash)
    my $sf = String::Filter->new(
        rules        => [
            'http://[A-Za-z0-9_\-\~\.\%\?\#\@/]+' => sub {
                my $url = shift;
                sprintf(
                    '<a href="%s">%s</a>',
                    encode_entities($url),
                    encode_entities($url),
                );
            },
            '(?:^|\s)\@[A-Za-z0-9_]+' => sub {
                $_[0] =~ /^(.*?\@)(.*)$/;
                my ($prefix, $user) = ($1, $2);
                sprintf(
                    '%s<a href="http://twitter.com/%s">%s</a>',
                    encode_entities($prefix),
                    encode_entities($user),
                    encode_entities($user),
                );
            },
            '(?:^|\s)#[A-Za-z0-9_]+' => sub {
                $_[0] =~ /^(.?)(#.*)$/;
                my ($prefix, $hashtag) = ($1, $2);
                sprintf(
                    '%s<a href="http://twitter.com/search?q=%s">%s</a>',
                    encode_entities($prefix),
                    encode_entities(uri_escape($hashtag)),
                    $hashtag,
                );
            },
        ],
        default_rule => sub {
            my $text = shift;
            encode_entities($text);
        },
    );
    
    # convert a tweet to HTML
    my $html = $sf->filter($tweet);

=head1 DESCRIPTION

The module is a regexp-based string filter, that can merge multiple conversion rules for converting strings.  The primary target of the module is to convert inline markups (such as the tweets of Twitter) to HTML.

=head1 FUNCTIONS

=head2 new

instantiates the filter object.  Takes a hash as an argument recognizing the attributes below.

=head3 rules

arrayref of more than zero "regexp => subref"s.  For more information see L<add_rule>.

=head3 default_rule

default filter function.  See the L<default_rule> accessor for more information.

=head2 filter($input)

Converts the input string using the given rules and returns it.

=head2 add_rule($regexp => $subref)

adds a conversion rule.  For each substring matching the regular expression the subref will be invoked with the substring as the only argument.  The subref should return the filtered output of the substring.

=head3 default_rule([$subref])

setter / getter for the default conversion function.  The subref should accept a string and return the filtered output of the input.

=head1 COPYRIGHT

Copyright (C) 2010 Cybozu Labs, Inc.  Written by Kazuho Oku.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
