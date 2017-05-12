package Net::Jaiku;

$VERSION ="0.0501";
use warnings;
use strict;

use LWP::UserAgent;
use JSON::Any;
use HTML::Entities;
use Params::Validate qw/validate SCALAR ARRAYREF BOOLEAN/;

sub new {
    my $class = shift;
    my %conf = @_;

    $conf{ua} = LWP::UserAgent->new();
    $conf{ua}->env_proxy();
	$conf{ua}->timeout($conf{timeout}) if ($conf{timeout});
	delete($conf{timeout});

	$conf{username} ||= '';
	$conf{userkey}  ||= '';

    return bless {%conf}, $class;
}


sub username {
	my $self = shift;
	my $username = shift;
	if ($username){
		$self->{username} = $username;
	}
	return $self->{username};
}

sub userkey {
	my $self = shift;
	my $userkey = shift;
	if ($userkey){
		$self->{userkey} = $userkey;
	}
	return $self->{userkey};
}

sub auth {
	my $self = shift;
	if ($self->username() && $self->userkey()){
		return {
			user => $self->username,
			personal_key => $self->userkey,
		}
	}
	return {};
}
sub auth_query {
	my $self = shift;
	if ($self->username && $self->userkey){
		return sprintf('?user=%s&personal_key=%s',
			$self->username,
			$self->userkey,
		)
	}
	return '';
}


sub getMyFeed {
	my $self = shift;
	return $self->getFeed( user => $self->username );
}
sub getUserFeed {
	my $self = shift;
	my %arg = @_;
	return $self->getFeed( user => $arg{user} || $self->username );
}
sub getFeed {
	my $self = shift;
	my %arg = @_;

	return undef if $arg{user} && ! $self->auth;

    my $req = $self->{ua}->get(
		'http://'.(($arg{user}) ? "$arg{user}." : '').'jaiku.com/feed/json'.
		$self->auth_query,
	);
    return ($req->is_success) ?  HashInflator->new( JSON::Any->jsonToObj($req->content) ) : undef;
}

sub getContactsFeed {
	my $self = shift;
	my %arg = @_;

	return undef if $arg{user} && ! $self->auth;

    my $req = $self->{ua}->get(
		'http://'.$self->username.'.jaiku.com/contacts/feed/json'.
		$self->auth_query,
	);
    return ($req->is_success) ?  HashInflator->new( JSON::Any->jsonToObj($req->content) ) : undef;
}

sub getMyPresence {
	my $self = shift;
	return $self->getUserPresence( user => $self->username );
}
sub getUserPresence {
	my $self = shift;
	my %arg = @_;

	$arg{user} ||= $self->username;

    my $req = $self->{ua}->get(
		'http://'.$arg{user}.'.jaiku.com/presence/last/json'.
		$self->auth_query,
	);
	if ($req->is_success){
		my $rv = HashInflator->new( JSON::Any->jsonToObj($req->content) );
		#decode_entities( $rv->{line} );
		return $rv;
	}
	return undef;
}

sub getMyInfo {
	my $self = shift;
	return $self->getUserInfo( user => $self->username );
}
sub getUserInfo {
	my $self = shift;
	my %arg = @_;

	$arg{user} ||= $self->username;

    my $req = $self->{ua}->get(
		'http://'.$arg{user}.'.jaiku.com/json'.
		$self->auth_query,
	);
	if ($req->is_success){
		my $content = $req->content;
		$content =~ s/^.*?(\{.+\}).*?$/$1/s;
		return HashInflator->new( JSON::Any->jsonToObj($content) );
	}
	return undef;
}

sub getChannelFeed {
	my $self = shift;
	my %arg = @_;

	return undef unless $arg{channel};

	$arg{channel} =~ s/^#//;

    my $req = $self->{ua}->get(
		'http://jaiku.com/channel/'.$arg{channel}.'/feed/json'.
		$self->auth_query,
	);
    return ($req->is_success) ?  HashInflator->new( JSON::Any->jsonToObj($req->content) ) : undef;
}


