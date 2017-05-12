package Perl::PrereqInstaller;
use strict;
use warnings;
use Carp;
use Cwd qw(getcwd abs_path);
use File::Basename;
use File::Find;
use Perl::PrereqScanner;
use Text::Wrap;

=head1 NAME

Perl::PrereqInstaller - Install missing modules explicitly
loaded in Perl files

=head1 VERSION

Version 0.6.2

=cut

our $VERSION = '0.6.2';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Extract the names of the modules explicitly loaded in Perl files,
check which modules are not installed, and install the missing
modules. Since this module relies on
L<Perl::PrereqScanner|Perl::PrereqScanner> to statically identify
dependencies, it has the same caveats regarding identifying loaded
modules. Therefore, modules that are loaded dynamically (e.g.,
C<eval "require $class">) will not be identified as dependencies or
installed.

=head2 Command-line tool

Command-line usage is possible with C<install-perl-prereqs>
(co-installed with this module).

    install-perl-prereqs FILE_OR_DIR [FILE_OR_DIR ...]
        -h, --help
        -d, --dry-run
        -q, --quiet
        -v, --version

=head2 Methods for scanning files and installing modules

=over 4

=item new

Initializes a new Perl::PrereqInstaller object.

=cut

sub new {
    my $class = shift;

    my $self = {
        _not_installed        => {},
        _previously_installed => {},
        _newly_installed      => {},
        _failed_install       => {},
        _scan_errors          => [],
        _scan_warnings        => {},
        _banned => { # Some pragmas and/or modules misbehave or are irrelevant
            'autodie'  => 1,
            'base'     => 1,
            'feature'  => 1,
            'overload' => 1,
            'perl'     => 1,
            'strict'   => 1,
            'vars'     => 1,
            'warnings' => 1,
        },
        _quiet     => 0,
        _filetypes => [ 'pl', 'pm', 'cgi', 'psgi', 't' ],
    };
    bless $self, $class;

    return $self;
}

=item scan( FILES and/or DIRECTORIES )

Analyzes all specified FILES (regardless of file type) and Perl files
(.pl/.pm/.cgi/.psgi/.t) within specified DIRECTORIES to generate a
list of modules explicitly loaded and identify which are not
currently installed. Subsequent use of C<scan()> will update the
lists of not yet installed and previously installed modules.

=cut

sub scan {
    my ( $self, @path_list ) = @_;

    my $filetypes = join "|", @{ $self->{_filetypes} };
    my $filetypes_regex = qr/^.+\.(?:$filetypes)$/i;

    unless ( $self->quiet ) {
        print "\n";
        print "Files scanned:\n";
    }

    for my $path (@path_list) {
        if ( -f $path ) {
            $path = abs_path($path);
            print "  $path\n" unless $self->quiet;

            my $original_dir = getcwd;
            my $file_dir     = ( fileparse($path) )[1];

            chdir $file_dir; # Mimics the way File::Find traverses a directory
            $self->_scan_file("$path");
            chdir $original_dir;
        }
        elsif ( -d $path ) {
            find(
                sub {
                    return unless /$filetypes_regex/;
                    my $cwd  = getcwd;
                    my $file_path = "$cwd/$_";
                    print "  $file_path\n" unless $self->quiet;
                    $self->_scan_file("$file_path");
                },
                $path
            );
        }
        else {
            print "Neither file nor directory: $path\n"
                unless $self->quiet;
        }
    }
    print "\n" unless $self->quiet;
}

sub _scan_file {
    my ( $self, @file_list ) = @_;

    my $scanner = Perl::PrereqScanner->new;

    for my $file (@file_list) {
        next unless -e $file;

        if ( -s $file >= 1048576 ) {
            $self->_scan_code($file);
            next;
        }

        my $prereqs;
        my $CATCH_WARNING = 1;
        $SIG{'__WARN__'}
            = sub { _catch_warning( $self, $file, $_[0], $CATCH_WARNING ) };
        eval { $prereqs = $scanner->scan_file($file) };
        $CATCH_WARNING = 0;
        if ($@) {
            push @{ $self->{_scan_errors} }, $file;
            next;
        }

        my @module_list = keys %{ $$prereqs{'requirements'} };
        $self->_check_installed( $file, @module_list );
    }
}

