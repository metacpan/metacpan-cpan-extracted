package TM::ResourceAble;

use strict;
use warnings;

use Class::Trait 'base';

our @REQUIRES  = qw(last_mod);

use Data::Dumper;
use Time::HiRes;

=pod

=head1 NAME

TM::ResourceAble - Topic Maps, abstract trait for resource-backed Topic Maps

=head1 SYNOPSIS

   package MyNiftyMap;

     use TM;
     use base qw(TM);
     use Class::Trait ('TM::ResourceAble');
 
     1;

   my $tm = new MyNiftyMap;
   $tm->url ('http://nirvana/');

   warn $tm->mtime;

   # or at runtime even:

   use TM;
   Class::Trait->apply ('TM', qw(TM::ResourceAble));
   my $tm = new TM;
   warn $tm->mtime;
   

=head1 DESCRIPTION

This traits adds methods to provide the role I<resource> to a map. That allows a map to be
associated with a resource which is addressed by a URL (actually a URI for that matter).

=head2 Predefined URIs

The following resources, actually their URIs are predefined:

=over

=item C<io:stdin>

Symbolizes the UNIX STDIN file descriptor. The resource is all text content coming from this file.

=item C<io:stdout>

Symbolizes the UNIX STDOUT file descriptor.

=item C<null:>

Symbolizes a resource which never delivers any content and which can consume any content silently
(like C</dev/null> under UNIX).

=back

=head2 Predefined URI Methods

=over

=item C<inline>

An I<inlined> resource is a resource which contains all content as part of the URI. Currently
the TM content is to be written in AsTMa=.

Example:

  inlined:donald (duck)

=back



=head1 INTERFACE

=head2 Methods

=over

=item B<url>

I<$url> = I<$tm>->url

I<$tm>->url (I<$url>)

Once an object of this class is instantiated it keeps the URL of the resource to which it is
associated. With this method you can retrieve and set that. No special further action is taken
otherwise.

=cut

sub url {
    my $self = shift;
    my $url  = shift;
    return $url ? $self->{url} = $url : $self->{url};
}

=pod

=item B<mtime>

I<$time> = I<$tm>->mtime

This function returns the UNIX time when the resource has been modified last. C<0> is returned
if the result cannot be determined. All methods from L<LWP> are supported.

Special resources are treated as follows:

=over

=item C<null:> 

always has mtime C<0>

=item C<io:stdin> 

always has an mtime 1 second in the future. The idea is that STDIN always has new
content.

=item C<io:stdout> 

always has mtime C<0>. The idea is that STDOUT never changes by itself.

=back

=cut

sub mtime {
    my $self = shift;

#warn "xxxx mtime in $self for url $self->{url}";

    my $url = $self->{url} or die "no URL specified for this resource\n";

    if ($url =~ /^file:(.+)/) {
	use File::stat;
	my $stats = stat ($1);
	return 0 unless $stats; # or die "file '$1' is not accessible (or does not exist)";
#warn "file stats ".Dumper $stats;
#warn "will return ".$stats->mtime;
	return $stats->mtime;
    } elsif ($url =~ /^inline:/) {
	return $self->{created}; ## Time::HiRes::time + 1;      # how can I know?
    } elsif ($url eq 'null:') {
	return 0;
    } elsif ($url eq 'io:stdin') {
	return Time::HiRes::time + 1;                           # this always changes, by definition
    } elsif ($url eq 'io:stdout') {
	return 0;
    } else {                                                    # using LWP is a bit heavyweight, but anyways
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->agent("TimeTester 1.0");
	
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req);
	
	use HTTP::Date;
	return str2time($res->headers->{'last-modified'});
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[67], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.2;
our $REVISION = '$Id: ResourceAble.pm,v 1.3 2007/07/17 16:22:41 rho Exp $';

1;

__END__

