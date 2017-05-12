package RADIUS::Dictionary;

use strict;
use vars qw($VERSION);

$VERSION = '1.0';

sub new {
  my $class = shift;
  my $self = { };
  bless $self, $class;
  $self->readfile($_[0]) if defined($_[0]);
  return $self;
}

sub readfile {
  my ($self, $filename) = @_;
  my (%attr, %rattr, %val, %rval);

  open DICT, "<$filename";

  while (defined(my $l = <DICT>)) {
    next if $l =~ /^\#/;
    next unless my @l = split /\s+/, $l;
    if (uc($l[0]) eq "ATTRIBUTE") {
      if (not defined $attr{$l[1]}) {
	$attr{$l[1]}  = [@l[2,3]];
      }
      if (not defined $rattr{$l[2]}) {
	$rattr{$l[2]} = [@l[1,3]];
      }
    }
    elsif (uc($l[0]) eq "VALUE") {
      if (defined $attr{$l[1]}) {
	if (not defined $val{$attr{$l[1]}->[0]}->{$l[2]}) {
	  $val{$attr{$l[1]}->[0]}->{$l[2]}  = $l[3];
	}
	if (not defined $val{$attr{$l[1]}->[0]}->{$l[3]}) {
	  $rval{$attr{$l[1]}->[0]}->{$l[3]} = $l[2];
	}
      }
      else {
	warn "Warning: $filename contains value for unknown attribute ",
	     "\"$l[1]\"\n";
      }
    }
    else {
      warn "Warning: Weird dictionary line: $l\n";
    }
  }
  close DICT;

  $self->{attr} = \%attr; $self->{rattr} = \%rattr;
  $self->{val}  = \%val;  $self->{rval}  = \%rval;
}

sub attr_num     { $_[0]->{attr}->{$_[1]}->[0];     }
sub attr_type    { $_[0]->{attr}->{$_[1]}->[1];     }
sub attr_name    { $_[0]->{rattr}->{$_[1]}->[0];    }
sub attr_numtype { $_[0]->{rattr}->{$_[1]}->[1];    }
sub attr_has_val { $_[0]->{val}->{$_[1]};           }
sub val_has_name { $_[0]->{rval}->{$_[1]};          }
sub val_num      { $_[0]->{val}->{$_[1]}->{$_[2]};  }
sub val_name     { $_[0]->{rval}->{$_[1]}->{$_[2]}; }

1;
__END__

=head1 NAME

RADIUS::Dictionary - RADIUS dictionary parser

=head1 SYNOPSIS

  use RADIUS::Dictionary;

  my $dict = new RADIUS::Dictionary "/etc/radius/dictionary";
  $dict->readdict("/some/other/file");
  my $num = $dict->attr_num('User-Name');
  my $name = $dict->attr_name(1);

=head1 DESCRIPTION

This is a simple module that reads a RADIUS dictionary file and
parses it, allowing conversion between dictionary names and numbers.

=head2 METHODS

I<new>

Returns a new instance of a RADIUS::Dictionary object.
If given an (optional) filename, it calls I<readdict> for you.

->I<readdict>

Parses a dictionary file and learns the name<->number mappings.

->I<attr_num>($attrname)

Returns the number of the named attribute.

->I<attr_type>($attrname)

Returns the type (I<string>, I<integer>, I<ipaddr>, or I<time>) of the
named attribute.

->I<attr_name>($attrnum)

Returns the name of the attribute with the given number.

->I<attr_numtype>($attrnum)

Returns the type of the attribute with the given number.

->I<attr_has_val>($attrnum)

Returns a true or false value, depending on whether or not the numbered
attribute has any known value constants.

->I<val_has_name>($attrnum)

Alternate (bad) name for I<attr_has_val>.

->I<val_num>($attrnum, $valname)

Returns the number of the named value for the attribute number supplied.

->I<val_name>

Returns the name of the numbered value for the attribute number supplied.

=head1 CAVEATS

This module is mostly for the internal use of RADIUS::Packet, and
may otherwise cause insanity and/or blindness if studied.

=head1 AUTHOR

Christopher Masto, chris@netmonger.net

=head1 SEE ALSO

RADIUS::Packet

=cut
