use strict;
use warnings;
use 5.008001;
use Test::More;
use Shell::Guess;
use Shell::Config::Generate;

is eval { Shell::Config::Generate->new->shebang('/bin/foo')->generate(Shell::Guess->bourne_shell) }, "#!/bin/foo\n", "shebang = #!/bin/foo";
diag $@ if $@;

is eval { Shell::Config::Generate->new->shebang('/bin/foo')->generate(Shell::Guess->cmd_shell) }, '', "shebang = ''";
diag $@ if $@;

is eval { Shell::Config::Generate->new->shebang->generate(Shell::Guess->bourne_shell) }, "#!/bin/sh\n", "shebang = #!/bin/sh";
diag $@ if $@;

is eval { Shell::Config::Generate->new->shebang->generate(Shell::Guess->c_shell) }, "#!/bin/csh\n", "shebang = #!/bin/csh";
diag $@ if $@;

done_testing;
