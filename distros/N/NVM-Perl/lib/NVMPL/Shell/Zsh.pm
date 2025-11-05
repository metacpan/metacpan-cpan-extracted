package NVMPL::Shell::Zsh;
use strict;
use warnings;
use feature 'say';
use NVMPL::Utils qw(log_info);

sub update_path {
    my ($bin_path) = @_;
    say "export PATH=\"$bin_path:\$PATH\"";
}

sub init_snippet {
    return <<'ZSH';
if [ -d "$HOME/.nvm-pl/install/versions/current/bin" ]; then
    export PATH="$HOME/.nvm-pl/install/versions/current/bin:$PATH"
fi
ZSH
}

1;