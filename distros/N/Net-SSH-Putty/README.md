# net-ssh-putty
Perl module to interact with Putty `plink` program on Microsoft Windows OS.

Inspiration from this module came from the necessity to have non-interactive SSH session working on Microsoft Windows. Initially this was attempted with `Net::SSH::Any` Perl module (using `Net::SSH::Any::Backend::Plink_Cmd`) with a certain degree of success, but as soon things get more complicated (like creating multiple SSH sessions using threads) sessions started failing without further explanation or error messages.

The combination of Microsoft Windows, Perl and SSH is historically problematic too.

Since the author didn't need any interaction within the SSH sessions (like executing a command, reading the output and taking some conditional action), a simple solution was to execute the `plink.exe` executable with a set of commands already defined.

Be sure to read the POD from the module (`Net::SSH::Putty`) for more details.
