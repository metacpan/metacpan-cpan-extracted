package TM::Serializable;

use Class::Trait 'base';
use Class::Trait 'TM::Synchronizable';

=pod

=head1 NAME

TM::Serializable - Topic Maps, abstract trait for stream (map) based input/output drivers

=head1 SYNOPSIS

  # step 1) you write an input/output driver for a serialized TM format
  package MyFormat;

     # provides methods
     sub deserialize {
         my $self   = shift; # gets current map
	 my $stream = shift;
         # .... fill the map with content
     }

     sub serialize {
         my $self = shift; # get the map
         # ....
         return ... #serialized content
     }
  1;

  # step 2) construct a subclass of TM using this driver
  package MapWithMyFormat;

    use TM;
    use base qw(TM);
    use Class::Trait qw(TM::Serializable MyFormat);

    1;

  # step 3) use it in your application
  my $tm = new MapWithMyFormat (url => 'file:map.myformat');
  $tm->sync_in; # uses MyFormat to parse the content from the file

=head1 DESCRIPTION

This trait implements synchronizable resources using a serialized format. Examples are formats such
as AsTMa 1.0, 2.0, LTM, CTM, XTM. The only thing these drivers have to provide are the methods
C<serialize> and C<deserialize> which serialize maps to streams and vice-versa.

This trait provides the implementations for C<source_in> and C<source_out> triggering C<deserialize>
and C<serialize>, respectively.

=head1 INTERFACE

=head2 Methods

=over

=item B<source_in>

Uses the URL attached to the map object to trigger C<deserialize> on the stream content behind the
resource. All URLs of L<LWP> are supported. If the URI is C<io:stdio> then content from STDIN is
consumed. This content can be consumed more than once (it is buffered internally), so that you can
read several times from C<io:stdin> getting the same input.

If the resource URI is C<io:stdout>, then nothing happens.

If the resource URI is C<null:>, then nothing happens.

[Since TM 1.53]: Any additional parameters are passed through to the underlying C<deserialize> method.

=cut

sub source_in {
    my $self = shift;
    my $url  = $self->url;
    
#warn "serial source in checking url $url";
    return if $url eq 'io:stdout';   # no syncing in from STDOUT
    return if $url eq 'null:';       # no syncing in from null

    my $content = _get_content ($url);
    $self->deserialize ($content, @_);
}

our $STDIN; # here we store the STDIN content to be able to reuse it later

sub _get_content {
    my $url = shift or $TM::log->logdie (scalar __PACKAGE__ . ": url is empty");

    if ($url =~ /^inline:(.*)/s) {
	return $1;
    } elsif ($url eq 'io:stdout') {
	return undef;
    } elsif ($url eq 'io:stdin') {
	unless ($STDIN) {
	    local $/;
	    $STDIN = scalar <STDIN>;
	}
	return $STDIN;
    } else {                                    # some kind of URL?
	use LWP::Simple;
	return get($url) || die "unable to load '$url'\n";
    }
}

=pod

=item B<source_out>

This method triggers C<serialize> on the object. The contents will be copied to the resource
identified by the URI attached to the object. At the moment, only C<file:> URLs  and C<io:stdout>
is supported.

If the resource URI is C<io:stdin>, nothing happens.

If the resource URI is C<null:>, nothing happens.

If the resource URI is C<inline:..> nothing happens.

[Since TM 1.53]: Any additional parameters are passed through to the underlying C<serialize> method.

=cut

sub source_out {
    my $self = shift;
    my $url  = $self->url;

    return if $url eq 'io:stdin'; # no syncing out to STDIN
    return if $url eq 'null:';    # no syncing out to null
    return if $url =~ /^inline:/; # no syncing out to inline

    my $content = $self->serialize (@_);
    _put_content ($url, $content);
}

sub _put_content {
    my $url = shift;
    my $s   = shift;

#warn "put content '$s' to ".$url;
    if      ($url eq 'io:stdin')  {  # no, I will not do that
    } elsif ($url eq 'null:')     {  # we should not be there, but in case, nothing will be written
    } elsif ($url =~ /^inline:/)  {  # we should not be there, but in case, nothing will be written
    } elsif ($url eq 'io:stdout') {
	print STDOUT $s;
    } elsif ($url =~ /^file:(.*)/) { # LWP does not support file: PUT?
	open (F, ">$1") or die "cannot open file '$1' for writing";
	print F $s;
	close F;
    } else {
	die "other URL schemes '$url' not yet implemented";
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Synchronizable>

=head1 AUTHOR INFORMATION

Copyright 20(0[2-6]|10), Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.13;

1;

__END__
