use Mojolicious::Lite;
plugin 'Memorize';

any '/' => 'index';

any '/reset' => sub {
  my $self = shift;
  $self->memorize->expire('access');
  $self->redirect_to('/');
};

app->start;

__DATA__

@@ index.html.ep

%= memorize access => { expires => 0 } => begin
  This page was memorized on 
  %= scalar localtime
% end

