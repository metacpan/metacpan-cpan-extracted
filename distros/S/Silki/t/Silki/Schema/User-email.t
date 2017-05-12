use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';

use Silki::Test::Email qw( clear_emails test_email );
use Silki::Test::RealSchema;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $user1 = Silki::Schema::User->insert(
    display_name  => 'Joe Smith',
    email_address => 'joe@example.com',
    password      => 'foo',
    user          => Silki::Schema::User->SystemUser(),
);

my $user2 = Silki::Schema::User->insert(
    display_name  => 'Bjork',
    email_address => 'bjork@example.com',
    password      => 'foo',
    user          => Silki::Schema::User->SystemUser(),
);

my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

$user1->send_invitation_email(
    wiki   => $wiki,
    sender => $user2,
);

test_email(
    {
        From => q{"Bjork" <bjork@example.com>},
        To   => q{"Joe Smith" <joe@example.com>},
        Subject =>
            qr{^\QYou have been invited to join the First Wiki wiki at \E.+},
    },
    qr{<p>\s+
       \QYou have been invited to join the First Wiki wiki.\E
       \s+
       \QSince you already have a user account at \E\S+?\Q, you can <a href="http://\E\S+?\Q/wiki/first-wiki">visit the wiki right now</a>.\E
       \s+</p>
       .+?
       <p>\s+
       \QSent by Bjork\E
       \s+</p>
      }xs,
    qr{\QYou have been invited to join the First Wiki wiki. Since you already have\E
       \s+
       \Qa user account at \E\S+?\Q, you can visit the wiki right\E
       \s+
       \Qnow (http://\E\S+?\Q/wiki/first-wiki).\E
       \s+
       \QSent by Bjork\E
      }xs,
);

clear_emails();

my $user3 = Silki::Schema::User->insert(
    display_name        => 'Colin',
    email_address       => 'colin@example.com',
    password            => 'foo',
    requires_activation => 1,
    user                => Silki::Schema::User->SystemUser(),
);

$user3->send_activation_email( sender => Silki::Schema::User->SystemUser() );

test_email(
    {
        From => qr{\Q"System User" <silki-system-user@\E.+?\Q>},
        To   => q{"Colin" <colin@example.com>},
        Subject =>
            qr{^\QActivate your user account on the \E\S+\Q server},
    },
    qr{<p>\s+
       \QYou have created a user account on the \E\S+\Q server. You must <a href="http://\E\S+?/user/\d+/confirmation/.+?\Q">activate your user account</a> before you can log in.\E
       \s+</p>
       \s+
       \Q</body>\E
      }xs,
    qr{\QYou have created a user account on the \E\S+\Q server. You\E
       \s+
       \Qmust activate your user account (http://\E\S+?\)
       \s+
       \Qbefore you can log in.\E
       \s+$
      }xs,
);

clear_emails();

$user3->send_activation_email(
    wiki   => $wiki,
    sender => $user2,
);

test_email(
    {
        From => q{"Bjork" <bjork@example.com>},
        To   => q{"Colin" <colin@example.com>},
        Subject =>
            qr{^\QYou have been invited to join the First Wiki wiki at \E.+},
    },
    qr{<p>\s+
       \QYou have been invited to join the First Wiki wiki.\E
       \s+
       \QOnce you <a href="http://\E\S+?/user/\d+/confirmation/.+?\Q">activate your user account</a>, you will be a member of the wiki.\E
       \s+</p>
       .+?
       <p>\s+
       \QSent by Bjork\E
       \s+</p>
      }xs,
    qr{\QYou have been invited to join the First Wiki wiki. Once you activate your\E
       \s+
       \Quser account (http://\E\S+?\),
       \s+
       \Qyou will be a member of the wiki.\E
       \s+
       \QSent by Bjork\E
      }xs,
);

like(
    exception {
        $user3->send_invitation_email(
            sender => $user2,
        );
    },
    qr/\QCannot send an invitation email without a wiki./,
    'cannot send an invitation email without a wiki'
);

done_testing();
