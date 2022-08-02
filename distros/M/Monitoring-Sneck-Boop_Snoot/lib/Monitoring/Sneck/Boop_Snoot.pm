package Monitoring::Sneck::Boop_Snoot;

use 5.006;
use strict;
use warnings;
use String::ShellQuote;
use MIME::Base64;
use Gzip::Faster;

=head1 NAME

Monitoring::Sneck::Boop_Snoot -  Boop the Monitoring::Sneck's snoot via SNMP

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Monitoring::Sneck::Boop_Snoot;

    my $sneck_snoot_booper = Monitoring::Sneck::Boop_Snoot->new({
                                                   version=>'2c',
                                                   community=>'public',
                                                   });

=head1 METHODS

=head2 new

Initiates the object.

    version      Version to use. 1, 2c, or 3
                 Default: 2c

    SNMP Version 1 or 2c specific
    community    set the community string
                 Default: public

    SNMP Version 3 specific
    a            set authentication protocol (MD5|SHA|SHA-224|SHA-256|SHA-384|SHA-512)
    A            set authentication protocol pass phrase
    e            set security engine ID (e.g. 800000020109840301)
    E            set context engine ID (e.g. 800000020109840301)
    l            set security level (noAuthNoPriv|authNoPriv|authPriv)
    n            set context name (e.g. bridge1)
    u            set security name (e.g. bert)
    x            set privacy protocol (DES|AES)
    X            set privacy protocol pass phrase
    Z            set destination engine boots/time

    my $sneck_snoot_booper = Monitoring::Sneck::Boop_Snoot->new({
                                                   version=>'2c',
                                                   community=>'public',
                                                   });

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my $self = {
		version   => '2c',
		community => 'public',
	};

	foreach my $arg_key ( keys(%args) ) {
		$self->{$arg_key} = shell_quote( $args{$arg_key} );
	}

	if ( $self->{version} ne '1' && $self->{version} ne '2c' && $self->{version} ne '3' ) {
		die( '"' . $self->{version} . '" is not a recognized version' );
	}

	bless $self;

	return $self;
}

=head2 boop_the_snoot

Fetches the data for the host and returns it.

One option is taken and that is the hostname to poll.

This will die on snmpget failure.

    my $raw_json=$$sneck_snoot_booper->boop_the_snoot($host);

=cut

sub boop_the_snoot {
	my $self = $_[0];
	my $host = $_[1];

	# makes sure we have a good host
	if ( !defined($host) ) {
		die('No host specified');
	}

	# quote the host so we can safely use it
	$host = shell_quote($host);

	# put together the auth string to use
	my $auth_string = '-v ' . $self->{version};
	if ( $self->{version} eq '1' || $self->{version} eq '2c' ) {
		$auth_string = $auth_string . ' -c ' . $self->{community};
	}
	else {
		my @auth_keys = ( 'a', 'A', 'e', 'E', 'l', 'n', 'u', 'x', 'X', 'Z' );
		foreach my $auth_key (@auth_keys) {
			if ( defined( $self->{$auth_key} ) ) {
				$auth_string = $auth_string . ' -' . $auth_key . ' ' . shell_quote( $self->{$auth_key} );
			}
		}
	}

	# the the snmpget command
	my $returned
		= `snmpget -Onq -v $self->{version} $auth_string $host 1.3.6.1.4.1.8072.1.3.2.3.1.2.5.115.110.101.99.107`;
	my $exit_code = $?;
	chomp($returned);

	# handle the exit code
	my $exit_error = '';
	if ( $exit_code == -1 ) {
		die('failed to execute snmpget');
	}
	elsif ( $exit_code & 127 ) {
		die(
			sprintf(
				"child died with signal %d, %s coredump\n",
				( $exit_code & 127 ),
				( $exit_code & 128 ) ? 'with' : 'without'
			)
		);
	}
	else {
		$exit_code = $exit_code >> 8;
		if ( $exit_code != 0 ) {
			die( 'snmpget exited with ' . $exit_code );
		}
	}

	# clean it up incase it is on a system that quotes everything
	$returned =~ s/\\([^nbfrt\\])/$1/g;
	$returned =~ s/^\"//;
	$returned =~ s/\"$//;
	my ( $oid, $json ) = split( /\ +/, $returned, 2 );
	$json =~ s/^\"//;
	$json =~ s/\"$//;

	# check for base64 incasae the return has been gzipped
	if ($json =~ /^[A-Za-z0-9\/\+\n]+\=*\n*$/ ) {
		$json = gunzip(decode_base64($json));
	}

	return $json;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-monitoring-sneck-boop_snoot at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Monitoring-Sneck-Boop_Snoot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Monitoring::Sneck::Boop_Snoot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Monitoring-Sneck-Boop_Snoot>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Monitoring-Sneck-Boop_Snoot>

=item * Search CPAN

L<https://metacpan.org/release/Monitoring-Sneck-Boop_Snoot>

=item * Github

L<https://github.com/VVelox/Monitoring-Sneck-Boop_Snoot>

=item * Repo

L<https://github.com/VVelox/Monitoring-Sneck-Boop_Snoot.git>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Monitoring::Sneck::Boop_Snoot
