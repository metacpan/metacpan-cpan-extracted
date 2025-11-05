package NVMPL::Shell::PowerShell;
use strict;
use warnings;
use feature 'say';
use NVMPL::Utils qw(log_info);

sub update_path {
    my ($bin_path) = @_;
    say '$Env:PATH = "' . $bin_path . ';$Env:PATH"';
}

sub init_snippet {
    return <<'PS1';
if (Test-Path "$HOME\.nvm-pl\install\versions\current\bin") {
    $Env:PATH = "$HOME\.nvm-pl\install\versions\current\bin;" + $Env:PATH
}
PS1
}

1;