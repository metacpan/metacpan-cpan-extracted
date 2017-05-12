use Mojolicious::Lite;

plugin 'RevealJS';

any '/' => { template => 'mytalk', layout => 'revealjs' };

app->start;

