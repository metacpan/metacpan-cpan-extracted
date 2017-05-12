#----------------------------------------------------------------------------+
#
#  String::Urandom - An alternative to using /dev/random
#
#  DESCRIPTION
#  Using output of /dev/urandom.  Simply convert bytes into 8-bit characters.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package String::Urandom;

use strict;
use warnings;
use Params::Validate qw( :all );

our $VERSION = 0.16;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# new(\%params)
#
# General object constructor.

sub new {
    my $class  = shift;
    my $params = (ref $_[0] eq 'HASH') ? shift : { @_ };
    return bless( {
        LENGTH => $params->{LENGTH} || 32,
        CHARS  => $params->{CHARS}  ||
                  [ qw/ a b c d e f g h i j k l m n o p q r s t u v w x y z
                        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                        1 2 3 4 5 6 7 8 9                                 / ]
    }, $class );
}

#----------------------------------------------------------------------------+
# str_length($value)
#
# Set/Get the string length.

sub str_length {
    my ( $self, $value )
      = validate_pos( @_,
          { type => OBJECT }, 
          { type => SCALAR, optional => 1 }
          );

    return $self->{LENGTH} unless ($value);
    return $self->{LENGTH} unless ($value =~ /^[\d]*$/);
    $self->{LENGTH} = $value;
    return $self->{LENGTH};
}

#----------------------------------------------------------------------------+
# str_chars($value)
#
# Set/Get the string characters.

sub str_chars {
    my ( $self, $value )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR, optional => 1 }
          );

    return $self->{CHARS} unless ($value);
    return $self->{CHARS} unless ($value =~ /^[\w\s]*$/);
    my @chars = split(/\s+/, $value);
    $self->{CHARS} = \@chars;
    return $self->{CHARS};
}

#----------------------------------------------------------------------------+
# rand_string()
#
# Generate a new random string.

sub rand_string {
    my ($self)
      = validate_pos( @_,
          { type => OBJECT }
          );

    my @chars = @{ $self->{CHARS} };

    shuffle_array(\@chars);

    open (DEV, "/dev/urandom") or die "Cannot open file: $!";
    read (DEV, my $bytes, $self->{LENGTH});

    my $string;
    my @randoms = split(//, $bytes);
    foreach (@randoms) {
        $string .= $chars[ ord($_) % @chars ];
    }
    return $string;
}

#----------------------------------------------------------------------------+ 
# shuffle_array()
#
# Fisher-Yates shuffle algorithm - Perl Cookbook, Recipe 4.17

sub shuffle_array {
    my $array = shift;

    for (my $i = @$array; --$i;) {
        my $j = int rand ($i + 1);
        next if ($i == $j);
        @$array[$i, $j] = @$array[$j, $i];
    }
}

1;

__END__

=head1 NAME

String::Urandom - An alternative to using /dev/random

=head1 SYNOPSIS 

  use String::Urandom;

  my $obj = String::Urandom->new(
      LENGTH => 55,
      CHARS  => [ qw/ a b c 1 2 3 / ]
    );

  print $obj->rand_string, "\n";

=head1 DESCRIPTION

Using output from /dev/urandom.  Simply convert bytes into 8-bit characters.

=head1 PREREQUISITES

  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz String-Urandom-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install String::Urandom'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install String::Urandom
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 new

Create a new session object.  Configuration items may be passed as a parameter.

  my $obj = new String::Urandom;

    or

  my %params = (
      LENGTH => 55,
      CHARS  => [ qw/ a b c 1 2 3 / ]
    );

  my $obj = String::Urandom->new(\%params);

=head2 str_length

This method will Set/Get the string character length.

The default value is: 32

  $obj->str_length(55);

=head2 str_chars

This method will Set/Get characters used for generating a string.

The default value is: a-z A-Z 0-9

  $obj->str_chars('a b c 1 2 3');

=head2 rand_string

This method generates a new random string.

  $obj->rand_string;

=head1 PARAMETERS

=head2 LENGTH

Defines the length of the string in characters.

The default value is: 32

=head2 CHARS

Defines the characters used for generating the string.

The default value is: a-z A-Z 0-9

=head1 REQUIREMENTS

Any flavour of UNIX that supports /dev/urandom

=head1 SECURITY

In general, the longer the string length and total characters defined, the more
secure the output result will be.

=head1 NOTES

The /dev/urandom is an ("unlocked" random source) which reuses the internal pool to
produce more pseudo-random bits.  Since this is the case, the read may contain less
entropy than its counterpart /dev/random.  Knowing this, this module was intended
to be used as a pseudorandom string generator for less secure applications where
response timing may be an issue.

=head1 SEE ALSO

urandom(4)

=head1 AUTHOR

Marc S. Brooks E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
