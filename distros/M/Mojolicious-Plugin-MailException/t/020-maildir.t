#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests    => 17;
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
    use_ok 'File::Temp', 'tempdir';
    require_ok 'Mojolicious::Plugin::MailException';
}


my $dir = tempdir CLEANUP => 1;


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
  ->content_like(qr/Exception Line:     die "die marker1 outside eval"; ### die marker1\n$/);


my ($mail) = glob "$dir/*";

like $mail, qr{^$dir/\d+\.\d+$}, 'file created';
my $fh;
ok open($fh, '<:raw', $mail), 'file opened';
my $data = do { local $/; <$fh> };

like $data => qr{^From:}m, 'From';
like $data => qr{^To:}m, 'To';



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
        maildir     => $dir,
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

