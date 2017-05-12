use Mojolicious::Lite;

plugin 'RevealJS';

helper line => sub { shift->tag(span => class => slabtext => @_ ) };

my $init = { transition => 'none', progress => 0 };
any '/' => { template => 'mytalk', layout => 'revealjs', init => $init };

app->start;

