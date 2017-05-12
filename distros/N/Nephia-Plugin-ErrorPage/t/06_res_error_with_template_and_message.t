use strict;
use warnings;
use Test::More;
use Nephia::Core;
use Plack::Test;
use HTTP::Request::Common;
use File::Temp 'tempdir';
use File::Spec;

my $tempdir  = tempdir(CLEANUP => 1);
my $viewdir  = File::Spec->catdir($tempdir, 'view');
my $template = File::Spec->catfile($viewdir, 'error.html');
mkdir $viewdir;

open my $fh, '>', $template;
print $fh <<'EOF';
? my $arg = shift;
<html>
<head>
<title>ERROR! <?= $arg->{code} ?> <?= $arg->{message} ?></title>
</head>
<body>
  <h1><?= $arg->{code} ?></h1>
  <p><?= $arg->{message} ?></p>
</body>
</html>
EOF
close $fh;

subtest with_template => sub {
    my $v = Nephia::Core->new(
        appname => 'MyTestApp',
        plugins => [ 
            'View::MicroTemplate' => {
                include_path => [ $viewdir ],
            },
            'ErrorPage', 
        ],
        app => sub { res_error(403, 'Something Wrong') },
    );
    
    my $app = $v->run(ErrorPage => {template => 'error.html'});
    
    test_psgi($app => sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->code, '403';
        like $res->content, qr|<h1>403</h1>|; 
        like $res->content, qr|<p>Something Wrong</p>|;
    });
};

done_testing;

