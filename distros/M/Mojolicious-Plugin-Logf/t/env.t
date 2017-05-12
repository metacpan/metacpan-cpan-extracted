use Mojo::Base -base;
use Test::More;
BEGIN { $ENV{MOJO_LOGF_UNDEF} = 'not defined'; }
use Mojolicious::Plugin::Logf;
my $logf = Mojolicious::Plugin::Logf->new;
is_deeply [$logf->flatten(undef)], ['not defined'], 'MOJO_LOGF_UNDEF';
done_testing;
