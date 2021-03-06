package Net::Radius::Server::Base;

use 5.008;
use strict;
use warnings;

require Exporter;
use base qw/Net::Radius::Server Exporter/;

# These are constants useful for the "match" methods
use constant NRS_MATCH_FAIL	=> 0x0;
use constant NRS_MATCH_OK	=> 0x1;

# These constants are used for the "set" methods
use constant NRS_SET_CONTINUE	=> 0x0;
use constant NRS_SET_SKIP	=> 0x1;
use constant NRS_SET_RESPOND	=> 0x2;
use constant NRS_SET_DISCARD	=> 0x4;

our %EXPORT_TAGS = ( 
		     match	=> 
		     [ qw(
			  NRS_MATCH_FAIL
			  NRS_MATCH_OK
			  )],
		     set	=> 
		     [ qw(
			  NRS_SET_CONTINUE
			  NRS_SET_SKIP
			  NRS_SET_RESPOND
			  NRS_SET_DISCARD
			  )],
);

do 
{
    my %seen = ();
    my @all = ();
    for my $k (keys %EXPORT_TAGS)
    {
	push @all, grep { ! $seen{$_}++ } @{$EXPORT_TAGS{$k}};
    }
    $EXPORT_TAGS{all} = \@all;
};

Exporter::export_ok_tags('all');

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

__PACKAGE__->mk_accessors(qw/description log_level/);

sub log
{
    my $self = shift;
    my $level = shift;

    return unless $level <= ($self->log_level || 2);
    if ($self->can('description'))
    {
	warn $self->description . ": " . join(" ", @_) . "\n";
    }
    elsif (ref($self))
    {
	warn ref($self) . ": " . join(" ", @_) . "\n";
    }
    else
    {
	warn @_, "\n";
    }
}

sub new
{
    my $class	= shift;
    my $self = $class->SUPER::new(@_);
    my @c = caller;
    $self->description((ref($class) || $class) . " ($c[1]:$c[2])")
	unless $self->description;
    return $self;
}
42;
__END__

=head1 NAME

Net::Radius::Server::Base - Base definitions and utility methods and factories

=head1 SYNOPSIS

  package My::Radius::Thing;
  use base 'Net::Radius::Server::Base';

  # Alternatively...

  use Net::Radius::Server::Base qw(:match);

  ...

=head1 DESCRIPTION

C<Net::Radius::Server::Base> provides a number of utility methods and
services useful for "match" and "set" sub-classes of
C<Net::Radius::Server>.

The following methods are provided or overriden:

=over

=item C<-E<gt>new(...)>

This method is modified so that C<SUPER::new()> is invoked and then,
the value of the description property is
initialized. C<Class::Accessor> is used as a base class, so we'll
inherit the C<new()> method defined there.

=item C<-E<gt>description()>

This is an accessor to an object property of the same name, that
stores te description of this object. It is automagically initialized
to the class name of the object, the file name and line number where
it was created.

This is used in errors and warnings to make it easier to spot
problems.

=item C<-E<gt>log($level, $msg, ...)>

A simple logging facility. The current implementation causes messages
to be sent to C<warn()> when the C<$level> is lower than or equal to
the current C<-E<gt>log_level>.

=item C<-E<gt>log_level($level)>

Specifies the current logging level. This is a number (defaults to 2)
that controls how verbose are the logs generated by a given
object. Only messages with a level lower or equal to the current log
level are produced.

As a general rule, the following are guidelines about how to set the
log level:

=over

=item B<Level 1>

Only exceptions and failures - Events that cause a process to fail.

=item B<Level 2>

Includes less severe exceptions and rejects.

=item B<Level 3>

Includes general internal conditions within the code. Generally useful
to determine the execution thread within a class.

=item B<Level 4>

Most detailed data, including normal behavior. This is used for
debugging purposes.

=back

=back

=head2 EXPORT

Usually, constants are imported using one of the following keywords:

=over

=item B<:match>

Export the constants that are useful for B<match> methods and classes,
namely:

=over

=item C<NRS_MATCH_FAIL>

This should be returned when the match method did not match the given
request. An example would be a match method looking for a certain
domain in the Username field of the RADIUS request. If the required
value is not present, the match method could return NRS_MATCH_FAIL to
tell the server that the rule should not apply to this request.

=item C<NRS_MATCH_OK>

When the match method does match the given request, NRS_MATCH_OK
should be returned. This causes the next match method to be
invoked. After all the match methods have returned NRS_MATCH_OK, the
packet will be passed to the set methods for processing.

=back

=item B<:set>

Export the constants that are useful for B<set> methods and classes,
namely:

=over

=item C<NRS_SET_CONTINUE>

Causes the next set method within this rule to be invoked. This is the
default return code for set methods.

=item C<NRS_SET_SKIP>

Causes the remaining set methods in the current rule to be
skipped. The next rule will be evaluated, starting with the match
methods.

=item C<NRS_SET_RESPOND>

Causes the current response packet to be returned to the RADIUS client
as the response to its request.

=item C<NRS_SET_DISCARD>

Causes the current response packet to be abandonned. No further
processing will occur and no response will be sent. This is a silent
packet discard.

=back

=item B<:all>

Includes all of the above. Included just for completion, as it is
seldom necessary.

=back

=head1 HISTORY

  $Log$
  Revision 1.4  2006/12/14 15:52:25  lem
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
