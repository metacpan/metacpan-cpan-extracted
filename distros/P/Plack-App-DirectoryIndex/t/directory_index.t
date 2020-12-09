use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::DirectoryIndex;

my $handler = Plack::App::DirectoryIndex->new({
  root => 't/share',
  dir_index => '',
});


my %test = (
  client => sub {
    my $cb  = shift;

    my $desc = 'Dir index turned off';

    my $res = $cb->(GET "/");
    is $res->code, 200, "$desc - response code is 200";
    like $res->content, qr/Index of \//, "$desc: content is correct";
  },
  app => $handler,
);

test_psgi %test;

$handler = Plack::App::DirectoryIndex->new({
  root => 't/share',
  dir_index => 'index.html',
});

%test = (
  client => sub {
    my $cb  = shift;

    my $desc = 'Dir index defined';

    open my $fh, ">", "t/share/index.html" or die $!;
    print $fh "<html>\n</html>";
    close $fh;
  
    my $res = $cb->(GET "/");
    is $res->code, 200, "$desc - response code is 200";
    is $res->content, "<html>\n</html>", "$desc - content is correct";
  
    unlink "t/share/index.html";
  },
  app => $handler,
);

test_psgi %test;

$handler = Plack::App::DirectoryIndex->new({
  root => 't/share',
  dir_index => 'random.html',
});

%test = (
  client => sub {
    my $cb  = shift;

    my $desc = 'Non-standard dir index defined';

    open my $fh, ">", "t/share/random.html" or die $!;
    print $fh "<html>random\n</html>";
    close $fh;
    open my $fh2, ">", "t/share/index.html" or die $!;
    print $fh2 "<html>\n</html>";
    close $fh2;
  
    my $res = $cb->(GET "/");
    is $res->code, 200, "$desc - response code is 200";
    is $res->content, "<html>random\n</html>", "$desc - content is correct";
  
    unlink "t/share/index.html";
    unlink "t/share/random.html";
  },
  app => $handler,
);

test_psgi %test;
$handler = Plack::App::DirectoryIndex->new({
  root => 't/share',
});

%test = (
  client => sub {
    my $cb  = shift;
  
    my $desc = 'Default dir index';

    open my $fh, ">", "t/share/index.html" or die $!;
    print $fh "<html>\n</html>";
    close $fh;
  
    my $res = $cb->(GET "/");
    is $res->code, 200, "$desc - response code is 200";
    is $res->content, "<html>\n</html>", "$desc - content is correct";
  
    unlink "t/share/index.html";
  },
  app => $handler,
);

test_psgi %test;
done_testing;
