use Mojolicious::Lite;

# A 5 second cron line example. This is supported by Algorithm::Cron
#  syntax although not recommended unless you are sure it will not cause
# problems with Mojolicious singleton IOLoop
#
# Here it is fine, just for demostration purposes
plugin Cron => (
  '*/5 * * * * *' => sub {
    app->log->info("Cron from $$");
  }
);

get '/' => {data => 'Hello World!'};

app->start;
