##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

package PApp::FormBuffer;

=head1 NAME

PApp::FormBuffer - a re-blocking buffer for multipart streams

=head1 SYNOPSIS

 use PApp::FormBuffer;

=head1 DESCRIPTION

PApp::FormBuffer is a utility class that converts a file handle into a
filehandle that emulates multiple virtual files that are separated by a
boundary strings, just what's required to parse multipart form data. It
should be used via perls tie interface.

=over 4

=item new attr => val, ...

 fh         filehandle to use (only read()) is ever called
 boundary   the "file"-part boundary
 rsize      max. number of bytes to read
 bufsize    the approx. buffer size (def. 32768)

=back

=head2 Supported Methods

 READ
 READLINE
 EOF

 skip_boundary

=cut

$VERSION = 2.3;

no utf8;
use bytes;

use PApp::Exception;

sub new {
   my $class = shift;
   my $fh = local *PApp_FormBuffer;
   my $self = tie *$fh, $class, {
      bufsize => 32768,
      @_,
      buffer => "\15\12",
      datalen => 2,
   };
   $self->_refill($self->{bufsize});
   $self;
}

sub TIEHANDLE {
   my $class = shift;
   my $self = shift;

   bless $self, $class;
}

sub EOF {
   my $self = shift;
   $self->{datalen} == 0;
}

sub _datalen {
   my $self = shift;
   $self->{datalen} = index $self->{buffer}, "\15\12--$self->{boundary}";
   $self->{datalen} = length $self->{buffer} if $self->{datalen} < 0;
}

sub _refill {
   my $self = shift;
   my $len = shift;

   while ($self->{datalen} < $len
	  && $self->{datalen}
	  && $self->{datalen} >= length($self->{buffer})
	 ) {
      $len = $self->{rsize} if $len > $self->{rsize};
      my $got = $self->{fh}->read($self->{buffer}, $len, length $self->{buffer});

      $got > 0 or die "unable to read more form data into FormBuffer: $!\n";
      $self->{rsize} -= $got;
      $self->_datalen;
   }
}

sub skip_boundary {
   my $self = shift;
   while ($self->{datalen} >= length ($self->{buffer})) {
      if (length($self->{buffer}) > 6 + length($self->{boundary})) {
         $self->{buffer} = ""; $self->{datalen} = 0;
      }
      $self->_refill($self->{bufsize});
   }
   $self->{buffer} =~ s/.*?\15\12--\Q$self->{boundary}\E(..)//s;
   if ($1 eq "--") {
      return ();
   } else {
      if (length $self->{buffer}) {
	 $self->_datalen;
      } else {
	 $self->_refill($self->{bufsize});
      }
      return 1;
   }
}

sub READ {
   my $self = shift;
   my $buf = \$_[0];
   my $len = $_[1];
   my $offset = $_[2];
   $self->_refill($len);
   $len = $self->{datalen} if $len > $self->{datalen};
   substr ($$buf, $offset) = substr ($self->{buffer}, 0, $len);
   substr ($self->{buffer}, 0, $len) = ""; $self->{datalen} -= $len;
   $len;
}

sub READLINE {
   my $self = shift;
   for(;;) {
      return undef if $self->{datalen} == 0;
      if ($self->{buffer} =~ s/^([^\15\12]*)\15?\12//) {
         my $line = $1;
         $self->_datalen;
         return $line;
      }
      $self->_refill(length($self->{buffer}) + $self->{bufsize});
   }
}

*read = \&READ;

=head1 SEE ALSO

L<PApp>.
      
=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;
