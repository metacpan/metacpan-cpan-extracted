#!perl

use strict;

use constant PPM3 => eval "use PPM::UI; 1;";
use constant PPM4 => eval "use ActivePerl::PPM::Client; 1;";

unless (PPM3 || PPM4) {
    die "You must run this script with ActivePerl";
}

our $VERSION = join('.', 1, q$Revision: #3 $ =~ /#(\d+)/);

use Getopt::Long;
use Pod::Usage;
my %opts;
GetOptions(\%opts, 'verbose', 'help', 'man') or pod2usage(2);
pod2usage(1) if ($opts{help});
pod2usage(-verbose => 2) if ($opts{man});

my %modes = (
             'save'    => \&save,
             'restore' => \&restore,
            );

my $mode = shift @ARGV;

if (exists $modes{$mode}) {
    exit $modes{$mode}->();
}
else {
    exit pod2usage("Unknown mode: $mode");
}

sub ActivePerl::PPM::Package::osd_version {
    my $pkg = shift;
    my $osd = $pkg->version;
    
    my @v = map { s/^0+//g; $_ } split /\./, $osd;
    push @v, '0' for 1..4-@v;
    
    $osd = join ',',@v;
    
    return $osd;
}

sub ActivePerl::PPM::Package::xml {
    my $pkg = shift;
    my $client = shift;
    my $name = $pkg->name;
    my $abstract = $pkg->abstract;
    my $version = $pkg->version;
    my $uri = $pkg->ppd_uri;
    
    print "pkg:$name, uri: $uri\n";
    
    $uri =~ s[/package.xml$][];
    my $code = $pkg->codebase;
    
    my $codebase_xml;
    if ($uri && $code) {
        $codebase_xml = qq(\n    <CODEBASE HREF="$uri/$code" />);
    }
    
    my $arch = $client->arch;
    my $os = $^O;
return <<"EOF"
 <SOFTPKG NAME="$name" VERSION="$version">
  <ABSTRACT>$abstract</ABSTRACT>
  <IMPLEMENTATION>
    <ARCHITECTURE NAME="$arch" />$codebase_xml
    <OS NAME="$os" />
  </IMPLEMENTATION>
 </SOFTPKG>
EOF
}

sub save {
    my $profile = shift @ARGV || 'profile.xml';
    
    die "$0 save is not supported for PPM4 yet" if PPM4;

    open(my $fh, ">", $profile)
      || die "Can't open profile file:" . "$profile ($!)";

    print STDERR "Saving to $profile:\n" if $opts{verbose};

    my @profile;

    if (PPM3) {
        my @targets = PPM::UI::target_list()->result_l;
        my $target  = $targets[0];

        my @query = PPM::UI::query($target, '*')->result_l;

        my $fake_rep = PPM::Repository->new("xxx", "PPM Profile");

        foreach my $ppm (@query) {
            $ppm->make_complete($target);
            my $name = $ppm->name;
            my $ppd  = $ppm->getppd_obj->result;

            my $version = $ppd->version;

            print STDERR "\t$name ($version)\n" if $opts{verbose};
            (my $xml = $ppm->getppd->result) =~ s/<\?xml[^>]+>\n//;

            push @profile, $xml;
        }
    }
    elsif (PPM4) {
        # Not quite supported yet.
        my $client = ActivePerl::PPM::Client->new;
        foreach my $area_name ($client->areas) {
            my $area = $client->area( $area_name );
            print "Area: $area\n";
            foreach my $pkg_name ($area->packages) {
                my $pkg = $area->package($pkg_name);
                my $xml = $pkg->xml($client);
                print "package: $pkg_name\n";
                push @profile, $xml;
            }
        }
    }

    my $now = localtime;
    print $fh qq(<?xml version="1.0" encoding="UTF-8"?>\n);
    print $fh
      "<!-- Generated by ppmprofile (version $VERSION) at $now -->\n";
    print $fh "<REPOSITORYSUMMARY>\n", @profile,
      "</REPOSITORYSUMMARY>\n";
    close($fh);
}

use File::Temp;
use Config;
use XML::Simple;

sub restore {
    my $profile = shift @ARGV || 'profile.xml';

    my $data = XMLin(
                     $profile,
                     forcearray    => 1,
                     forcecontent  => 1,
                     keyattr       => [],
                     suppressempty => undef,
                    );

    my $ppm    = File::Spec->catfile($Config{installbin}, PPM4 ? 'ppm' : 'ppm3');
    my $nul    = File::Spec->devnull;
    my $output = $opts{verbose} ? "" : "1>$nul 2>$nul";

    my @failed;
    foreach my $pkg (@{$data->{SOFTPKG} || []}) {
        my $name = $pkg->{NAME};
        
        print "Restoring $name: " if $opts{verbose};

        if (PPM3) {
            my $ppd = XMLout(
                   $pkg,
                   rootname => 'SOFTPKG',
                   xmldecl => q{<?xml version="1.0" encoding="UTF-8"?>},
            );
            my $tmp = new File::Temp(SUFFIX => '.ppd');
            binmode($tmp, ':utf8');
            print $tmp $ppd;
            $tmp->flush;
        
            system(qq($ppm install --nofollow --force "$tmp" $output));

            if ($? != 0) {
                system(qq($ppm install --nofollow --force $name $output));
            }
        }
        else {
            system(qq($ppm install --nodeps --force $name $output));
        }

        if ($? != 0) {
            print STDERR "Failed\n" if $opts{verbose};
            push @failed, $name;
        }
        else {
            print "Ok\n" if $opts{verbose};
        }
    }

    print STDERR "Failed restoring the following packages: ";
    print STDERR join ', ', @failed;
    print STDERR "\n";

}

=pod

=head1 NAME

ppmprofile - A tool to save and restore PPM profiles

=head1 SYNOPSIS

ppmprofile [--verbose] (save|restore) [profile_file]

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

A more detailled help message

=item B<-verbose>

Print out more details at run-time

=back

=head1 DESCRIPTION

B<This program> can be used to export a list of all currently installed
PPM packages. It can then be used to automatically install all these
package in another installation of ActivePerl, possibly on a different
machine.

=over 4

=item * save

Save will export a snapshot of all installed modules in a profile file
called C<profile.xml> by default

=item * restore

Restore will import a snapshot from a profile file (called C<profile.xml> 
by default) and use PPM to re-install these modules

=back

=cut

