package MyTest;

use Mojo::Base 'Test::Mojo';

use Browser::Open;
our $fake_default_browser = 'iceweasel';
Mojo::Util::monkey_patch 'Browser::Open',
  open_browser_cmd => sub { $fake_default_browser };

use Mojolicious;
use Mojo::Util 'dumper';
use Scalar::Util 'blessed';

sub default_browser { $fake_default_browser }

sub with_default_browser {
    my ($t, $br, $code) = @_;
    local $fake_default_browser = $br;
    $code->();
}

sub new {
    my $class = shift;
    my $app = blessed $_[0] && $_[0]->isa('Mojolicious') ? shift : undef;
    my $further_setup = @_ % 2 && ref $_[-1] eq 'CODE' ? pop : sub { };
    my %options = (initial_get => '/dummy', @_);

    state $n;
    $app = Mojolicious->new(moniker => "my_test" . ++$n)->secrets(['seekrit'])
      unless ($app // delete $options{use_lite});

    my $t = $class->SUPER::new($app);
    $app = $t->app;

    my $tx_init;
    $t->ua->max_redirects(1);
    $app->plugin(
        'Loco',
        initial_wait         => 0,
        final_wait           => 0,
        _test_browser_launch => sub {
            $app->{_stats}->{count}++;
            @{ $app->{_stats} }{qw(cmd url)} = my ($cmd, $url) =
              @_;
            if ($options{initial_get}) {
                $tx_init->req->url->$_($url->$_())
                  for (qw(path query fragment));
            }
        },
        @{ $options{plugin_args} // [] }
    );

    $further_setup->($app);
    if ($options{initial_get}) {
        $tx_init = $t->ua->build_tx(GET => $options{initial_get});
        $t->request_ok($tx_init);
    }
    return $t;
}

1;
