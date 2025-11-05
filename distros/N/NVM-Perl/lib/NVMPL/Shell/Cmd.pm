package NVMPL::Shell::Cmd;
use strict;
use warnings;
use feature 'say';
use NVMPL::Utils qw(log_info);

sub update_path {
    my ($bin_path) = @_;
    say "set PATH=$bin_path;%PATH%";
}

sub init_snippet {
    return <<'CMD';
:: nvm-pl cmd.exe integration
if exists "%USERPROFILE%\.nvm-pl\install\versions\current\bin" (
    set PATH=%USERPROFILE%\.nvm-pl\install\versions\current\bin;%PATH%
)
CMD
}

1;