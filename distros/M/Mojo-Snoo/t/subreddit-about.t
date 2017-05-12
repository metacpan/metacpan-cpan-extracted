use Mojo::Base -strict;
use Mojo::JSON qw(encode_json);

use Test::More;

use_ok('Mojo::Snoo::Subreddit');

no warnings 'redefine';
local *Mojo::Snoo::Base::_do_request = sub {
    my ($class, $method, $path) = @_;
    my $tx = Mojo::Transaction::HTTP->new();
    $tx->res->code(200);

    diag('TODO test mods and about subroutines as well.');
    my $mock_data = {
        data => {
            banner_img          => '',
            submit_text_html    => undef,
            user_is_banned      => 0,
            id                  => '2qh5e',
            user_is_contributor => 0,
            submit_text         => '',
            display_name        => 'perl',
            header_img =>
              'http://b.thumbs.redditmedia.com/7YFKOvUoQ-goVxxqQfiTzI3P-ZCFEVxbV49K91RdKOA.png',
            description_html =>
              '&lt;!-- SC_OFF --&gt;&lt;div class=\md\&gt;&lt;p&gt;The Perl Programming Language, including both &lt;a href=\http://perl.org\&gt;Perl 5&lt;/a&gt; and &lt;a href=\http://perl6.org/\&gt;Perl 6&lt;/a&gt;.&lt;/p&gt;\n\n&lt;p&gt;Want to learn Perl? See &lt;a href=\http://perl-tutorial.org/\&gt;Perl Tutorials&lt;/a&gt; for great links!&lt;/p&gt;\n\n&lt;p&gt;Want coding help? Asking at &lt;a href=\http://perlmonks.org/\&gt;PerlMonks&lt;/a&gt; or &lt;a href=\http://stackoverflow.com/tags/perl\&gt;Stack Overflow&lt;/a&gt; may give faster assistance.&lt;/p&gt;\n\n&lt;p&gt;Keep up to date with Perl news by subscribing to &lt;a href=\http://perlweekly.com/\&gt;Perl Weekly&lt;/a&gt;.&lt;/p&gt;\n\n&lt;p&gt;Code of Conduct: Be civil or be banned. Anonymity is OK. Dissent is OK. Being rude is not OK.&lt;/p&gt;\n&lt;/div&gt;&lt;!-- SC_ON --&gt;',
            title                     => 'Perl',
            collapse_deleted_comments => 0,
            public_description        => '',
            over18                    => 0,
            public_description_html   => undef,
            icon_size                 => undef,
            icon_img                  => '',
            header_title              => undef,
            description =>
              q@The Perl Programming Language, including both [Perl 5](http://perl.org) and [Perl 6](http://perl6.org/).\n\nWant to learn Perl? See [Perl Tutorials](http://perl-tutorial.org/) for great links!\n\nWant coding help? Asking at [PerlMonks](http://perlmonks.org/) or [Stack Overflow](http://stackoverflow.com/tags/perl) may give faster assistance.\n\nKeep up to date with Perl news by subscribing to [Perl Weekly](http://perlweekly.com/).\n\nCode of Conduct: Be civil or be banned. Anonymity is OK. Dissent is OK. Being rude is not OK.@,
            submit_link_label       => undef,
            accounts_active         => '6',
            public_traffic          => 0,
            header_size             => [qw ( 150 40 )],
            subscribers             => '9513',
            submit_text_label       => undef,
            name                    => 't5_2qh5e',
            created                 => '1201247794',
            url                     => '/r/perl/',
            hide_ads                => 0,
            created_utc             => '1201247794',
            banner_size             => undef,
            user_is_moderator       => 0,
            user_sr_theme_enabled   => 1,
            comment_score_hide_mins => 0,
            subreddit_type          => 'public',
            submission_type         => 'any',
            user_is_subscriber      => 1,
        },
    };

    $tx->res->body(encode_json($mock_data));
    $tx->res;
};

my $cb = 0;

my $mods = Mojo::Snoo::Subreddit->new('perl')->about(
    sub {
        isa_ok(shift, 'Mojo::Message::Response', 'Callback has response object');
        $cb = 1;
    }
);
ok($cb, 'Callback was run');
done_testing();
