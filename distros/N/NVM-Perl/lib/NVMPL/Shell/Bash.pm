package NVMPL::Shell::Bash;
use strict;
use warnings;
use feature 'say';
use NVMPL::Utils qw(log_info);

sub update_path {
    my ($bin_path) = @_;
    say "export PATH=\"$bin_path:\$PATH\"";
}

sub init_snippet {
    return <<'BASH';
if [ -d "$HOME/.nvm-pl/install/versions/current/bin" ]; then
    export PATH="$HOME/.nvm-pl/install/versions/current/bin:$PATH"
fi
BASH
}

1;