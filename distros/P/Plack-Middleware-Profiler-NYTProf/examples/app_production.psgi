use Mojolicious::Lite;
use Plack::Builder;

BEGIN {
    use Plack::Middleware::Profiler::NYTProf;
    $ENV{NYTPROF} = 'start=no:sigexit=int:stmts=0:addpid=0';
    Plack::Middleware::Profiler::NYTProf->preload;
}

get '/' => 'index';

builder {
  enable "Profiler::NYTProf",
    profiling_result_dir => sub { '/tmp' },
    # Don't generate HTML report for production. Generate only NYTProf profiling output.
    enable_reporting     => 0,
    # Do sampling, select some processes or select some paths using enable_profile callbak.
    enable_profile       => sub { $$ % 2 == 0 }
    ;
 
  app->start;
};

__DATA__

@@ index.html.ep
<html><body>Hello World</body></html>
