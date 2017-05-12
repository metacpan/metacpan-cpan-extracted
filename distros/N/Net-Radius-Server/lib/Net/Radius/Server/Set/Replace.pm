#! /usr/bin/perl
#
#
# $Id: Replace.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Set::Replace;

use 5.008;
use strict;
use warnings;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use Net::Radius::Server::Base qw/:set/;
use base qw/Net::Radius::Server::Set/;
__PACKAGE__->mk_accessors(qw/attr vsattr result/);

sub set_attr
{
    my $self = shift;
    my $r_data = shift;

    my $rep = $r_data->{response};
    my $spec = $self->attr || [];
    
    my $i = 0;
    while ($i < @$spec)
    {
	my $attr = $spec->[$i];
	my $cond = $spec->[$i + 1];
	my $newv = $spec->[$i + 2];

	if (not grep { $_ eq $attr } $rep->attributes)
	{
	    $self->log(4, "Skip $attr replacement");
	    $i += 3;
	    next;
	}

	my $curv = $rep->attr($attr);

	if (not ref($cond))
	{
	    if ($curv eq $cond)
	    {
		$self->log(4, "Replace $attr $curv with $newv (eq $cond)");
		$rep->set_attr($attr, $newv);
	    }
	    else
	    {
		$self->log(4, 
			   "Don't replace $attr $curv with $newv (!= $cond)");
	    }
	}
	elsif (ref($cond) eq 'Regexp')
	{
	    if ($curv =~ m/$cond/)
	    {
		$self->log(4, "Replace $attr $curv with $newv (=~ $cond)");
		$rep->set_attr($attr, $newv);
	    }
	    else
	    {
		$self->log(4, 
			   "Don't replace $attr $curv with $newv (!~ $cond)");
	    }
	}
	elsif (ref($cond) eq 'NetAddr::IP')
	{
	    my $ip = new NetAddr::IP $curv;
	    if ($ip and $cond->contains($ip))
	    {
		$self->log(4, "Replace $attr $curv with $newv ($ip)");
		$rep->set_attr($attr, $newv);
	    }
	    else
	    {
		$self->log(4, 
			   "Don't replace $attr $curv with $newv "
			   . "(!contains $cond)");

	    }
	}
	else
	{
	    die $self->description . ": Don't know how to work with $cond\n";
	}

	$i += 3;
    }
}

sub set_vsattr
{
    my $self = shift;
    my $r_data = shift;

    my $rep = $r_data->{response};
    my $spec = $self->vsattr || [];

    my $i = 0;
    while ($i < @$spec)
    {
	my $vend = $spec->[$i];
	my $attr = $spec->[$i + 1];
	my $cond = $spec->[$i + 2];
	my $newv = $spec->[$i + 3];

	if (not grep { $_ eq $attr } $rep->vsattributes($vend))
	{
	    $self->log(4, "Skip $vend" . ".$attr replacement");
	    $i += 4;
	    next;
	}

	for my $curv (@{$rep->vsattr($vend, $attr) || []})
	{
	    if (not ref($cond))
	    {
		if ($curv eq $cond)
		{
		    $self->log(4, "Replace $vend" . ".$attr $curv with $newv"
			       . " (eq $cond)");
		    $curv = $newv;
		}
		else
		{
		    $self->log(4, "Don't replace $vend" 
			       . ".$attr $curv with $newv (ne $cond)");
		}
	    }
	    elsif (ref($cond) eq 'Regexp')
	    {
		if ($curv =~ m/$cond/)
		{
		    $self->log(4, "Replace $vend" . ".$attr $curv with $newv"
			       . " (=~ $cond)");
		    $curv = $newv;
		}
		else
		{
		    $self->log(4, "Don't replace $vend" 
			       . ".$attr $curv with $newv (=~ $cond)");
		}
	    }
	    elsif (ref($cond) eq 'NetAddr::IP')
	    {
		my $ip = new NetAddr::IP $curv;
		if ($ip and $cond->contains($ip))
		{
		    $self->log(4, "Replace $vend" . ".$attr $curv with $newv"
			       . " ($cond)");
		    $curv = $newv;
		}
		else
		{
		    $self->log(4, "Don't replace $vend" 
			       . ".$attr $curv with $newv ($cond)");
		}

	    }
	    else
	    {
		die $self->description . 
		    ": Don't know how to work with $cond\n";
	    }
	}
	$i += 4;
    }
}

42;

__END__

=head1 NAME

Net::Radius::Server::Set::Replace - Perform replacements on the RADIUS response

=head1 SYNOPSIS

  use Net::Radius::Server::Base qw/:set/;
  use Net::Radius::Server::Set::Replace;

  my $replace = Net::Radius::Server::Set::Replace->new
    ({
      result => NRS_SET_RESPOND,
      vsattr => [
        [ 'Cisco', 'cisco-avpair' => qr/datum=foo/ => 'bad=baz' ],
      ],
      attr => [
        [ 'Reply-Message', qr/Login Succesful/ => "Welcome home!!!\r\n\r\n",
          'Reply-Message', qr/Invalid/ => "Go away stranger\r\n\r\n",
         ],
      ]});
  my $replace_sub = $set->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Set::Replace> provides a simple mechanism
allowing changes to be made to RADIUS packets.

See C<Net::Radius::Server::Set> for general usage guidelines. The
relevant attributes that control the matching of RADIUS requests are:

=over

=item C<attr>

Takes a listref containing groups of three elements: The first is the
name of the attribute to replace. The second, is the replacement
condition. It must be true in order for the replacement to be
completed. The third element is the value to be stored in the named
attribute.

The replacement condition can be of any of the following types:

=over

=item B<scalar>

An exact match will be attempted.

=item B<regexp>

The value of the attribute must match the given regexp.

=item B<NetAddr::IP>

The value of the attribute must be convertible into a NetAddr::IP(3)
subnet. In this case, the comparison matches if the given
NetAddr::IP(3) range contains the current attribute.

The comparison does not match if the attribute value cannot be
converted into a NetAddr::IP(3) object.

=back

=item C<result>

The result of the invocation of this set method. See
C<Net::Radius::Server::Set> for more information. The example shown in
the synopsis would cause an inmediate return of the packet. Other set
methods after the current one won't be called at all.

=item C<vsattr>

Just as C<attr>, but dealing with
C<Net::Radius::Packet-E<gt>set_vsattr()> instead.

=back

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

Perl(1), NetAddr::IP(3), Net::Radius::Server(3),
Net::Radius::Server::Set(3), Net::Radius::Packet(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


