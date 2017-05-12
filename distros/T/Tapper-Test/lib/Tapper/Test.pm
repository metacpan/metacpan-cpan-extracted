package Tapper::Test;
# git description: v4.1.2-3-g0257452

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Utilities for Perl based Tapper testing
$Tapper::Test::VERSION = '5.0.0';
use warnings;
use strict;

use 5.010;

use Test::More;
use Sys::Info;
use Format::Human::Bytes;

use parent 'Exporter';
our @EXPORT = qw/tapper_suite_meta tapper_section_meta/;

sub _uname {
        my $os = Sys::Info->new->os;

        my $osbase =
         $os->is_win   ? "Windows" :
         $os->is_linux ? "Linux" :
         $os->is_bsd   ? "BSD" :
         "UnknownOS";
        my $uname = join (" ",
                          $osbase,
                          $os->node_name,
                          $os->name(long => 1, edition => 1),
                          ~~localtime($os->build),
                         );
        $uname .= " [Sys::Info]";
        return $uname;
}

sub _hostname {
        my $hostname = Sys::Info->new->os->node_name;
        return $hostname;
}

sub _osname {
        my $os = Sys::Info->new->os;
        my $osname = join (" ",
                           $os->name(edition => 1),
                           $os->version,
                          );
        return $osname;
}

sub _cpuinfo {
        return Sys::Info->new->device('CPU')->identify;
}

sub _ram {
        my %osmeta = Sys::Info->new->os->meta;
        my $ram = Format::Human::Bytes::base2($osmeta{physical_memory_total}*1024);
        return $ram;
}

sub _starttime_test_program {
        use POSIX qw(strftime setlocale);

        my $old_loc = setlocale( &POSIX::LC_ALL );

        setlocale( &POSIX::LC_ALL, "C" );
        my $starttime_test_program = strftime("%a, %d %b %Y %H:%M:%S %z", gmtime(time()));
        setlocale( &POSIX::LC_ALL, $old_loc );

        return $starttime_test_program;
}

sub _suite_name
{
        my $build_paramfile = '_build/build_params';
        my $makefile        = 'Makefile';
        my $distini         = 'dist.ini';

        if (-e $build_paramfile )
        {
                my $params = do $build_paramfile;
                my $suite_name = $params->[2]->{dist_name};
                return $suite_name;
        }
        elsif (-e $makefile)
        {
                my $infile = $makefile;
                open my $F, "<", $infile or die "Cannot open $infile";
                my ($suite_name) = grep { /^DISTNAME *=/ } <$F>;
                $suite_name =~ s/^.*=\s*//;
                chomp $suite_name;
                return $suite_name;
        }
        elsif (-e $distini)
        {
                my $infile = $distini;
                open my $F, "<", $infile or die "Cannot open $infile";
                my ($suite_name) = grep { /^name *=/ } <$F>;
                $suite_name =~ s/^.*=\s*//;
                chomp $suite_name;
                return $suite_name;
        }
        else
        {
                warn "Cannot access $build_paramfile or $makefile.\nPlease run perl Build.PL or perl Makefile.PL.\n";
                return undef;
        }
}

sub _suite_version
{
        my $build_paramfile = '_build/build_params';
        my $makefile        = 'Makefile';
        my $distini         = 'dist.ini';

        if (-e $build_paramfile )
        {
                my $params = do $build_paramfile;
                my $suite_version;
                if (not ref $params->[2]->{dist_version}) {
                        $suite_version = $params->[2]->{dist_version};
                } else {
                        $suite_version = $params->[2]->{dist_version}->{original};
                }
                return $suite_version;
        }
        elsif (-e $makefile)
        {
                my $infile = $makefile;
                open my $F, "<", $infile or die "Cannot open $infile";
                my ($suite_version) = grep { /^VERSION *=/ } <$F>;
                $suite_version =~ s/^.*=\s*//;
                chomp $suite_version;
                return $suite_version;
        }
        elsif (-e $distini)
        {
                return undef;
        }
        else
        {
                warn "Cannot access $build_paramfile or $makefile.\nPlease run perl Build.PL or perl Makefile.PL\n";
                return undef;
        }
}

sub _suite_type
{
        'software'; # 'hardware', 'benchmark', 'os', 'unknown'
}

sub _language_description {
        return "Perl $], $^X";
}

sub _reportgroup_arbitrary { $ENV{TAPPER_REPORT_GROUP} }
sub _reportgroup_testrun   { $ENV{TAPPER_TESTRUN}   }


sub tapper_suite_meta
{
        my %opts = @_;

        plan tests => 1 unless $opts{-suppress_plan};
        pass("tapper-suite-meta");

        my $suite_name             = $opts{suite_name}             // _suite_name();
        my $suite_version          = $opts{suite_version}          // _suite_version();
        my $suite_type             = $opts{suite_type}             // _suite_type();
        my $hostname               = $opts{hostname}               // _hostname();
        my $reportgroup_arbitrary  = $opts{reportgroup_arbitrary}  // _reportgroup_arbitrary();
        my $reportgroup_testrun    = $opts{reportgroup_testrun}    // _reportgroup_testrun();

        # to be used by TestSuite::* and Tapper::* modules

        print "# Tapper-reportgroup-arbitrary:   $reportgroup_arbitrary\n" if $reportgroup_arbitrary;
        print "# Tapper-reportgroup-testrun:     $reportgroup_testrun\n"   if $reportgroup_testrun;
        print "# Tapper-suite-name:              $suite_name\n";
        print "# Tapper-suite-version:           $suite_version\n";
        print "# Tapper-suite-type:              $suite_type\n";
        print "# Tapper-machine-name:            $hostname\n";

        tapper_section_meta(@_);
}


sub tapper_section_meta
{
        my %opts = @_;

        my $uname                  = $opts{uname}                  // _uname();
        my $osname                 = $opts{osname}                 // _osname();
        my $cpuinfo                = $opts{cpuinfo}                // _cpuinfo();
        my $ram                    = $opts{ram}                    // _ram();
        my $starttime_test_program = $opts{starttime_test_program} // _starttime_test_program();
        my $language_description   = $opts{language_description}   // _language_description();
        my $section                = $opts{section};

        # to be used by TestSuite::* and Tapper::* modules

        print "# Tapper-language-description:    $language_description\n";
        print "# Tapper-uname:                   $uname\n";
        print "# Tapper-osname:                  $osname\n";
        print "# Tapper-cpuinfo:                 $cpuinfo\n";
        print "# Tapper-ram:                     $ram\n";
        print "# Tapper-starttime-test-program:  $starttime_test_program\n";
        print "# Tapper-section:                 $section\n" if $section;
}



1; # End of Tapper::Test

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Test - Tapper - Utilities for Perl based Tapper testing

=head1 SYNOPSIS

 use Tapper::Test;
 tapper_suite_meta();

=head1 DESCRIPTION

When running tests in Tapper the Tapper report framework expects a
number of metainformation about the test system. To generate these
metainformation you can use Tapper::Test. Call
Tapper::Test::tapper_suite_meta() in your perl test script. This will
print the metainformation to STDOUT in the format Tapper expects (TAP
headers). See L<Tapper::Doc|Tapper::Doc> for more information on Tapper
testing.

=head2 tapper_suite_meta

Provides general meta information applying to the whole report.

=head2 tapper_section_meta

Provides meta information allowed to be repeated in several sections.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
