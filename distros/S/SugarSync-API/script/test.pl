#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Tue Aug 30 12:44:57 2011
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jul 25 21:11:33 2016
# Update Count    : 38
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'SugarSync';
# Program name and version.
my ($my_name, $my_version) = qw( test 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 0;		# verbose processing
my $config = $ENV{HOME} . "/.config/sugarsync/config";
my $show_location = 0;

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use SugarSync::API;
use Config::Tiny;

die("Nothing to test -- spcify URLs on the command line\n")
  unless @ARGV || $show_location;

# Load config data.
my $cfg = Config::Tiny->read($config);

my $so = SugarSync::API->new( $cfg->{auth}->{username},
			      $cfg->{auth}->{password},
			      $cfg->{api}->{accesskeyid},
			      $cfg->{api}->{privateaccesskey},
			      $cfg->{api}->{application},
			    );

warn("Location: ", $so->{_auth}, "\n") if $show_location;

$so->get_userinfo();
use Data::Dumper;warn(Dumper($so));exit;
foreach ( @ARGV ) {
    $so->get_url_xml( $_, 1 );
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions('ident'	=> \$ident,
		   'show-location|s' => \$show_location,
		   'config=s'	=> \$config,
		   'verbose'	=> \$verbose,
		   'trace'	=> \$trace,
		   'help|?'	=> \$help,
		   'man'	=> \$man,
		   'debug'	=> \$debug)
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

__END__

################ Documentation ################

=head1 NAME

test - SugarSync API tester

=head1 SYNOPSIS

test [options] url ...

 Options:
   --show-auth -s	show authorization token
   --config=XXX		altenative config file
   --ident		show identification
   --help		brief help message
   --man                full documentation
   --verbose		verbose information

=head1 OPTIONS

=over 8

=item B<--show-auth> B<-s>

Show the authorization token.

=item B<--config> I<file>

Alternate config file.

Default config file is $HOME/.config/sugarsync/config .

This should contain the username and password for Sugarsync.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=item I<file>

Input file(s).

=back

=head1 DESCRIPTION

B<This program> will authorize for SugarSync access and retrieve the
specified urls. The urls are assumed to return XML data which is shows
as a Perl structure.

With option <--show-auth> it will also show the authorization token.
In this case, specifying urls is optional.

=head1 CONFIG FILE

A config file is required to store the username and password for
SugarSync access.

By default, the config file is C<.config/sugarsync/config> in the
users home directory. An alternative config file can be selected with
the B<--config> command line option.

The config file should contain:

  [auth]
  username = your_sugarsync_user_name
  password = your_sugarsync_password

=SEE ALSO

L<SugarSync::API>.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS & SUPPORT

See L<SugarSync::API>.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
