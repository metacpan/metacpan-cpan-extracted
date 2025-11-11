package NVMPL::Shell::PowerShell;
use strict;
use warnings;
use feature 'say';
use NVMPL::Utils qw(log_info);

# ---------------------------------------------------------
# Update PATH (used for shell printouts, rarely called)
# ---------------------------------------------------------
sub update_path {
    my ($bin_path) = @_;
    say '$Env:PATH = "' . $bin_path . ';$Env:PATH"';
}

# ---------------------------------------------------------
# Initialization snippet for PowerShell profile
# ---------------------------------------------------------
sub init_snippet {
    return <<'EOS';
# nvm-pl managed Node.js path (Windows-aware)
$CurrentNodePath = "$env:USERPROFILE\.nvm-pl\install\versions\current"

if (Test-Path $CurrentNodePath) {
    # Look for nested node-v*-win-x64 folder (typical Windows layout)
    $NodeFolder = Get-ChildItem $CurrentNodePath -Directory -Filter "node-v*-win-x64" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($NodeFolder) {
        $NodeBin = $NodeFolder.FullName
    } else {
        $NodeBin = $CurrentNodePath
    }

    if (-not ($env:PATH -like "*$NodeBin*")) {
        $env:PATH = "$NodeBin;" + $env:PATH
    }
}
EOS
}

1;
