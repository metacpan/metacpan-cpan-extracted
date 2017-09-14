package Plack::Middleware::QueryCounter::DBI;
use strict;
use warnings;
use utf8;

use parent 'Plack::Middleware';
use DBIx::Tracer;

use Plack::Util::Accessor qw/prefix/;

sub prepare_app {
    my $self = shift;

    $self->{__prefix} = $self->prefix || 'X-QueryCounter-DBI';
}

sub call {
    my ($self, $env) = @_;

    my $stats = {
        total => 0,
        read  => 0,
        write => 0,
        other => 0,
    };

    my $tracer = DBIx::Tracer->new(
        sub{
            my %args = @_;
            _callback(\%args, $stats);
        }
    );
    my $res = $self->app->($env);

    # add header to response
    return Plack::Util::response_cb($res, sub {
        my $res = shift;
        Plack::Util::header_set($res->[1], $self->{__prefix} . '-Total', $stats->{total});
        Plack::Util::header_set($res->[1], $self->{__prefix} . '-Read',  $stats->{read});
        Plack::Util::header_set($res->[1], $self->{__prefix} . '-Write', $stats->{write});
        Plack::Util::header_set($res->[1], $self->{__prefix} . '-Other', $stats->{other});
    });
}

sub _callback {
    my ($args, $stats) = @_;
    my $inputs = $args->{sql};
    $inputs =~ s{/\*(.*)\*/}{}g;

    my @sqls = split /;/, $inputs;

    for my $sql (@sqls) {
        $sql =~ s/^\s*(.*?)\s*$/$1/;
        $stats->{total}++;

        if ($sql =~ /^SELECT/i) {
            $stats->{read}++;
        } elsif ($sql =~ /^(INSERT|UPDATE|DELETE)/i) {
            $stats->{write}++;
        } else {
            $stats->{other}++;
        }
    }
}

1;

__END__

=head1 NAME

Plack::Middleware::QueryCounter::DBI - DBI query counter per request middleware

=head1 SYNOPSIS

Enable this middleware using Plack::Builder.

    use MyApp;
    use Plack::Builder;

    my $app = MyApp->psgi_app;

    builder {
        enable 'QueryCounter::DBI';
        $app;
    };

You can specify HTTP header using prefix option.

    builder {
        enable 'QueryCounter::DBI', prefix => 'X-MyQueryCounter';
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::QueryCounter::DBI is a middleware to count SQL query
per each HTTP request. Count result outputs on HTTP header.

The counted quieries classify read, write or other query.

You'll get following HTTP headers.

X-QueryCounter-DBI-Total: 20
X-QueryCounter-DBI-Read:  16
X-QueryCounter-DBI-Write:  4
X-QueryCounter-DBI-Other:  0

Then, you can write to access log using nginx.

    log_format ltsv   'host:$remote_addr\t'
                      'user:$remote_user\t'
    (snip)
                      'user_agent:$http_user_agent\t'
                      'query_total:$sent_http_x_querycounter_dbi_total\t'
                      'query_read:$sent_http_x_querycounter_dbi_read\t'
                      'query_write:$sent_http_x_querycounter_dbi_write\t'
                      'query_other:$sent_http_x_querycounter_dbi_other\t';

LTSV is Labeled Tab-separated Values, see L<http://ltsv.org/>

Additionally, I recommend to remove these header for end-user response.

    location / {
        proxy_hide_header 'X-QueryCounter-DBI-Total';
        proxy_hide_header 'X-QueryCounter-DBI-Read';
        proxy_hide_header 'X-QueryCounter-DBI-Write';
        proxy_hide_header 'X-QueryCounter-DBI-Other';

        proxy_pass http://backend;
    }

=head1 SEE ALSO

L<Plack> L<Plack::Builder>

=head1 LICENSE

Copyright (C) Masatoshi Kawazoe (acidlemon).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masatoshi Kawazoe (acidlemon) E<lt>acidlemon@cpan.orgE<gt>

=cut

