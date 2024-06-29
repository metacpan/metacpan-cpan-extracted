package OpenSearch::Helper;
use strict;
use warnings;
use Moo::Role;
use JSON::XS;
use Data::Dumper;
use feature qw(signatures);
no warnings qw(experimental::signatures);

$Carp::Verbose = 1;

my $functions = {
  as_is        => sub { my $value = shift; return ($value); },
  encode_json  => sub { my $value = shift; return ( encode_json($value) ); },
  encode_bool  => sub { my $value = shift; return ( defined($value) ? ( $value ? 'true' : 'false' ) : $value ); },
  concat_comma => sub { my $value = shift; return ( join( ',', @{$value} ) ); },
  encode_bulk  => sub {
    my $value = shift;
    my $bulk  = [];
    foreach my $item ( @{$value} ) {
      push( @{$bulk}, encode_json($item) );
    }
    return ( join( "\n", @{$bulk} ) . "\n" );
  },
};

sub _generate_params( $self, $instance ) {
  my $parsed = { url => {}, body => {} };
  my $forced = undef;

  # Seems like there are API Endpoints that dont require any Params
  # See: https://opensearch.org/docs/latest/api-reference/security-apis/
  my $api_spec = $instance->can('api_spec') ? $instance->api_spec : {};

  foreach my $param ( keys( %{$api_spec} ) ) {
    my $value = $instance->$param;

    my $desc = $api_spec->{$param};
    my $enc  = $desc->{encode_func} // 'as_is';
    my $type = $desc->{type};
    my $fb   = $desc->{forced_body};

    # Skipp all other body params if forced_body is already set
    next if ( $forced && ( $type eq 'body' ) );

    # If forced_body is set by any attribute, we will only use this body param
    if ( $value && $fb ) {
      $forced = 1;
    }

    if ( $type ne 'path' ) {
      my $val = $self->_generate_value( $value, $enc );
      if ($fb) {
        $parsed->{$type} = $val;
      } else {
        $parsed->{$type}->{$param} = $val if defined($val);
      }
    }

    $instance->{$param} = undef if $self->clear_attrs;

  }

  return ($parsed);
}

sub _generate_value( $self, $value, $encode ) {
  if ( ref($value) eq 'ARRAY' ) {
    return ( $functions->{$encode}->($value) ) if ( scalar( @{$value} ) );

  } elsif ( ref($value) eq 'HASH' ) {
    return ( $functions->{$encode}->($value) ) if ( keys( %{$value} ) );

  } elsif ( ref($value) ) {
    if ( $value->can('to_hash') && $value->to_hash ) {
      return ( $functions->{$encode}->( $value->to_hash ) );

    } elsif ( $value->can('to_string') && $value->to_string ) {
      return ( $functions->{$encode}->( $value->to_string ) );

    } else {

      # Wonder if we ever get here? Maybe on scalar ref?
      #warn("Reached unknown territory with value: " . Dumper($value) . "and type: " Dumper($type));
      #return($functions->{$encode}->($value));
    }

  } else {
    return ( $functions->{$encode}->($value) );
  }

  return (undef);
}

1;