sub setPresence {
	my $self = shift;

	my %arg = validate( @_, {
		icon => {
			type => SCALAR,
			optional => 1,
		},
		message => {
			type => SCALAR,
			optional => 1,
		},
		location => {
			type => SCALAR | ARRAYREF,
			optional => 1,
		},
		generated => {
			type => BOOLEAN,
			optional => 1,
		},
	});

	# Now turn them into something interesting
	$arg{icon} =~ s/(\D+)/$Net::Jaiku::iconByName{$1}/
		if exists $arg{icon} && $arg{icon} =~ /\D/;
	$arg{location} = join(', ', @{ $arg{location} }[0,2] )
		if exists $arg{location} && ref $arg{location} eq 'ARRAY';
	$arg{generated} = $arg{generated} ? 1 : 0
		if exists $arg{generated};

    my $req = $self->{ua}->post(
		'http://api.jaiku.com/json',
		{
			user => $self->username,
			personal_key => $self->userkey,
			method => 'presence.send',
			%arg
		}
	);
    if ($req->is_success) {
    	my $rv = JSON::Any->jsonToObj($req->content);
    	return lc($rv->{status}) eq 'ok';
    }
    return undef;
}

# Class methods

# DEPRECATED: Don't use it!
our %JAIKU_ICONS = (
	# Original names
	beer => 322, coffee => 319, computing => 329, eat => 341, home => 392, hurry => 399, morning => 400, sleep => 363, song => 367, toaster => 377, airplain => 316, bike => 388, bus => 317, car => 401, luggage => 373, metro => 372, taxi => 375, train => 378, tram => 304, walk => 325, theatre => 395, happy => 393, love => 347, uzi => 308, snorkeling => 364, bomb => 310, straitjacket => 371, pils => 389, grumpy => 318, megaphone => 352, game => 331, blading => 387, shop => 396, rollator => 358, football => 339, loudspeaker => 303, driller => 333, binoculars => 323, 'ice cream' => 381, toiletpaper => 394, balloons => 348, book => 354, spraycan => 368, scull => 361, wallclock => 326, 'ear muffs' => 346, tv => 328, makeup => 383, lifejacket => 391, storm => 370,
	# Cleaned names
	airplane => 316, aeroplane => 316, pills => 389, 'walking frame' => 358, drill => 333, skull => 361, clock => 326
);

our %iconsByCategory = (
	Transport =>
		[301, 304, 316, 317, 358, 372, 375, 378, 379, 401],
	Weaponry =>
		[308, 310, 343],
	'Household items' =>
		[302, 324, 326, 323, 327, 348, 349, 353, 354, 373, 377, 380, 383, 384, 386, 389, 394, 396, 397],
	'Audio Visual' =>
		[303, 305, 312, 314, 320, 328, 329, 330, 331, 342, 346, 336, 351, 352, 376],
	Clothing =>
		[306, 311, 335, 340, 344, 345, 391, 325],
	'Food and beverages' =>
		[315, 319, 322, 334, 341, 360, 366, 369, 381, 385, 390],
	Sport =>
		[307, 321, 339, 359, 362, 364, 387, 388],
	Activities =>
		[313, 382, 395, 399],
	Tools =>
		[309, 333, 332, 350, 368],
	'Generic icons' =>
		[337, 356],
	Symbols =>
		[338, 357, 363, 367, 347, 392],
	Weather =>
		[365, 370, 374, 398, 400],
	Misc =>
		[318, 355, 361, 371, 393, 402, 403]
);

