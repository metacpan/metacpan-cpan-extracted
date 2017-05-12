# ===========================================================================
# POE::Component::Growl - version 1.00 - 31 Jul 2005
# 
# Growl notification dispatcher for POE
# 
# Author: Alessandro Ranellucci <aar@cpan.org>
# Copyright (c) 2005 - All Rights Reserved.
# 
# See below for documentation.
#Ê

package POE::Component::Growl;

use strict;
use vars qw($VERSION);

use Carp qw(croak);
use Mac::Growl ':all';
use POE;

$VERSION = '1.00';

# object fields ("SF" stands for "self")
sub SF_ALIAS 	() { 0 }
sub SF_APPNAME 	() { 1 }
sub SF_NOTIF 	() { 2 }

sub spawn {
	my $type = shift;
	croak "$type requires an even number of parameters" if @_ % 2;
	my %params = @_;
	
	# let's check params
	my $alias = delete $params{Alias} || 'Growl';
	my $appname = delete $params{AppName} || croak("Missing AppName parameter");
	my $notif = delete $params{Notifications} || croak("Missing Notifications parameter");
	my $defaultnotif = delete $params{DefaultNotifications} || $notif;
	my $icon = delete $params{IconOfApp} || undef;
	croak("Unknown parameters: ", join(', ', sort keys %params))
		if scalar keys %params;
	
	# register our app with Mac::Growl
	RegisterNotifications($appname, $notif, $defaultnotif, $icon);
	my $self = bless [
		$alias,
		$appname,
		$notif
	], $type;
	
	# register session with POE
	POE::Session->create(
		object_states => [
			$self => {
				_start => '_start',
				post => 'post'
			}
		]
	);
	
	return $self;
}

sub _start {
	my ($object, $kernel) = @_[OBJECT, KERNEL];
	$kernel->alias_set( $object->[SF_ALIAS] );
}

sub post {
	my ($object, $kernel, $not) = @_[OBJECT, KERNEL, ARG0];
	$object->notify($not);
}

sub notify {
	my ($self, $not) = @_;
	
	&PostNotification(
		$self->[SF_APPNAME],
		@$not{ qw/name title descr/ },
		map { $not->{$_} || 0 } qw/sticky priority/,
		$not->{imagepath}
	);
}

1;

__END__

=head1 NAME

POE::Component::Growl - Growl notification dispatcher for POE

=head1 SYNOPSIS

 use POE qw(Component::Growl);
 
 # instantiate your Growl notifier:
 POE::Component::Growl->spawn(
    Alias 				 => 'MyGrowl',
    AppName 			 => 'MyApplication',
    Notifications 		 => [ 'one', 'two', 'three' ]
 );
 
 # then post notifications from other POE sessions:
 sub myevent {
 	my $kernel = $_[KERNEL];
 	...
 	my $notification = {
 	   name => 'one',
 	   title => 'Title of notification',
 	   descr => 'Text of notification'
 	};
 	$kernel->post('MyGrowl', 'post', 'one', $notification);
 }
 
 # you can also directly access the notifier object instead of posting
 # notificaton through POE queue:
 my $growl =  POE::Component::Growl->spawn(...);
 $growl->notify($notification);

=head1 ABSTRACT

POE::Component::Growl provides a facility for notifying events through Growl
using the L<Mac::Growl> module as back-end. Integration with POE's architecture
allows easy, non-blocking notifications.

Multiple notifiers can be spawned within the same POE application with multiple
default options.

=head1 PUBLIC METHODS

=over 4

=item C<spawn>

A program must spawn at least one POE::Component::Growl instance before it can
perform Growl notifications. Each instance registers itself with Growl itself
by passing a few parameters to it, and a reference to the object is returned for 
optional manual handling (see C<notify> method below).

The following parameters can be passed to the C<spawn> constructor (AppName and 
Notifications are required).

=over 8

=item AppName

This must contain the name of the application. It may be a free string as it 
isn't required to match any existing file name; its purpose is only to let Growl
define user preferences for each application.

=item Notifications

This must be an arrayref containing the list of possible notifications from our 
application. These names will be displayed in Growl preference pane to let
users customize options for each notification.

=item DefaultNotificatons

(Optional) This parameter can contain an arrayref with the list of notifications 
to enable by default. If DefaultNotifications isn't provided, POE::Component::Growl
will enable all available notifications, otherwise the user will have to manually
enable those which aren't included here.

=item Alias

(Optional) This parameter will be used to set POE's internal session alias. This is 
useful to post events and is also very important if you instantiate multiple notifiers.
If left empty, the alias will be set to "Growl".

=item IconOfApp

(Optional) This parameter can contain the name of an application whose icon is to use
by default.

=back

=item C<notify>

This method lets you post notifications without injecting them to POE's queue. While 
that way is preferred, C<notify> may be useful for some particular purposes.

	$growl->notify($notification);

See below for an explanation of the C<$notification> hashref.

=head1 POE EVENTS

=over 4

=item C<post>

Posting this event to your POE::Component::Growl notifier lets you pass messages
to Growl from inside your POE application:

	$kernel->post('MyGrowl', 'post', $notification);

MyGrowl is the alias name (see above about Alias parameter), and C<$notification> is a 
hashref with message (see below);

=head1 NOTIFICATIONS

Each notification must be passed to POE::Component::Growl as a hashref with the 
following values:

=over 4

=item name

The name of the notification (should be one of the Notifications list previously passed
to the C<spawn> constructor, see above).

=item title
=item description

Title and description to be displayed by Growl.

=item sticky

(Optional) Set this flag to 1 to cause the notification to remain until manually dismissed 
by the user. If undefined or set to false, the notification will time out according
to Growl default settings.

=item priority

(Optional) This value may range from -2 for low priority to 2 for high priority.

=item imagepath

(Optional) This can be an UNIX path to a file containing the image for the notification.

=back

For detailed information and examples about these items, see
L<http://growl.info/documentation/applescript-support.php>. It is specific to AppleScript
but the concepts apply to this module as well, except that file paths for images are Unix 
paths, not URLs.

=head2 Unicode

POE::Component::Growl and Mac::Growl expect strings to be passed as UTF-8, if they 
have high-bit characters. See Mac::Growl docs for more information.

=head1 SEE ALSO

http://growl.info
#growl on irc.freenode.net
Mac::Growl
POE

=head1 AVAILABILITY

Latest versions can be downloaded from CPAN. You are very welcome to write mail 
to the author (aar@cpan.org) with your comments, suggestions, bug reports or complaints.

=head1 AUTHOR

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Alessandro Ranellucci. All Rights Reserved.
POE::Component::Growl is free software, you may redistribute it and/or modify it under 
the same terms as Perl itself.

=cut