###########################################
package Perl::Installed;
###########################################

use strict;
use warnings;
#use Log::Log4perl qw(:easy);
use File::Spec;

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    if(! exists $self->{prefix}) {
        die "Mandatory parameter 'prefix' missing";
    }

    if(! -d $self->{prefix}) {
        die "Mandatory parameter 'prefix' not a directory";
    }

    $self->{bindir}  = File::Spec->catfile($self->{prefix}, "bin");
    $self->{perldoc} = File::Spec->catfile($self->{bindir}, "perldoc");
    $self->{perl}    = File::Spec->catfile($self->{bindir}, "perl");

    if(! -f $self->{perl}) {
        die "perl not found under prefix $self->{prefix}/bin";
    }

    bless $self, $class;
    $self->_config_init();

    return $self;
}

###########################################
sub _config_init {
###########################################
    my($self) = @_;

    my $cmd = 
        qq#$self->{perl} -MConfig -l0e'print "\$_\\0\$Config{\$_}" # .
        qq#for keys %Config'#;

    my $data = `$cmd`;
    my %config = split /\0/, $data;
    $self->{config} = \%config;

    $self->{packlistfile} = File::Spec->catfile($self->{config}->{archlib},
                                                ".packlist");

    if($self->{config}->{version} !~ /\d/) {
        die "Loading config failed";
    }
}

###########################################
sub config {
###########################################
    my($self) = @_;

    return $self->{config};
}

###########################################
sub files {
###########################################
    my($self) = @_;

    if(! -f $self->{packlistfile}) {
        #ERROR "Package file $packfile doesn't exist";
        return undef;
    }

    my @packlist;
        # Read a .packlist file of an installed perl distribution
        # and generate the necessary yicf file/symlink lines from
        # it.
        #
        # A perl packlist looks like this:
        # /home/y/bin/libnetcfg type=file
        # /home/y/bin/perl from=/home/y/bin/perl5.10.1 type=link
    open FILE, "<$self->{packlistfile}" or 
        die "Cannot open $self->{packlistfile} ($!)";

    while(<FILE>) {

        my %opts;

        my($file, @options) = split ' ', $_;

        for my $opt (@options) {
            my($key, $value) = split /=/, $opt;
            $opts{$key} = $value;
        }

        push @packlist, {path => $file, %opts};
    }
    close FILE;

    return \@packlist;
}

###########################################
sub packlistfile {
###########################################
    my($self) = @_;

    return $self->{packlistfile};
}

1;

__END__

=head1 NAME

Perl::Installed - Get meta information of a perl installation

=head1 SYNOPSIS

    use Perl::Installed;

    my $perl = Perl::Installed->new( prefix => "/usr/local" );

        # Retrieve all files and symlinks
    my @files = $perl->files();

        # Retrieve configuration parameters
    my $cfg = $perl->config();
    print "$cfg->{version} on $cfg->{osname}\n";

=head1 DESCRIPTION

When you point C<Perl::Installed> to a perl installation by telling it the
prefix (e.g. "/usr" or "/usr/local"), it will provide meta data, like
the files the installation consists of or the $Config hash it uses.

This way, you can bundle up perl installations for package management 
systems like Redhat's RPM or Debian's dpkg. Note that the perl installation
you're using to perform the bundling isn't necessarily identical with
the perl installation you're bundling up.

=head1 METHODS

=over 4

=item new( prefix => "..." )

Constructor, takes the prefix of the perl installation as a mandatory
parameter. Usually the prefix of a perl installation is either
"/usr" (perl therefore being at /usr/bin/perl) or "/usr/local".

=item files()

Looks at the installation's .packlist and returns the files therein.
It returns a reference to an array with an element for each file/symlink.
Every array element is a reference to a hash with the following entries:

    path - Path to the file/symlink
    type - "file" or "link"
    from - If 'path' is a symlink, this entry tells where it's pointing
           to (usually where the corresponding file is).

Example:

    my @files = $perl->files();

    for my $file (@files) {

        if( $file->{type} eq "file" ) {
            print "File: $file->{path}\n";
        } elsif( $file->{type} eq "link" ) {
            print "Link: $file->{path} -> $file->{from}\n";
        }
    }

=item config()

Returns a reference to the perl installation's $Config hash, just as
if you had said C<use Config> and used C<%Config> afterwards. Note that 
the perl installation you're using to perform the bundling isn't 
necessarily identical with the perl installation you're bundling up, so
it will 

=item packlistfile()

Return the path to the packlist file of the perl core.

=back

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>