our %iconById = (
	301 => 'car', 302 => 'alarmclock', 303 => 'loudspeaker', 304 => 'tram', 305 => 'casette', 306 => 'underware', 307 => 'rollerblade', 308 => 'uzi', 309 => 'scoop', 310 => 'bomb', 311 => 'bra', 312 => 'videotape', 313 => 'cigarettes', 314 => 'vinyl', 315 => 'champaign', 316 => 'airplain', 317 => 'bus', 318 => 'grumpy', 319 => 'coffee', 320 => 'camera', 321 => 'basketball', 322 => 'beer', 323 => 'binoculars', 324 => 'boiler', 325 => 'walk', 326 => 'wallclock', 327 => 'trashcan', 328 => 'tv', 329 => 'computing', 330 => 'videocamera', 331 => 'game', 332 => 'cone', 333 => 'driller', 334 => 'popcorn', 335 => 'playshirt', 336 => 'disc', 337 => 'event', 338 => 'exclamationmark', 339 => 'football', 340 => 'footballshoe', 341 => 'eat', 342 => 'gameboy', 343 => 'grenade', 344 => 'hand', 345 => 'hanger', 346 => 'hearingprotector', 347 => 'love', 348 => 'balloons', 349 => 'clock', 350 => 'barrier', 351 => 'laptop', 352 => 'megaphone', 353 => 'microwave', 354 => 'book', 355 => 'middlefinger', 356 => 'notes', 357 => 'question', 358 => 'rollator', 359 => 'shuttlecock', 360 => 'salt', 361 => 'scull', 362 => 'sk8', 363 => 'sleep', 364 => 'snorkeling', 365 => 'snowflake', 366 => 'soda', 367 => 'song', 368 => 'spraycan', 369 => 'sticks', 370 => 'storm', 371 => 'straitjacket', 372 => 'metro', 373 => 'luggage', 374 => 'sun', 375 => 'taxi', 376 => 'technics', 377 => 'toaster', 378 => 'train', 379 => 'wheelchair', 380 => 'zippo', 381 => 'icecream', 382 => 'movie', 383 => 'makeup', 384 => 'bandaid', 385 => 'wine', 386 => 'clean', 387 => 'blading', 388 => 'bike', 389 => 'pils', 390 => 'picnic', 391 => 'lifejacket', 392 => 'home', 393 => 'happy', 394 => 'toiletpaper', 395 => 'theatre', 396 => 'shop', 397 => 'search', 398 => 'cloudy', 399 => 'hurry', 400 => 'morning', 401 => 'car', 402 => 'baby-boy', 403 => 'baby-girl'
);

our %iconByName = (
	# Original names
	reverse %iconById,
	# Cleaned names
	airplane => 316, aeroplane => 316, pills => 389, 'walking frame' => 358, drill => 333, skull => 361, clock => 326
);

our @OfficialIconList = (322, 319, 329, 341, 392, 399, 400, 363, 367, 377, 316, 388, 317, 401, 373, 372, 375, 378, 304, 325, 395, 393, 347, 308, 364, 310, 371, 389, 318, 352, 331, 387, 396, 358, 339, 303, 333, 323, 381, 394, 348, 354, 368, 361, 326, 346, 328, 383, 391, 370);

sub findIcon {
	my $class = shift;
	my $icon = shift || $class;
	return $iconByName{lc $icon} || undef;
}


package HashInflator;

sub new {
	my $class = shift;
	my %hash = (@_ > 1) ? @_ : %{$_[0]};

	foreach my $key (keys %hash){
		if (ref $hash{$key} eq 'HASH'){
			$hash{$key} = new HashInflator($hash{$key});
		}
		elsif(ref $hash{$key} eq 'ARRAY'){
			foreach( @{$hash{$key}} ) {
				$_ = new HashInflator($_);
			}
		}
	}

	return bless \%hash, $class;
}

sub AUTOLOAD {
	my $self = shift;
	our $AUTOLOAD;
	$AUTOLOAD =~ s/.+:://;
	return if $AUTOLOAD =~ /^[A-Z]+$/;
	return $self->{$AUTOLOAD};
}

1;

__END__

=head1 NAME

Net::Jaiku - A perl interface to jaiku.com's API

=head1 SYNOPSIS

	use Net::Jaiku;

	my $jaiku = new Net::Jaiku(
		username => 'Example',
		userkey  => 'API Key'
	);

	my $p = $jaiku->getMyPresence;
	print $p->user->url;

	my $rv = $jaiku->setPresence(
		message => 'Reading a book'
	);

=head1 ABSTRACT

This module allows easy access to Feeds, Presences and Users at
jaiku.com. It requires an API key retreivable from http://api.jaiku.com/
for each username you wish to authenticate.

=head1 CONSTRUCTOR

This module has a single constructor:

=over 4

=item * C<new( ... )>

