#! /usr/bin/perl
#
#
# $Id: Set.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Set;

use 5.008;
use strict;
use warnings;
use Carp qw/croak/;

use Net::Radius::Server::Base ':set';
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

    return sub { $n->_set(@_) };
}

sub _set
{
    my $self	= shift;
    my $r_args	= shift;

    for my $arg (sort keys %$self)
    {
	next if $arg =~ /^_/;
	if ($self->can('set_' . $arg))
	{
	    no strict 'refs';
	    my $m = 'set_' . $arg;
	    $self->log(4, "Invoking set method $m");
	    $self->$m($r_args, @_);
	}
    }

    if ($self->can('result') and exists $self->{result})
    {
	my $r = $self->result;
	$self->log(4, "Set returning $r");
	return $r;
    }

    $self->log(4, "Set returning CONTINUE by default");
    return NRS_SET_CONTINUE;
}

42;

__END__

=head1 NAME

Net::Radius::Server::Set - Base class for set methods

=head1 SYNOPSIS

  package My::Radius::Set;
  use base 'Net::Radius::Server::Set';

  __PACKAGE__->mk_accessors(qw/foo bar baz/);

  sub set_foo { ... }
  sub set_bar { ... }
  sub set_baz { ... }

  # Meanwhile, in a configuration file nearby...
  my $set = My::Radius::Set->new({ foo => 'x', bar => 'y' });
  my $set_sub = $set->mk;
  ...

  # Alternatively, in a more compact notation...
  my $set_sub = My::Radius::Set->mk({ foo => 'x', bar => 'y' });

=head1 DESCRIPTION

C<Net::Radius::Server::Set> is a base class for developing "set"
methods to be used in C<Net::Radius::Server> rules.

C<Net::Radius::Server::Set>'s C<new()> will honor a property called
C<result>, that will be used as the return value of the
method. Otherwise, C<NRS_SET_CONTINUE> will be returned. Note that you
can define the C<set_result> hook, causing the result of the request
to be calculated at packet processing time.

=over

=item C<-E<gt>new($hashref)>

Creates a new C<Net::Radius::Server::Set> object. C<$hashref>
referenes a hash with the attributes that will apply to this object,
so that multiple set methods (that will share the same underlying
object) can be created and given to different rules.

=item C<$self-E<gt>mk()> or C<__PACKAGE__-E<gt>mk($hashref)> 

This method returns a sub suitable for calling as a set method for a
C<Net::Radius::Server> rule. The resulting sub will return whatever is
defined in its C<result> property.

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

=item C<-E<gt>_set()>

This method is internally called by the sub returned by the call to
C<-E<gt>mk()> and should not be called explicitly. This method
iterates through the existing elements in the object -- It is assumed
that it is a blessed hash ref, as left by C<Class::Accessor>.

This method tries to invoke C<$self->set_$element(@_)>, passing the
same arguments it receives - Note that normally, those are the same
that were passed to the sub returned by the factory.

See the source of C<Net::Radius::Server::Set::Simple>. This is much
simpler than it sounds. Really.

Arguments with no corresponding C<set_*> method are
ignored. Arguments whose name start with "_" are also ignored.

After invoking all the required C<set_*> methods, whatever is
specified in the C<result> property or the default value is returned.

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
  Revision 1.4  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.3  2006/12/14 15:52:25  lem
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


