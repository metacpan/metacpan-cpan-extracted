#===============================================================================
#
#         FILE:  Mapper.pm
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/24/2011 02:36:47 PM
#     REVISION:  ---
#===============================================================================
package Storable::AMF::Mapper;
use strict;
use Storable::AMF qw(parse_serializator_option);
use Carp qw(croak);

sub new{
	my $class = shift;
	if ( @_ % 2 ){
		croak( "Usage Storable::AMF::Mapper->new( to_amf => 0 | 1, option => ...)");
	}
	my %options = @_;
	my $option_int = parse_serializator_option( 'prefer_number'); 
	if ( my $option_str = delete $options{ option } ){
		$option_int = parse_serializator_option( $option_str );
	}
	if ( delete $options{ to_amf } ){
		$option_int |= 128	;
	}
	if (keys %options ){
		croak( "Unknown option: ". join (" ", keys %options ));
	}
	return $option_int;
}

1;
__END__

=head1 SYNOPSYS 

  use Storable::AMF::Mapper;
  use Storable::AMF0 qw(freeze);

  my $mapper = Storable::AMF::Mapper->new( to_amf =>1 );

  sub T::TO_AMF {
	  my $orig = shift;
	  return { %$orig, some_key_to_be_added => "Key Value" };
  }
  my $obj  = bless { Zeta => 1 }, 'T';

  my $amf0 = freeze( $obj, $mapper); # use TO_AMF method for freezing perl_objects

  my $obj  = thaw( $amf0 ); # $obj = { Zeta=> , some_key_to_be_added => "Key Value" }

=head1 NOTICE

  This Mapper is experimental feature of Storable::AMF distro. So may change in future ...
