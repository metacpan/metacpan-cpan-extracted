package Template::Plugin::Session;

use Apache::Session::Flex;
use Template::Plugin;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use strict;

$VERSION = '0.01';

sub new {
	my ($class, $context, $id, @args) = @_; 
	my %session;
	eval {
		tie %session, 'Apache::Session::Flex', $id, ( ref $args[0] ? $args[0] : {@args} );
	};
	$context->throw('Session',"Can't create/restore session with id '$id'") if $@;
	bless {
		_CONTEXT => $context,
		session  => \%session,
	}, $class;
}

sub get {
	my $self = shift;
	my @args = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
	if ( ! @args ) {
		@args = keys %{$self->{session}};
	}
	my @ary;
	foreach ( @args ) {
		push @ary, $self->{session}->{$_};
	}
	return @ary;
}

sub set {
	my ($self, @args) = @_;
	my $config = @args && ref $args[-1] eq 'HASH' ? pop(@args) : {};
	foreach ( keys %$config ) {
		# to avoid ovverride _session_id special key
		next if /^_session_di$/;
		$self->{session}->{$_} = $config->{$_};
	}
	return '';
}

sub delete {
	my $self = shift;
	my @args = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
	foreach ( @args ) {
		# to avoid ovverride _session_id special key
		next if /^_session_id$/;
		delete $self->{session}->{$_};
	}
	return '';
}

sub destroy {
	my $self = shift;
	tied(%{$self->{session}})->delete;
}

1;
__END__

=pod 

=head1 NAME

Template::Plugin::Session - Template Toolkit interface to Apache::Session

=head1 SYNOPSIS

   [% USE my_sess = Session (undef,
            { Store => 'File' 
              Generate => 'MD5',
              Lock => 'Null',
              Serialize => 'Storable',
              Directory => '/tmp/session_data/' } %]

   # Getting single session value
   SID = [% my_sess.get('_session_id') %]

   # Getting multiple session values
   [% FOREACH s = my_sess.get('_session_id','foo','bar') %]
   * [% s %]
   [% END %]
   # same as
   [% keys = ['_session_id','foo','bar'];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]
   [% END %]

   # Getting all session values
   [% FOREACH s = my_sess.get %]
   * [% s %]
   [% END %]

   # Setting session values:
   [% my_sess.set('foo' => 10, 'bar' => 20, ...) %]

   # Deleting session value(s)
   [% my_sess.delete('foo', 'bar') %]
   # same as
   [% keys = ['foo', 'bar'];
      my_sess.delete(keys) %]

   # Destroying session
   [% my_sess.destroy %]

=head1 DESCRIPTION

This Template Toolkit plugin provides an interface to Apache::Session 
module wich provides a persistence framework for session data.

A Session plugin object can be created as follows:

   [% options = { 
         Store => 'File' 
         Generate => 'MD5',
         Lock => 'Null',
         Serialize => 'Storable',
         Directory => '/tmp/session_data/'
        } %] 
   # for a first time session generation
   [% USE my_sess = Session ( undef, options ) %]

   # to retrieve session by id
   [% USE my_sess = Session ( 'b7cc652e2944b8f77651d1a122cdc5f2', options ) %]

The C<options> keys are identical to Apache::Session::Flex.

With this hash you must provide the store, serializer, id generator
and whatever arguments are expected by the backing store and lock 
manager that you've chosen.

Please see the documentation for L<Apache::Session::Flex|Apache::Session::Flex>
and for store/lock modules in order to pass right arguments.

If the constructor cannot create a session instance using the arguments 
passed, a C<Session> Exception is thrown, which will need to be
caught appropriately:

   [% TRY %]
      [% USE my_sess = Session ( 'a2414cb819502fa78e0e9187e95f53e8', options ) %]
   [% CATCH Session %]
      Can't create/restore session id
   [% CATCH %]
      Unexpected exception: [% error %]
   [% END %]

You can then use the plugin methods.

=head1 METHODS

=head2 get([array])

Reads a session value(s) and returns an array containing the keys values:

   Session id is [% my_sess.get('_session_id') %]

   [% FOREACH s = my_sess.get('foo', 'bar') %]
   * [% s %]
   [% END %]

Also it is possible to call C<get> method:

   [% keys = [ 'foo', 'bar' ];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]
   [% END %]

Called with no args, returns all keys values.

=head2 set(hash)

Set session values 

   [% my_sess.set('foo' => 10, 'bar' => 20, ...) %]

Called with no args, has no effects.

=head2 delete(array)

Delete session values 

   [% my_sess.delete('foo', 'bar', ...) %]

Also it is possible to call C<delete> method:

   [% keys = [ 'foo', 'bar' ];
      my_sess.delete(keys) %]

Called with no args, has no effects.

=head2 destroy

Destroy current session

   [% my_sess.destroy %]

=head1 AUTHORS

Enrico Sorcinelli <enrico@sorcinelli.it>

=head1 BUGS 

This library has been tested by the author with Perl versions 5.005,
5.6.0 and 5.6.1 on different platforms: Linux 2.2 and 2.4, Solaris 2.6
and 2.7.

Send bug reports and comments to: enrico@sorcinelli.it.
In each report please include the version module, the Perl version,
the Apache, the mod_perl version and your SO. If the problem is 
browser dependent please include also browser name and
version.
Patches are welcome and I'll update the module if any problems 
will be found.

=head1 VERSION

Version 0.01

=head1 SEE ALSO

Apache::Session, Apache::Session::Flex, Template, Apache, perl

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2003 Enrico Sorcinelli. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself. 

=cut
