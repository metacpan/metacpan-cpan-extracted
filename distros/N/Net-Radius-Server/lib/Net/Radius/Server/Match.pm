#! /usr/bin/perl
#
#
# $Id: Match.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Match;

use 5.008;
use strict;
use warnings;
use Carp qw/croak/;

use Net::Radius::Server::Base ':match';
use base 'Net::Radius::Server::Base';
our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

sub mk
{
    my $self = shift;
    croak "->mk() cannot have arguments when in object-method mode\n" 
	if ref($self) and $self->isa('UNIVERSAL') and @_;

    my $n = $self;

    if (@_)
    {
	$n = $self->new(@_);
	die "Failed to create new object\n" unless $n;
    }

    return sub { $n->_match(@_) };
}

sub _match
{
    my $self	= shift;
    my $r_args	= shift;

    for my $arg (sort keys %$self)
    {
	my $n = NRS_MATCH_OK;
	next if $arg =~ /^_/;
	if ($self->can('match_' . $arg))
	{
	    no strict 'refs';
	    my $m = 'match_' . $arg;
	    $self->log(4, "Invoking match method $m");
	    $n = $self->$m($r_args, @_);
	}
	unless ($n == NRS_MATCH_OK)
	{
	    if ($r_args->{dict})
	    {
		$self->log(2, "Fail request from " . 
			   ($r_args->{request}->attr
			    ($r_args->{dict}->attr_name(4))
			    || '(no NAS-IP-Address)')
			   . " [" . ($r_args->{peer_addr} || '(no peer)') 
			   . "] for user " 
			   . ($r_args->{request}->attr
			      ($r_args->{dict}->attr_name(1))
			      || '(no user)'));
	    }
	    else
	    {
		$self->log(2, "Fail request from ["
			   . ($r_args->{peer_addr} || '(no peer)')
			   . "] and no dictionary");
	    }
	    $self->log(4, "Return $n from match method");
	    return $n;
	}
    }
    
    if ($r_args->{dict})
    {
	$self->log(2, "Match request from " . 
		   ($r_args->{request}->attr
		    ($r_args->{dict}->attr_name(4))
		    || '(no NAS-IP-Address)')
		   . " [" . ($r_args->{peer_addr} || '(no peer)')
		   . "] for user " 
		   . ($r_args->{request}->attr
		      ($r_args->{dict}->attr_name(1))
		      || '(no user)'));
    }
    else
    {
	$self->log(2, "Match request from ["
		   . ($r_args->{peer_addr} || '(no peer)')
		   . "] and no dictionary");
    }
    return NRS_MATCH_OK;	# Fail by default
}

42;

__END__

=head1 NAME

Net::Radius::Server::Match - Base class for match methods

=head1 SYNOPSIS

  package My::Radius::Match;
  use base 'Net::Radius::Server::Match';

  __PACKAGE__->mk_accessors(qw/foo bar baz/);

  sub match_foo { ... }
  sub match_bar { ... }
  sub match_baz { ... }

  # Meanwhile, in a configuration file nearby...
  my $match = My::Radius::Match->new({ foo => 'x', bar => 'y' });
  my $match_sub = $match->mk;
  ...

  # Alternatively, in a more compact notation...
  my $match_sub = My::Radius::Match->mk({ foo => 'x', bar => 'y' });

=head1 DESCRIPTION

C<Net::Radius::Server::Match> is a base class for developing "match"
methods to be used in C<Net::Radius::Server> rules.

=over

=item C<-E<gt>new($hashref)>

Creates a new C<Net::Radius::Server::Match> object. C<$hashref>
referenes a hash with the attributes that will apply to this object,
so that multiple match methods (that will share the same underlying
object) can be created and given to different rules.

=item C<$self-E<gt>mk()> or C<__PACKAGE__-E<gt>mk($hashref)> 

This method returns a sub suitable for calling as a match method for a
C<Net::Radius::Server> rule. The resulting sub will return either
C<NRS_MATCH_OK> or C<NRS_MATCH_FAIL> depending on its result.

The sub contains a closure where the object attributes -- Actually,
the object itself -- are kept.

When invoked as an object method (ie, C<$self-E<gt>mk()>), no
arguments can be given. The object is preserved as is within the
closure.

When invoked as a class method (ie, C<__PACKAGE__-E<gt>mk($hashref)>),
a new object is created with the given arguments and then, this object
is preserved within the closure. This form is useful for compact
filter definitions that require little or no surrounding code or
holding variables.

=item C<-E<gt>_match()>

This method is internally called by the sub returned by the call to
C<-E<gt>mk()> and should not be called explicitly. This method
iterates through the existing elements in the object -- It is assumed
that it is a blessed hash ref, as left by C<Class::Accessor>.

This method tries to invoke C<$self->match_$element(@_)>, passing the
same arguments it receives - Note that normally, those are the same
that were passed to the sub returned by the factory.

See the source of C<Net::Radius::Server::Match::Simple>. This is much
simpler than it sounds. Really.

The calls are done in "short circuit". This means that the first
method returning C<NRS_MATCH_FAIL> will cause this result to be
returned.

Arguments with no corresponding C<match_*> method are
ignored. Arguments whose name start with "_" are also ignored.

By default, this method will return C<NRS_MATCH_OK>.

=back

=head2 Methods to Provide in Derived Classes

As shown in the example in the SYNOPSIS, your derived class must
provide a C<match_*> method for each attribute you define.

The method must return any of the C<NRS_MATCH_*> constants to indicate
its result.

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.6  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.5  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), Class::Accessor(3), Net::Radius::Server(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


