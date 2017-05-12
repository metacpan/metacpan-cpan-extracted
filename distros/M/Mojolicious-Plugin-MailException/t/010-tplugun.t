#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests    => 30;
use Encode qw(decode encode decode_utf8);

my @elist;
my @mails;


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Test::Mojo';
    require_ok 'Mojolicious';
    require_ok 'MIME::Lite';
    require_ok 'MIME::Words';
    require_ok 'Mojolicious::Plugin::MailException';
}


my $t = Test::Mojo->new('MpemTest');

# Workaround for newer Mojolicious Versions so the Namespace stays the same
$t->app->routes->namespaces(['MpemTest'])
    if $t->app->can('routes') and $t->app->routes->can('namespaces');

$t->get_ok('/')
  ->status_is(200)
  ->content_is('Hello');

$t->get_ok('/crash')
  ->status_is(500)
  ->content_like(qr{^Exception: die marker1 outside eval})
  ->content_like(qr{Exception Line:     die "die marker1 outside eval"; ### die marker1\n$});



is  scalar @elist, 1, 'one caugth exception';
my $e = shift @elist;


like $e->message, qr{^die marker1 outside eval}, 'text of message';
like $e->line->[1], qr{^    die "die marker1 outside eval"; ### die marker1$}, 'line';

is scalar @mails, 1, 'one prepared mail';
my $m = shift @mails;


# note decode_utf8 $t->tx->res->to_string;
# note decode_utf8 $m->as_string;

note decode_utf8 $m->as_string if $ENV{SHOW};

$m->send if $ENV{SEND};

isa_ok $m => 'MIME::Lite';
$m = $m->as_string;

like $m, qr{^Stack}m, 'Stack';
like $m, qr{^Content-Disposition:\s*inline}m, 'Content-Disposition';

@mails = ();
$t->get_ok('/crash_sig')
  ->status_is(500)
  ->content_like(qr{^Exception: die marker2 sig})
  ->content_like(qr{Exception Line:     die "die marker2 sig"; ### die marker2\n$});

is scalar @mails, 1, 'one prepared mail';
$m = shift @mails;

# note decode_utf8 $m->as_string;

@mails = ();
$t -> get_ok('/crash_sub')
   -> status_is(500)
   -> content_like(qr{^Exception: mail exception marker3})
   -> content_like(qr{Exception Line:.*?mail_exception.".*?### die marker3\n$})
;

# couldn get thi to work:
#  ->content_like(qr!Exception Line:    \$_[0]->mail_exception("mail exception marker3", { 'x-test' => 123 });  ### die marker3!);

is scalar @mails, 1, 'one prepared mail';
$m = shift @mails;

like $m->header_as_string, qr{^X-Test:\s*123$}m, 'Additional header';

package MpemTest::Ctl;
use Mojo::Base 'Mojolicious::Controller';

sub hello {
     $_[0]->render(text => 'Hello');
}

sub crash {
    eval {
        die "die marker1 inside eval";
    };

    die "die marker1 outside eval"; ### die marker1
}

sub crash_sig {
    local $SIG{__DIE__} = sub {
        die $_[0];
    };

    die "die marker2 sig"; ### die marker2
}

sub crash_sub {
    $_[0]->mail_exception("mail exception marker3", { 'x-test' => 123 });  ### die marker3
}

package MpemTest;
use utf8;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';


sub startup {
    my ($self) = @_;

    $self->secrets(['my secret phrase']);
    $self->mode('development');

	push @{$self->renderer->classes}, 'MpemTest';

    $self->plugin('MailException',
        send => sub {
            my ($m, $e) = @_;
            push @elist => $e;
            push @mails => $m;
        },
        $ENV{FROM}  ? ( from => $ENV{FROM} ) : (),
        $ENV{TO}    ? ( to   => $ENV{TO} ) : (),
        subject => 'Случилось страшное (тест)!',
        headers => {},
    );

    my $r = $self->routes;

    $r->get('/')->to('ctl#hello');
    $r->get('/crash')->to('ctl#crash');
    $r->get('/crash_sig')->to('ctl#crash_sig');
    $r->get('/crash_sub')->to('ctl#crash_sub');
}

1;

__DATA__

@@ exception.html.ep
Exception: <%== $exception %>
Exception Line: <%== $exception->line->[1] %>