sub _scan_code {

    # Scan code in chunks half the size of PPI:Tokenizer's limit
    # This 1 MB limit should be removed in PPI 1.218
    #
    # I submitted a pull request to bump the required PPI version #
    # for Perl::PrereqScanner. Will remove this workaround once the
    # request is accepted and released.
    # https://github.com/rjbs/Perl-PrereqScanner/pull/46


    my ( $self, $file ) = @_;

    my $scanner = Perl::PrereqScanner->new;
    my $prereqs;
    my %modules;
    my $string = '';
    open my $perl_fh, "<", $file;
    while ( my $line = <$perl_fh> ) {
        $string .= $line;
        my $byte_size;
        {
            use bytes;
            $byte_size = length $string;
        }
        next unless $byte_size > 524_288 || eof($perl_fh);

        my $CATCH_WARNING = 1;
        $SIG{'__WARN__'}
            = sub { _catch_warning( $self, $file, $_[0], $CATCH_WARNING ) };
        eval { $prereqs = $scanner->scan_string($string) };
        $CATCH_WARNING = 0;
        if ($@) {
            push @{ $self->{_scan_errors} }, $file;
            next;
        }
        $modules{$_} = 1 for keys %{ $$prereqs{'requirements'} };
        $string = '';
    }
    close $perl_fh;

    my @module_list = keys %modules;
    $self->_check_installed( $file, @module_list );
}

sub _check_installed {
    my ( $self, $file, @module_list ) = @_;

    for my $module (@module_list) {
        next if exists $self->{_banned}{$module};

        my $CATCH_WARNING = 1;
        $SIG{'__WARN__'}
            = sub { _catch_warning( $self, $file, $_[0], $CATCH_WARNING ) };
        eval "require $module;";
        $CATCH_WARNING = 0;
        if ($@) {
            $self->{_not_installed}{$module}++;
        }
        else {
            $self->{_previously_installed}{$module}++;
        }
    }
}

sub _catch_warning {
    my ( $self, $file, $warning, $CATCH_WARNING ) = @_;

    if ($CATCH_WARNING) {
        chomp $warning;
        push @{ $self->{_scan_warnings}{$file} }, $warning;
    }
    else { warn $warning }
}

=item cpanm

Use cpanm to install loaded modules that are not currently installed.

=cut

sub cpanm {
    my $self = shift;

    my @modules = sort keys %{ $self->{_not_installed} };
    for (@modules) {
        my $cpanm_cmd = "cpanm";
        $cpanm_cmd .= " -q" if $self->quiet;
        my $exit_status = system("$cpanm_cmd $_");
        if ($exit_status) {
            $self->{_failed_install}{$_}++;
        }
        else {
            delete $self->{_not_installed}{$_};
            delete $self->{_failed_install}{$_};
            $self->{_newly_installed}{$_}++;
        }
    }
}

=item quiet( BOOLEAN )

Set quiet mode to on/off (default: off). Quiet mode turns off most
of the output. If BOOLEAN is not provided, this method returns quiet
mode's current state.

=cut

sub quiet {
    my ( $self, $boolean ) = @_;

    if ( defined $boolean ) {
        $self->{_quiet} = $boolean;
    }
    else {
        return $self->{_quiet};
    }
}

=back

=head2 Methods for accessing and reporting scan/install status

=over 4

=item not_installed

Returns an alphabetical list of unique modules that were explicitly
loaded, but need to be installed. Modules are removed from this list
upon installation.

=cut

sub not_installed {
    my $self = shift;
    return sort keys %{ $self->{_not_installed} };
}

=item previously_installed

Returns an alphabetical list of unique installed modules that were
explicitly loaded.

=cut

sub previously_installed {
    my $self = shift;
    return sort keys %{ $self->{_previously_installed} };
}

=item newly_installed

Returns an alphabetical list of unique modules that were
explicitly loaded, needed to be installed, and were successfully
installed.

=cut

sub newly_installed {
    my $self = shift;
    return sort keys %{ $self->{_newly_installed} };
}

=item failed_install

Returns an alphabetical list of unique modules that were
explicitly loaded and needed to be installed, but whose installation
failed.

=cut

sub failed_install {
    my $self = shift;
    return sort keys %{ $self->{_failed_install} };
}

=item scan_errors

Returns a list of files that produced a parsing error
when being scanned. These files are skipped.

=cut

sub scan_errors {
    my $self = shift;
    return @{ $self->{_scan_errors} };
}

=item scan_warnings