The C<new> constructor takes the following attributes:

=over 4

=item * C<<username =E<gt> $string>>

This is a jaiku.com username. I<this bit>.jaiku.com

=item * C<<userkey =E<gt> $string>>

The user's key can be obtained by visiting http://api.jaiku.com when
logged in as the user.

=item * C<<timeout =E<gt> $seconds>>

The number of seconds to wait before giving up on the call to Jaiku.
(Optional)

=back

=back

=head1 METHODS

L<Net::Jaiku> has the following methods:

=head2 Feeds

=over 4

=item * C<getFeed()>

Returns the public feed as seen on the front page.

=item * C<getUserFeed( user =E<gt> $string )>

Returns a hashref of the feed for the given user. If no user is
specified, it will return the feed for the current user. If no
user is logged it, it will return undef.

=item * C<getMyFeed()>

A shortcut to the above method for the logged in user. If no
user is logged it, it will return undef.

=item * C<getContactsFeed()>

Retrieve a feed of all your contacts and their presences.

=item * C<getChannelFeed( channel =E<gt> $string )>

Retrieve a feed of the latest posts to a channel.

=item * B<RETURN VALUE>

Feed methods return an object representing the feed. The following
keys are available:

=over 4

=item * C<title>

=item * C<url>

=item * C<stream[n]-E<gt>icon>

=item * C<stream[n]-E<gt>content>

=item * C<stream[n]-E<gt>created_at>

=item * C<stream[n]-E<gt>created_at_relative>

=item * C<stream[n]-E<gt>comments>

=item * C<stream[n]-E<gt>url>

=item * C<stream[n]-E<gt>id>

=item * C<stream[n]-E<gt>title>

=back

=back


=head2 Presences

=over 4

=item * C<getUserPresence( user =E<gt> $string )>

Returns the 'presence' for the given user. If no user is
specified, it will return the feed for the current user. If no
user is logged it, it will return undef.

=item * C<getMyPresence()>

A shortcut to the above method for the logged in user. If no
user is logged it, it will return undef.

=item * B<RETURN VALUE>

Presence methods return an object representing the presence. The
following keys are available:

=over 4

=item * C<line>

=item * C<user-E<gt>avatar>

=item * C<user-E<gt>url>

=item * C<user-E<gt>nick>

=item * C<user-E<gt>first_name>

=item * C<user-E<gt>last_name>

=back

=item * C<setPresence( message =E<gt> $string,
location =E<gt> $string_or_arrayref, icon =E<gt> $integer_or_string,
generated =E<gt> $boolean )>

Set the Jaiku presence for the current user. All options are optional,
but it would be pointless to not set either a C<message> or a
C<location>.


=back


=head2 User Info

=over 4

=item * C<getUserInfo( user =E<gt> $string )>

Returns information for the given user. If no user is
specified, it will return the feed for the current user. If no
user is logged it, it will return undef.

=item * C<getMyInfo()>

A shortcut to the above method for the logged in user. If no
user is logged it, it will return undef.

=item * B<RETURN VALUE>

Info methods return an object representing the information. The
following keys are available:

=over 4

=item * C<avatar>

=item * C<url>

=item * C<nick>

=item * C<first_name>

=item * C<last_name>

=item * C<contacts[n]-E<gt>avatar>

=item * C<contacts[n]-E<gt>url>

=item * C<contacts[n]-E<gt>nick>

=item * C<contacts[n]-E<gt>first_name>

=item * C<contacts[n]-E<gt>last_name>

=back

=back


=head1 SETTERS AND GETTERS

=over 4

=item * C<username( $optional_new_username )>

Returns the current username (after optionally setting)

=item * C<userkey( $optional_new_userkey )>

Returns the current username (after optionally setting)

=back


=head1 NOTES

=head2 Objects

This module returns a custom object called 'HashInflator'. This is used
so you can do $rv->user->id rather than the more cumbersome $rv->{user}->{id}

Once the API settles down, I will investigate creating proper objects that
will auto-inflate when they need to.

=head1 AUTHOR

Rick Measham <rickm@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Rick Measham.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

irc://freenode.net/##jaiku

=cut



