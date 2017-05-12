#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::MailArchive';
}

New_message: {
    my $r = Socialtext::Resting::Mock->new;
    my $ma = Socialtext::MailArchive->new(rester => $r);
    isa_ok $ma, 'Socialtext::MailArchive';
    my %msg = fake_mail();
    $r->response->set_always('code', 404);
    $ma->archive_mail( $msg{raw} );
    $r->response->set_always('code', 200);
    is $r->get_page('Test Mail'), <<EOT;
{include [$msg{page}]}
EOT
    is $r->get_page($msg{page}), $msg{lean};
    is_deeply [ $r->get_pagetags($msg{page}) ], 
              ['message', 'Subject: Test Mail'];
}

Reply_message: {
    my $r = Socialtext::Resting::Mock->new;
    $r->response->set_always('code', 404);
    my $ma = Socialtext::MailArchive->new(rester => $r);
    isa_ok $ma, 'Socialtext::MailArchive';
    my %msg = fake_mail();
    $ma->archive_mail( $msg{raw} );
    is_deeply [ $r->get_pagetags($msg{page}) ], 
              ['message', 'Subject: Test Mail'];

    # hack message into a reply
    my $reply = $msg{raw};
    $reply =~ s/^Subject: /Subject: re: /m;
    my $reply_page = $msg{page};
    s/Mon, 5 Feb/Tue, 6 Feb/ for ($reply, $reply_page);
    $r->response->set_always('code', 200);
    $ma->archive_mail( $reply );
    is $r->get_page('Test Mail'), <<EOT;
{include [$msg{page}]}
----
{include [$reply_page]}
EOT
    is_deeply [ $r->get_pagetags($reply_page) ], 
              ['message', 'Subject: Test Mail'];
}

Reply_message_with_list_header: {
    my $r = Socialtext::Resting::Mock->new;
    $r->response->set_always('code', 404);
    my $ma = Socialtext::MailArchive->new(rester => $r);
    isa_ok $ma, 'Socialtext::MailArchive';
    my %msg = fake_mail();
    $msg{raw} =~ s/^Subject: .+$/Subject: [Foo] Bar/m;
    $ma->archive_mail( $msg{raw} );
    (my $page_title = $msg{page}) =~ s/Test Mail/Bar/;

    # hack message into a reply
    my $reply = $msg{raw};
    $reply =~ s/^Subject: /Subject: re: /m;
    my $reply_page = $page_title;
    s/Mon, 5 Feb/Tue, 6 Feb/ for ($reply, $reply_page);
    $r->response->set_always('code', 200);
    $ma->archive_mail( $reply );
    is $r->get_page('Bar'), <<EOT;
{include [$page_title]}
----
{include [$reply_page]}
EOT
}

Bad_args: {
    eval { Socialtext::MailArchive->new };
    like $@, qr/rester is mandatory/;
}

Subject_with_special_characters: {
    ok 1;
}

Hide_signature: {
    ok 1;
}

sub fake_mail {
    return ( 
        raw => <<'EOT',
From lukec@ruby Mon Feb 05 13:14:39 2007
Received: from lukec by ruby with local (Exim 4.60)
	(envelope-from <lukec@ruby>)
	id 1HEBAT-0005RZ-Rr
	for append@ruby; Mon, 05 Feb 2007 13:14:29 -0800
Date: Mon, 5 Feb 2007 13:14:19 -0800
To: append@ruby
Subject: Test Mail
Message-ID: <20070205211419.GA20922@ruby>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.5.11
From: Luke Closs <lukec@ruby>

awe
EOT
        lean => <<'EOT',
Date: Mon, 5 Feb 2007 13:14:19 -0800
To: append at ruby
Subject: Test Mail
From: Luke Closs <lukec at ruby>

awe
EOT
        page => 'Luke Closs - Test Mail - Mon, 5 Feb 2007 13:14:19 -0800',
    );
}
