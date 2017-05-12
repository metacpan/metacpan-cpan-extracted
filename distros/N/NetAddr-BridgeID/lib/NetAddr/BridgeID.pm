package NetAddr::BridgeID;

our $VERSION = '0.97'; # VERSION
# ABSTRACT: Object for BridgeIDs (priority/MAC combos)

use sanity;
use NetAddr::MAC;
use Scalar::Util qw/blessed/;

use Moo;
use MooX::Types::MooseLike::Base qw/InstanceOf Str/;
use MooX::Types::CLike qw/UShort/;

has original => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);
has priority => (
   is       => 'ro',
   isa      => UShort,
   required => 1,
);
has mac_obj => (
   is       => 'ro',
   isa      => InstanceOf['NetAddr::MAC'],
   required => 1,
   handles  => {
      (map { $_ => $_ } qw(
         is_eui48
         is_eui64
         is_multicast
         is_unicast
         is_local
         is_universal
         as_basic
         as_bpr
         as_cisco
         as_ieee
         as_ipv6_suffix
         as_microsoft
         as_singledash
         as_sun
         as_tokenring
         to_eui48
         to_eui64
      )),
      qw(
         mac  original
      ),
   },
);

sub bridge_id { $_[0]->priority.'#'.$_[0]->as_cisco; }


around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my %opts;

   if (@_ == 1) {
      my $arg = pop;
      if (blessed $arg) {
         if    ($arg->isa('NetAddr::BridgeID')) { $opts{bridge_id} = $arg->original; }
         elsif ($arg->isa('NetAddr::MAC'))      { $opts{mac_obj}   = $arg; }
         else                                   { $opts{bridge_id} = $arg; }
      }
      elsif (ref $arg eq 'ARRAY') { %opts = @$arg; }
      elsif (ref $arg eq 'HASH')  { %opts = %$arg; }
      else                        { $opts{bridge_id} = $arg; }
   }
   else { %opts = @_; }

   # parse vars from bridge_id
   if (defined $opts{bridge_id}) {
      $opts{bridge_id} =~ /^(\d+)\#(.+)$/;
      $opts{priority}  //= $1;
      $opts{mac}       //= $2;
   }

   # parse mac from mac_obj
   $opts{mac} //= $opts{mac_obj}->original if (defined $opts{mac_obj});

   # defaults
   $opts{priority}  //= 0;
   $opts{bridge_id} //= $opts{priority}.'#'.$opts{mac};
   #$opts{mac_obj}   //= NetAddr::MAC->new( mac => $opts{mac} );
   
   # NetAddr::MAC has some weird issues with MAC translation here
   # (see https://rt.cpan.org/Ticket/Display.html?id=79915)
   unless ($opts{mac_obj}) {
      my $new_mac = $opts{mac};
      $new_mac =~ s/[^\da-f]//gi;
      $new_mac =~ s/(.{4})(?=.)/$1./g;
      $opts{mac_obj} = NetAddr::MAC->new( mac => $new_mac );
      $opts{mac_obj}->{original} = $opts{mac};  # Ugly and hacky; remove when bug is fixed
   }
   
   # bridge_id is actually 'original'
   $opts{original} = delete $opts{bridge_id};
   delete $opts{mac};

   $orig->($self, \%opts);
};

1;



=pod

=encoding utf-8

=head1 NAME

NetAddr::BridgeID - Object for BridgeIDs (priority/MAC combos)

=head1 SYNOPSIS

   use NetAddr::BridgeID;
    
   my $bid;
   $bid = NetAddr::BridgeID->new( '2#00:11:22:aa:bb:cc' );
   $bid = NetAddr::BridgeID->new( bridge_id => '60#0011.22AA.BBCC' );
   
   use NetAddr::MAC;
   my $mac = NetAddr::MAC->new( mac => '0011.22AA.BBCC' );
   
   $bid = NetAddr::BridgeID->new( priority => '60', mac_obj => $mac );
   $bid = NetAddr::BridgeID->new( priority => '60', mac => '0011.22AA.BBCC' );

=head1 DESCRIPTION

This object class simply creates a L<NetAddr::MAC>-like object, with a priority for
STP Bridge IDs.

=for Pod::Coverage BUILDARGS

=head1 METHODS

=head2 original

The original bridge ID string, as it was passed to the constructor.  If it was passed
in pieces (or if parts were left out), it will fill in the gaps to provide a full
bridge ID

=head2 bridge_id

The bridge ID, with a Cisco-style MAC address (like C<0000.1111.2222>).

=head2 priority

The priority number.

=head2 mac_obj

The L<NetAddr::MAC> object tied to this one.

=head2 NetAddr::MAC Methods

All of the C<is_* / as_* / to_*> methods are "handled" to the main BridgeID object, so 
you can access them directly.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/NetAddr-BridgeID/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/NetAddr::BridgeID/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #distzilla then talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<L<https://github.com/SineSwiper/NetAddr-BridgeID/issues>|GitHub>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

