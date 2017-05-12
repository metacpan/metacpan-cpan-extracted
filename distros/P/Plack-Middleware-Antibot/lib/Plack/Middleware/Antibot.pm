package Plack::Middleware::Antibot;

use strict;
use warnings;

use parent 'Plack::Middleware';

our $VERSION = "0.02";

use List::Util qw(sum reduce);
use Plack::Util ();
use Plack::Util::Accessor qw(filters fall_through max_score);

sub prepare_app {
    my $self = shift;

    $self->{max_score} ||= 0.8;

    my $filters_names = $self->filters;

    my @filters;
    foreach my $filter (@$filters_names) {
        my @args;
        if (ref $filter eq 'ARRAY') {
            my $ref = $filter;
            $filter = shift @$ref;
            @args   = @$ref;
        }

        my $filter_class = __PACKAGE__ . '::' . $filter;

        Plack::Util::load_class($filter_class);

        push @filters, $filter_class->new(@args);
    }

    $self->filters(\@filters);

    return $self;
}

sub call {
    my $self = shift;
    my ($env) = @_;

    my @scores;
    my $current_score = 0;
    foreach my $filter (@{$self->filters}) {
        my $res = $filter->execute($env);
        return $res if $res && ref $res eq 'ARRAY';

        my $name = (split /::/, ref $filter)[-1];
        my $key = 'plack.antibot.' . lc($name) . '.detected';

        if ($env->{$key}) {
            push @scores, $filter->score;

            if (@scores > 1) {
                my $p = sum @scores;
                my $q = reduce { $a * $b } @scores;

                $current_score = $p - $q;
            }
            else {
                $current_score = $filter->score;
            }
        }

        last if $current_score >= $self->max_score;
    }

    $env->{'plack.antibot.score'} = $current_score;

    if ($current_score >= $self->max_score) {
        $env->{'plack.antibot.detected'} = 1;

        return [400, [], ['Bad request']] unless $self->fall_through;
    }

    return $self->app->($env);
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::Antibot - Prevent bots from submitting forms

=head1 SYNOPSIS

    use Plack::Builder;

    my $app = { ... };

    builder {
        enable 'Antibot', filters => [qw/FakeField TooFast/];
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Antibot is a L<Plack> middleware that prevents bots from
submitting forms. Every filter implements its own checks, so see their
documentation.

Plack::Middleware::Antibot uses scoring system (0 to 1) to determine if the
client is a bot. Thus it can be configured to match any needs.

=head2 C<$env>

Some filters set additional C<$env> keys all prefixed with C<antibot.>. For
example C<TextCaptcha> filter sets C<antibot.text_captcha> to be shown to the
user.

=head2 Options

=head3 B<max_score>

When accumulated score reaches this amount, no more filters are run and bot is
detected. C<0.8> by default.

=head3 B<filters>

    enable 'Antibot', filters => ['FakeField'];

To specify filter arguments instead of a filter name pass an array references:

    enable 'Antibot', filters => [['FakeField', field_name => 'my_fake_field']];

=head3 B<fall_through>

    enable 'Antibot', filters => ['FakeField'], fall_through => 1;

Sometimes it is needed to process detected bot yourself. This way in case of
detection C<$env>'s key C<antibot.detected> will be set.

=head2 Available filters

=over

=item L<Plack::Middleware::Antibot::FakeField> (requires L<Plack::Session>)

Check if an invisible or hidden field is submitted.

=item L<Plack::Middleware::Antibot::Static> (requires L<Plack::Session>)

Check if a static file was fetched before form submission.

=item L<Plack::Middleware::Antibot::TextCaptcha> (requires L<Plack::Session>)

Check if correct random text captcha is submitted.

=item L<Plack::Middleware::Antibot::TooFast>

Check if form is submitted too fast.

=item L<Plack::Middleware::Antibot::TooSlow>

Check if form is submitted too slow.

=back

=head1 ISA

L<Plack::Middleware>

=head1 METHODS

=head2 C<prepare_app>

=head2 C<call($env)>

=head1 INHERITED METHODS

=head2 C<wrap($app, @args)>

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
