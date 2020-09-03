package Mnet::Version;

=head1 NAME

Mnet::Version - Returns Mnet version information

=head1 SYNOPSIS

    $info = Mnet::Version::info();

=head1 DESCRIPTION

Mnet::Version makes available an Mnet::Version::info function that can be used
by other scripts and modules.

 our $VERSION = "1.00";

User scripts can use the above command to declare a version number string that
will be detected by this module and included in its output.

=head1 FUNCTIONS

Mnet::Version implements the functions listed below.

=cut

# required modules
use warnings;
use strict;
use Config;
use Cwd;
use POSIX;
use Mnet;



sub info {

=head2 Mnet::Version::info

    $info = Mnet::Version::info()

Output multiple lines of information about the current script, Mnet modules,
and operating system. This is used by Mnet::Opts::Cli and Mnet::Log.

=cut

    # note script name, without path
    my $script_name = $0;
    $script_name =~ s/^.*\///;

    # note path to Mnet modules
    my $mnet_path = $INC{"Mnet/Version.pm"};
    $mnet_path =~ s/\/Mnet\/Version\.pm$//;

    # note path of currently running perl executable
    my $perl_path = $Config{perlpath} // "";

    # note posix uname
    my @uname = POSIX::uname();
    my $uname = lc($uname[0]." ".$uname[2]);

    # note current working directory
    my $cwd_path = Cwd::getcwd();

    # init output version info string, and sprintf pad string to align outputs
    my ($info, $spad) = ("", "15s");
    $spad = "1s =" if caller eq "Mnet::Log";

    # output caller script version if known, no blank line in Mnet::Log --debug
    my $script_version = $main::VERSION // "?";
    $info .= sprintf("%-$spad $script_version\n", "$script_name");
    $info .= "\n" if caller ne "Mnet::Log";

    # output mnet, perl, and os version, no blank line in Mnet::Log --debug
    $info .= sprintf("%-$spad $Mnet::VERSION\n", "Mnet version");
    $info .= sprintf("%-$spad $^V\n",        "perl version");
    $info .= sprintf("%-$spad $uname\n",     "system uname");
    $info .= "\n" if caller ne "Mnet::Log";

    # output path information, no blank line in Mnet::Log --debug
    $info .= sprintf("%-$spad $0\n",         "exec path");
    $info .= sprintf("%-$spad $perl_path\n", "perl path");
    $info .= sprintf("%-$spad $mnet_path\n", "Mnet path");
    $info .= sprintf("%-$spad $cwd_path\n", "cwd path");

    # finished Mnet::Version::info, return info string
    return $info;
}



=head1 SEE ALSO

L<Mnet>

=cut

# normal end of package
1;

