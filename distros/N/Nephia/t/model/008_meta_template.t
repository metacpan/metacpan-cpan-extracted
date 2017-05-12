use strict;
use warnings;
use utf8;
use Test::More;
use Nephia::MetaTemplate;

my $data = join('', (<DATA>));

subtest default => sub {
    my $meta = Nephia::MetaTemplate->new;
    my $expect = <<EOF;
? my \$arg = shift;
<html>
<head>
<title><?= \$arg->{title} ?></title>
</head>
</html>
<body>
  <h1>Access to value: <?= \$arg->{title} ?></h1><h2>Access to nested value: <?= \$arg->{author}->{name} ?></h2>
</body>
</html>
EOF
    is $meta->process($data), $expect;
};

subtest tterse => sub {
    my $meta = Nephia::MetaTemplate->new(
        tag           => '[% ... %]',
        arrow         => '.',
        argument      => '...',
        replace_table => [],
    );
    my $expect = <<EOF;
<html>
<head>
<title>[% title %]</title>
</head>
</html>
<body>
  <h1>Access to value: [% title %]</h1><h2>Access to nested value: [% author.name %]</h2>
</body>
</html>
EOF
    is $meta->process($data), $expect;
};

done_testing;

1;
__DATA__
<html>
<head>
<title>[= title =]</title>
</head>
</html>
<body>
  <h1>Access to value: [= title =]</h1><h2>Access to nested value: [= author.name =]</h2>
</body>
</html>
