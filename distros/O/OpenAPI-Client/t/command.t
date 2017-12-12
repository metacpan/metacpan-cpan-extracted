use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;
use File::Temp qw(tempfile);
use Mojolicious::Command::openapi;

my $cmd = Mojolicious::Command::openapi->new;
my @said;

Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _say  => sub { push @said, @_ });
Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _warn => sub { push @said, @_ });

like $cmd->description, qr{Perform Open API requests}, 'description';
like $cmd->usage, qr{APPLICATION openapi SPECIFICATION OPERATION}, 'usage';

eval { $cmd->run };
like $@, qr{APPLICATION openapi SPECIFICATION OPERATION}, 'no arguments';

@said = ();
$cmd->run(path('t', 'spec.json'));
like $said[0], qr{Operations for http://localhost/v1}, 'validated spec from command line';
like $said[1], qr{^listPets$}m, 'validated spec from command line';

@said = ();
$cmd->run(path('t', 'spec.json'), -I => 'listPets');
like "@said", qr{pet response}, 'information about operation';

@said = ();
$cmd->run(path('t', 'spec.json'), -I => 'unknown');
like "@said", qr{Could not find}, 'no information about operation';

@said = ();
my ($fh, $filename) = tempfile;
close $fh;
# this is because under Docker, STDIN is !-t, readable immediately,
#  gives EOF. This simulates that
open STDIN, '<', $filename;
eval { $cmd->run(path('t', 'spec.json'), 'listPets') };
is $@, '';
like "@said", qr{Missing property}, 'missing property';

@said = ();
$cmd->run(path('t', 'spec.json'), 'listPets', '-v');
like "@said", qr{400 Bad Request}, 'verbose';

@said = ();
$cmd->run(path('t', 'spec.json'), 'listPets', '/errors/0/path');
like "@said", qr{^/type}, 'json path';

done_testing;
