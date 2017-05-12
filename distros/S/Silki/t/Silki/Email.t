use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Silki::Test::Email qw( clear_emails test_email );
use Silki::Test::FakeSchema;

use Cwd qw( abs_path );
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Silki::Config;

BEGIN {
    my $config = Silki::Config->instance();

    $config->_set_share_dir( dir( abs_path('t/share') ) );
    $config->_set_cache_dir( dir( tempdir( CLEANUP => 1 ) ) );
}

use Silki::Email;

{

    package Silki::Schema::User;

    no warnings 'redefine';

    my $user = Silki::Schema::User->new(
        user_id        => 42,
        display_name   => 'System User',
        username       => 'system-user',
        email_address  => 'system-user@example.com',
        password       => '*disabled*',
        is_system_user => 1,
        _from_query    => 1,
    );

    sub SystemUser {$user}
}

Silki::Email::send_email(
    from            => 'foo@example.com',
    to              => 'bar@example.com',
    subject         => 'Test email',
    template        => 'test',
    template_params => { uri => 'http://example.com' },
);

my $version = $Silki::Email::VERSION || 'from working copy';
test_email(
    {
        From         => 'foo@example.com',
        To           => 'bar@example.com',
        Subject      => 'Test email',
        'Message-ID' => qr/^<.+>$/,
        'X-Sender'   => "Silki version $version",
    },
    qr{<p>
       \s+
       \QThe user can pass a <a href="http://example.com">uri</a>.\E
       \s+
       </p>}x,
    qr{\QThe user can pass a uri (http://example.com).\E},
);

clear_emails();

Silki::Email::send_email(
    from     => 'foo@example.com',
    to       => 'bar@example.com',
    subject  => 'Test email',
    template => 'test',
);

test_email(
    {},
    qr{<p>
       \s+
       \QSome random content goes here.\E
       \s+
       </p>
       \s*
       \z}x,
    qr{\QSome random content goes here.\E\s*\z},
);

done_testing();
