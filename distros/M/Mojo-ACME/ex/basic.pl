use Mojolicious::Lite;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

#app->config(acme => {});
app->secrets(['s3cr3t']);

plugin 'ACME';

app->start;

