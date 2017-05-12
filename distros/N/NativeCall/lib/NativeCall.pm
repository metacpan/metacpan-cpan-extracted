package NativeCall;

use strict;
use warnings;
use 5.016;
use Sub::Util qw(subname);
use FFI::Platypus;
use FFI::CheckLib 0.06;

our $VERSION = '0.006';

my %attr21 = (
  Native => 1,
  Args => 1,
  Returns => 1,
  Symbol => 1,
);

sub _attr_parse {
  my ($attr) = @_;
  my ($attribute, $args) = ($attr =~ /
    (\w+)
    (?:
      \(
      (.*)
      \)
    )?
  /x);
  return ($attribute, [ map { s/;/,/gr; } split /,\s*/, ($args//'') =~ s/(\([^)]*\))/$1 =~ s{,}{;}rg /ger ]);
}

sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $subref, @attrs) = @_;
  my @bad;
  my %attr2args;
  for my $attr (@attrs) {
    my ($attribute, $args) = _attr_parse($attr);
    if (!$attr21{$attribute}) {
      push @bad, $attribute;
      next;
    } else {
      $attr2args{$attribute} ||= [];
      push @{ $attr2args{$attribute} }, @$args;
    }
  }
  my $subname = subname $subref;
  my $sub_base = $attr2args{Symbol}->[0] // (split /::/, $subname)[-1];
  my $ffi = FFI::Platypus->new;
  my $lib = $attr2args{Native}->[0] || undef; # undef means standard library
  $ffi->lib($lib ? find_lib_or_die lib => $lib : undef);
  my $argtypes = $attr2args{Args};
  my $returntype = $attr2args{Returns}->[0] || 'void';
  no warnings qw(redefine);
  undef &{ $subname }; # avoid "redefine" warning in Platypus
  $ffi->attach([ $sub_base => $subname ] => $argtypes => $returntype);
  return @bad;
}

1;

__END__

=head1 NAME

NativeCall - Perl 5 interface to foreign functions in Perl code without XS

=head1 SYNOPSIS

  use parent qw(NativeCall);
  use feature 'say';

  sub cdio_eject_media_drive :Args(string) :Native(cdio) {}
  sub cdio_close_tray :Args(string, int) :Native(cdio) {}

  say "Gimme a CD!";
  cdio_eject_media_drive undef;

  sleep 1;
  say "Ha! Too slow!";
  cdio_close_tray undef, 0;

  sub fmax :Args(double, double) :Native :Returns(double) {}
  say "fmax(2.0, 3.0) = " . fmax(2.0, 3.0);
  
  # avoid Perl built in also called "abs"
  sub myabs :Args(int) :Native :Returns(int) :Symbol(abs) {}
  say "abs(-3) = " . abs(-3);

=head1 DESCRIPTION

Mimics the C<NativeCall> module and interface from Perl 6. Uses
L<FFI::Platypus>, by the mighty Graham Ollis, for the actual hard
work. Uses inheritance and L<attributes>.

See F<examples/troll.pl> for the example given above in SYNOPSIS.

=head2 ATTRIBUTES

=over

=item Native

If an argument is given, try to load from that library. If none given,
use what is already loaded.

=item Args

A comma-separated list of L<FFI::Platypus::Type>s.  All types are supported,
including L<closures|FFI::Platypus::Type#Closures>.

=item Returns

A single L<FFI::Platypus::Type>.

=item Symbol

The native symbol name, if different from the Perl sub name.

=back

=head1 INSPIRATION

This module is entirely inspired by the article about Perl 6 NativeCall at
L<http://blogs.perl.org/users/zoffix_znet/2016/05/perl-6-nativecall-look-ma-im-a-c-programmer-1.html>.
All credit for clear explanation to Zoffix. All brickbats to me.
