package Net::Amazon::MechanicalTurk::OSUtil;

our $VERSION = '1.00';

sub homeDirectory {
    my $homeDir;
    eval {
        # Looks up home directory for effective user id
        $homeDir = [getpwuid($>)]->[7];
    };
    if ($@) {
        # getpwuid doesn't seem to work on ActivePerl
        # Try using the Windows API to get the home directory.
        eval {
            require Win32;
            $homeDir = Win32::GetFolderPath(Win32::CSIDL_PROFILE());
        };
    }
    return $homeDir;
}

return 1;
