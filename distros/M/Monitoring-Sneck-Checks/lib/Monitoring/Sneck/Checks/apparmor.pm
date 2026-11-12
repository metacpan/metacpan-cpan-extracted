package Monitoring::Sneck::Checks::apparmor;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::apparmor - checks AppArmor is enabled with its profiles enforcing

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where AppArmor says if it is enabled and lists its profiles. Set by tests.
our $ENABLED  = '/sys/module/apparmor/parameters/enabled';
our $PROFILES = '/sys/kernel/security/apparmor/profiles';

# How many profiles in complain mode to name in the status line.
our $COMPLAIN_NAMED = 5;

=head1 SYNOPSIS

    apparmor|perl:apparmor
    apparmor_web|perl:apparmor -p /usr/sbin/nginx -p php-fpm -m 20
    apparmor_lab|perl:apparmor -x '^/usr/bin/firefox'

=head1 DESCRIPTION

Checks AppArmor is enabled and the profiles it has loaded, from
/sys/kernel/security/apparmor/profiles, which only root can read.

- CRITICAL :: AppArmor not enabled. A profile given with --profile not
loaded or not in enforce mode. Fewer profiles than --min-profiles.

- WARNING :: Profiles in complain mode, other than those --exclude
matches.

- UNKNOWN :: Not being Linux, or the profiles not being readable.

Profiles flagged unconfined, as some distros ship, are counted but not
warned about.

=head1 OPTIONS

- -p, --profile :: A profile that must be loaded and enforcing. May be
given more than once.

- -m, --min-profiles :: How many profiles there must be at least.

- -x, --exclude :: A regex for profiles allowed to be in complain mode.
May be given more than once.

=cut

sub option_spec { return ( 'profile|p=s@', 'min-profiles|m=i', 'exclude|x=s@' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $regex ( @{ $options->{exclude} // [] } ) {
		push( @problems, '--exclude "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';

	my $enabled = read_file( $ENABLED, err_mode => 'quiet' ) // '';
	return $self->finish( $self->CRITICAL, 'AppArmor is not enabled' ) if $enabled !~ /\A\s*Y/;
	my $listed = read_file( $PROFILES, err_mode => 'quiet' );
	return $self->finish( $self->UNKNOWN, 'can not read ' . $PROFILES . ', ' . $! ) if !defined($listed);

	# lines such as "/usr/sbin/cupsd (enforce)", child profiles being "parent//child"
	my %profiles;
	foreach my $line ( split( /\n/, $listed ) ) {
		$profiles{$1} = $2 if $line =~ /\A(.+) \((\w+)\)\s*\z/;
	}
	my %modes;
	$modes{$_}++ foreach values(%profiles);

	my $count = scalar( keys(%profiles) );
	my @codes = ( $self->OK );
	my @parts = ( $count . ' profile' . ( $count == 1 ? '' : 's' ) );
	push( @parts, map { $modes{$_} . ' ' . $_ } sort( keys(%modes) ) );
	if ( defined( $self->opt('min-profiles') ) && $count < $self->opt('min-profiles') ) {
		push( @codes, $self->CRITICAL );
		push( @parts, 'under ' . $self->opt('min-profiles') );
	}

	my %required = map { $_ => 1 } @{ $self->opt('profile') // [] };
	foreach my $profile ( sort( keys(%required) ) ) {
		next if ( $profiles{$profile} // '' ) eq 'enforce';
		push( @codes, $self->CRITICAL );
		push( @parts,
			defined( $profiles{$profile} )
			? $profile . ' in ' . $profiles{$profile} . ' mode'
			: $profile . ' not loaded' );
	}

	# required ones are said above, so not again here
	my @excludes = map { qr/$_/ } @{ $self->opt('exclude') // [] };
	my @complaining;
	foreach my $profile ( sort( keys(%profiles) ) ) {
		next if $profiles{$profile} ne 'complain' || $required{$profile};
		next if grep { $profile =~ $_ } @excludes;
		push( @complaining, $profile );
	}
	if (@complaining) {
		push( @codes, $self->WARNING );
		my @named = @complaining;
		splice( @named, $COMPLAIN_NAMED ) if @named > $COMPLAIN_NAMED;
		my $says = 'complaining: ' . join( ', ', @named );
		$says = $says . ' and ' . ( @complaining - @named ) . ' more' if @complaining > @named;
		push( @parts, $says );
	}

	$self->perfdata( label => 'profiles', value => $count,                min => 0 );
	$self->perfdata( label => 'complain', value => $modes{complain} // 0, min => 0 );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ), map { 'complaining: ' . $_ } @complaining );
} ## end sub check

1;