Returns a hash of arrays containing the names of files (the keys) that
raised warnings (the array contents) during parsing. These warnings
are likely indicative of issues with the code in the parsed files
rather than actual parsing problems.

=cut

sub scan_warnings {
    my $self = shift;
    return %{ $self->{_scan_warnings} };
}

=item report

Write (to STDOUT) a summary of scan/install results. By default, all
status methods below (except C<scan_warnings>) are summarized. To
customize the contents of C<report()>, pass it an anonymous hash:

    $installer->report(
        {   'not_installed'        => 0,
            'previously_installed' => 0,
            'newly_installed'      => 1,
            'failed_install'       => 1,
            'scan_errors'          => 0,
            'scan_warnings'        => 0,
        }
    );

=cut

sub report {
    my ( $self, $custom_contents ) = @_;

    my %summary_contents = (
        'not_installed'        => 1,
        'previously_installed' => 1,
        'newly_installed'      => 1,
        'failed_install'       => 1,
        'scan_errors'          => 1,
        'scan_warnings'        => 0,
    );

    $summary_contents{$_} = $$custom_contents{$_} for keys %$custom_contents;

    _summarize( 'File parsing errors', '', $self->scan_errors )
        if $summary_contents{'scan_errors'} == 1 && !$self->quiet;

    _summarize(
        'Modules to install',
        'No missing modules need to be installed!',
        $self->not_installed
    ) if $summary_contents{'not_installed'} == 1 && !$self->quiet;

    _summarize( 'Successfully installed', '', $self->newly_installed )
        if $summary_contents{'newly_installed'} == 1;

    _summarize( 'Failed to install', '', $self->failed_install )
        if $summary_contents{'failed_install'} == 1;

    if ( $summary_contents{'scan_warnings'} == 1 && !$self->quiet ) {
        my %scan_warnings = $self->scan_warnings;
        my @warned_files  = sort keys %scan_warnings;
        if ( scalar @warned_files > 0 ) {
            print "Warnings during scan:\n";
            for my $file (@warned_files) {
                print "  $file\n";
                $Text::Wrap::columns = 78;
                $Text::Wrap::huge    = 'wrap';
                print wrap( "  | - ", "  |   ", "$_\n" )
                    for @{ $scan_warnings{$file} };
            }
            print "\n";
        }
    }
}

sub _summarize {
    my ( $title, $alt_message, @items ) = @_;

    if ( scalar @items > 0 ) {
        print "$title:\n";
        print "  $_\n" for @items;
        print "\n";
    }
    elsif ($alt_message) {
        print "$alt_message\n\n";
    }
}

=back

=head1 SEE ALSO

L<Perl::PrereqScanner|Perl::PrereqScanner>,
L<App::cpanoutdated|App::cpanoutdated>,
L<lib::xi|lib::xi>,
L<Module::Extract::Use|Module::Extract::Use>

The command-line tool C<scan-perl-prereqs> gets installed together
with L<Perl::PrereqScanner|Perl::PrereqScanner>. The basic
functionality of C<install-perl-prereqs> can be recreated with
C<scan-perl-prereqs | cpanm>; however, C<install-perl-prereqs> comes
with a few bonuses. These include:

=over 4

=item Better error handling

In the event of parse errors, C<scan-perl-prereqs> dies even if there
are files remaining to be scanned, whereas C<install-perl-prereqs>
logs the error and scans the next file.

=item Summary report

C<install-perl-prereqs> provides a summary of scan and install
results.

=item No unexpected updates

While C<scan-perl-prereqs | cpanm> attempts to update all
previously-installed modules found in a scan, C<install-perl-prereqs>
only attempts to install modules if they are not yet installed.

Perhaps a better way to update installed CPAN modules is to use
L<cpan-outdated|cpan-outdated> (from
L<App::cpanoutdated|App::cpanoutdated>):

    cpan-outdated -p | cpanm

=back

=head1 SOURCE AVAILABILITY

The source code is on Github:
L<https://github.com/mfcovington/Perl-PrereqInstaller>

=head1 AUTHOR

Michael F. Covington, <mfcovington@gmail.com>

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/mfcovington/Perl-PrereqInstaller/issues>.

=head1 INSTALLATION

To install this module from GitHub using cpanm:

    cpanm git@github.com:mfcovington/Perl-PrereqInstaller.git

Alternatively, download and run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Perl::PrereqInstaller

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael F. Covington.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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

=cut

1;
