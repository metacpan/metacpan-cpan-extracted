#! /usr/bin/perl
#
#
# $Id: Rule.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Rule;

use 5.008;
use strict;
use warnings;

use base qw/Net::Radius::Server::Base/;
use Net::Radius::Server::Base qw/:all/;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

__PACKAGE__->mk_accessors(qw/match_methods set_methods/);

sub eval
{
    my $self = shift;
    $self->match_methods([]) unless $self->match_methods;
    $self->set_methods([]) unless $self->set_methods;

    $self->log(4, "Starting eval");

    my $c = 0;
    # Verify match methods
    for my $m (@{$self->match_methods})
    {
	$self->log(4, "Invoking match method $c");
	unless ($m->(@_) == NRS_MATCH_OK)
	{
	    $self->log(3, "Method $c did not match - Rule fail");
	    return;
	}
	$c++;
    }

    $self->log(4, "Rule matches");

    my $r = NRS_SET_DISCARD;	# Default retval

    $c = 0;
    # Invoke set methods
    for my $s (@{$self->set_methods})
    {
	$self->log(4, "Invoking set method $c");
	$r = $s->(@_);
	if ($r & NRS_SET_SKIP)
	{
	    $self->log(3, "Set method returned $c (skip)");
	    last;
	}
    }

    $self->log(4, "Set returning $r");
    return $r;
}


42;

__END__

=head1 NAME

Net::Radius::Server::Rule - Rules for Net::Radius::Server

=head1 SYNOPSIS

  use Net::Radius::Server::Rule;
  my $rule = new Net::Radius::Server::Rule({
    match_methods => \@match_methods,
    set_methods => \@set_methods,
  });

  # Deep within the bowels of a RADIUS server...
  my $ret = $rule->eval(\%info);
  ...

=head1 DESCRIPTION

C<Net::Radius::Server::Rule> implements a simple mechanism to evaluate
RADIUS request packets using match methods. After the match methods
determine that the given rule applies to the request, the set methods
can modify a response packet to be sent to the RADIUS client.

Evaluation and application of the rule is done by the C<-E<gt>eval()>
method. This is normally invoked within the server code. C<\%info> is
a hashref with the same structure described in C<Net::Radius::Server>.

The following attributes are available for object creation or
manipulation via accessors created with C<Class::Accessor>:

=over

=item C<match_methods>

A reference to a list of match methods to be invoked in order. All the
provided methods must match (ie, return NRS_MATCH_OK) in order for the
rule to be applied.

=item C<set_methods>

A reference to a list of match methods to be invoked in order, in case
the rule can be applied to the current request. The return value of
the last set method executed will be returned by the C<-E<gt>eval()>
method.

If no set methods are specified, C<Net::Radius::Server::Rule> returns
NRS_SET_DISCARD by default.

=item C<description>

This attribute is inherited, and allows for the specification of a
name for this rule. Defaults to the class, file and line where this
rule has been created.

=back

The return value of the C<-E<gt>eval()> method is defined by the last
set method executed. C<undef> is returned if the rule did not match.

=head2 EXPORT

None by default.

=head1 HISTORY

  $Log$
  Revision 1.7  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.6  2006/12/14 15:52:25  lem
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
