##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Recode - convert bytes from one charset to another

=head1 SYNOPSIS

 use PApp::Recode;
 # not auto-imported into .papp-files

 $converter = to_utf8 PApp::Recode "iso-8859-1";
 $converter->("string");

=head1 DESCRIPTION

This module creates conversion functions that enable you to convert text
data from one character set (and/or encoding) to another.

=cut

package PApp::Recode;

use Convert::Scalar ();

BEGIN {
   $VERSION = 2.2;

   require XSLoader;
   XSLoader::load 'PApp::Recode', $VERSION;
}

=head2 Functions

=over 4

=item charset_valid $charset

Returns a boolean indicating wether the named charset is valid on this
system (where "valid" is defined as "can be converted from/to UTF-8 using
this module").

=cut

# cache the results, some frequently used charsets are always supported
my %charset_valid = ( "iso-8859-1" => 1, "utf-8" => 1, "ascii" => 1 );

sub charset_valid {
   unless (exists $charset_valid{$_[0]}) {
      $charset_valid{$cs} = eval {
         PApp::Recode::Pconv::open($cs, "utf-8");
         PApp::Recode::Pconv::open("utf-8", $cs);
         1;
      };
   }
   $charset_valid{$cs};
}

=back

=cut

=head2 The PApp::Recode Class

This class can be used to convert textual data between various encodings.

=over 4

=item $converter = new PApp::Recode "destination-charset", "source-charset" [, \&fallback]

Returns a new conversion function (a code reference) that converts its
argument from the source character set into the destination character set
each time it is called (it does remember state, though. A call without
arguments resets the state).

Perl's internal UTF-8-flag is ignored on input and not set on output.

Example: create a converter that converts UTF-8 into ascii, html-escaping
any non-ascii characters:

   new PApp::Recode "ascii", "utf-8", sub { sprintf "&#x%x;", $_[0] };

=item $converter = to_utf8 PApp::Recode "source-character-set" [, \&fallback]

Similar to a call to C<new> with the first argument equal to "utf-8". The
returned conversion function will, however, forcefully set perl's UTF-8
flag on the returned scalar.

=item $converter = utf8_to PApp::Recode "destination-character-set" [, \&fallback]

Similar to a call to C<new> with the second argument equal to "utf-8". The
returned conversion function will, however, upgrade its argument to UTF-8.

=cut

sub new($$$;$) {
   my $self = shift;
   my ($to, $from, $fb) = @_;
   my $pconv = PApp::Recode::Pconv::open($to, $from, $fb);
   $pconv && sub {
      unshift @_, $pconv;
      &PApp::Recode::Pconv::convert;
   };
}

sub to_utf8($$;$) {
   my $self = shift;
   my $converter = $self->new("utf-8", $_[0], $_[1]);
   sub {
      Convert::Scalar::utf8_on &$converter;
   };
}

sub utf8_to($$;$) {
   my $self = shift;
   my $converter = $self->new($_[0], "utf-8", $_[1]);
   sub {
      Convert::Scalar::utf8_upgrade($_[0]) if @_;
      &$converter;
   };
}

=back

=head2 The PApp::Recode::Pconv Class

This is the class that actually implements character conversion. It should not be used directly.

=cut

=over 4

=item new PApp::Recode::Pconv tocode, fromcode [, fallback]

Create a new encoding convert that encodes from C<fromcode> to C<tocode>,
optionally invoking the C<fallback> code reference for every character
that is not representable in the target encoding.

=item PApp::Recode::Pconv::open tocode, fromcode [, fallback]

Convenience function that calls C<new> and returns the converter.

=item $pconv->convert($string [, reset])

Convert the given string. If C<reset> is true, the internal multibyte
state is reset before conversion.

=item $pconv->reset

Reset the multibyte state.

=item $pconv->convert_fresh ($string)

Same as C<convert> with C<reset> set to true.

=cut

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;

