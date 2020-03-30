use utf8;
use warnings;
use strict;

BEGIN {
    unshift @INC, "$ENV{'LAMBDA_TASK_ROOT'}/lib/","$ENV{'LAMBDA_TASK_ROOT'}/extlocal/lib/perl5/";
};

use Mojo::Server::AWSLambda;
use Path::Tiny;

my $server = Mojo::Server::AWSLambda->new;
my $script = Path::Tiny->new(__FILE__)->sibling('app.pl')->stringify;
$server->load_app($script);

my $func = $server->run;
sub handle {
    my $payload = shift;
    return $func->($payload);
}

1;

