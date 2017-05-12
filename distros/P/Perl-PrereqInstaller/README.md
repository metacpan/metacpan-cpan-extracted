[![Build Status](https://travis-ci.org/mfcovington/Perl-PrereqInstaller.svg?branch=master)](https://travis-ci.org/mfcovington/Perl-PrereqInstaller) [![Coverage Status](https://coveralls.io/repos/mfcovington/Perl-PrereqInstaller/badge.png?branch=master)](https://coveralls.io/r/mfcovington/Perl-PrereqInstaller?branch=master)

# NAME

Perl::PrereqInstaller - Install missing modules explicitly
loaded in Perl files

# VERSION

Version 0.6.2

# SYNOPSIS

Scan, Install, and report results via command line:

    install-perl-prereqs lib/ bin/

Scan files and Install modules via script:

    use Perl::PrereqInstaller;
    my $installer = Perl::PrereqInstaller->new;
    $installer->scan( @files, @directories );
    $installer->cpanm;

    $installer->quiet(1);

Access and report scan/install status via script:

    my @not_installed  = $installer->not_installed;
    my @prev_installed = $installer->previously_installed;

    my @newly_installed = $installer->newly_installed;
    my @failed_install  = $installer->failed_install;

    my @scan_errors   = $installer->scan_errors;
    my %scan_warnings = $installer->scan_warnings;

    $installer->report;

# DESCRIPTION

Extract the names of the modules explicitly loaded in Perl files,
check which modules are not installed, and install the missing
modules. Since this module relies on
[Perl::PrereqScanner](https://metacpan.org/pod/Perl::PrereqScanner) to statically identify
dependencies, it has the same caveats regarding identifying loaded
modules. Therefore, modules that are loaded dynamically (e.g.,
`eval "require $class"`) will not be identified as dependencies or
installed.

## Command-line tool

Command-line usage is possible with `install-perl-prereqs`
(co-installed with this module).

    install-perl-prereqs FILE_OR_DIR [FILE_OR_DIR ...]
        -h, --help
        -d, --dry-run
        -q, --quiet
        -v, --version

## Methods for scanning files and installing modules

- new

    Initializes a new Perl::PrereqInstaller object.

- scan( FILES and/or DIRECTORIES )

    Analyzes all specified FILES (regardless of file type) and Perl files
    (.pl/.pm/.cgi/.psgi/.t) within specified DIRECTORIES to generate a
    list of modules explicitly loaded and identify which are not
    currently installed. Subsequent use of `scan()` will update the
    lists of not yet installed and previously installed modules.

- cpanm

    Use cpanm to install loaded modules that are not currently installed.

- quiet( BOOLEAN )

    Set quiet mode to on/off (default: off). Quiet mode turns off most
    of the output. If BOOLEAN is not provided, this method returns quiet
    mode's current state.

## Methods for accessing and reporting scan/install status

- not\_installed

    Returns an alphabetical list of unique modules that were explicitly
    loaded, but need to be installed. Modules are removed from this list
    upon installation.

- previously\_installed

    Returns an alphabetical list of unique installed modules that were
    explicitly loaded.

- newly\_installed

    Returns an alphabetical list of unique modules that were
    explicitly loaded, needed to be installed, and were successfully
    installed.

- failed\_install

    Returns an alphabetical list of unique modules that were
    explicitly loaded and needed to be installed, but whose installation
    failed.

- scan\_errors

    Returns a list of files that produced a parsing error
    when being scanned. These files are skipped.

- scan\_warnings

    Returns a hash of arrays containing the names of files (the keys) that
    raised warnings (the array contents) during parsing. These warnings
    are likely indicative of issues with the code in the parsed files
    rather than actual parsing problems.

- report

    Write (to STDOUT) a summary of scan/install results. By default, all
    status methods below (except `scan_warnings`) are summarized. To
    customize the contents of `report()`, pass it an anonymous hash:

        $installer->report(
            {   'not_installed'        => 0,
                'previously_installed' => 0,
                'newly_installed'      => 1,
                'failed_install'       => 1,
                'scan_errors'          => 0,
                'scan_warnings'        => 0,
            }
        );

# SEE ALSO

[Perl::PrereqScanner](https://metacpan.org/pod/Perl::PrereqScanner),
[App::cpanoutdated](https://metacpan.org/pod/App::cpanoutdated),
[lib::xi](https://metacpan.org/pod/lib::xi),
[Module::Extract::Use](https://metacpan.org/pod/Module::Extract::Use)

The command-line tool `scan-perl-prereqs` gets installed together
with [Perl::PrereqScanner](https://metacpan.org/pod/Perl::PrereqScanner). The basic
functionality of `install-perl-prereqs` can be recreated with
`scan-perl-prereqs | cpanm`; however, `install-perl-prereqs` comes
with a few bonuses. These include:

- Better error handling

    In the event of parse errors, `scan-perl-prereqs` dies even if there
    are files remaining to be scanned, whereas `install-perl-prereqs`
    logs the error and scans the next file.

- Summary report

    `install-perl-prereqs` provides a summary of scan and install
    results.

- No unexpected updates

    While `scan-perl-prereqs | cpanm` attempts to update all
    previously-installed modules found in a scan, `install-perl-prereqs`
    only attempts to install modules if they are not yet installed.

    Perhaps a better way to update installed CPAN modules is to use
    [cpan-outdated](https://metacpan.org/pod/cpan-outdated) (from
    [App::cpanoutdated](https://metacpan.org/pod/App::cpanoutdated)):

        cpan-outdated -p | cpanm

# SOURCE AVAILABILITY

The source code is on Github:
[https://github.com/mfcovington/Perl-PrereqInstaller](https://github.com/mfcovington/Perl-PrereqInstaller)

# AUTHOR

Michael F. Covington, <mfcovington@gmail.com>

# BUGS

Please report any bugs or feature requests at
[https://github.com/mfcovington/Perl-PrereqInstaller/issues](https://github.com/mfcovington/Perl-PrereqInstaller/issues).

# INSTALLATION

To install this module from GitHub using cpanm:

    cpanm git@github.com:mfcovington/Perl-PrereqInstaller.git

Alternatively, download and run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

# SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Perl::PrereqInstaller

# LICENSE AND COPYRIGHT

Copyright 2014 Michael F. Covington.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
