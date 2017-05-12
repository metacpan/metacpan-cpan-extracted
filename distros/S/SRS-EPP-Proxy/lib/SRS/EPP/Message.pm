# vim: filetype=perl:noexpandtab:ts=3:sw=3
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use strict;
use warnings;

package SRS::EPP::Message;
{
  $SRS::EPP::Message::VERSION = '0.22';
}
use Moose;

has 'xml' =>
	is => "rw",
	;

has 'message' =>
	is => "rw",
	handles => [qw(to_xml)],
	trigger => sub { $_[0]->message_trigger },
	;

# for use with 'around', 'after' modifiers
sub message_trigger { }

has 'error' =>
	is => "rw",
	;

use Scalar::Util qw(refaddr);

use overload '""' => sub {
	my $self = shift;
	my $class = ref $self;
	$class =~ s{SRS::EPP::}{};
	my @bits = map { lc $_ } split "::", $class;
	my @ids = eval{ $self->ids };
	if ( !@ids ) {
		@ids = sprintf("0x%x",(0+$self));
	}
	push @bits, @ids;
	s{:}{\xff1a}g for @bits;
	join ":", @bits
	},
	'0+' => sub {
	refaddr(shift);
	},
	fallback => 1;

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SRS::EPP::Message - abstract type for a single message particle

=head1 SYNOPSIS

 my $msg = SRS::EPP::Message->new(
     message => $object,
     xml => $xml,
     error => $message,
     );
 # convert a message to XML
 $message->to_xml;

=head1 DESCRIPTION

This class is a common ancestor of EPP commands and responses, as well
as SRS requests and responses.  Currently the only method that all of
these implement is conversion to XML; however parsing is likely to
follow.

=head1 SEE ALSO

L<SRS::EPP::Command>, L<SRS::EPP::Response>

=for thought

What space should we stick SRS messages under?  I reckon maybe plain
SRS::Request:: and SRS::Response::, and subclass them...

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
