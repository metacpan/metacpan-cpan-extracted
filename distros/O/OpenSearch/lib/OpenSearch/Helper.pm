package OpenSearch::Helper;
use strict;
use warnings;
use feature qw(signatures);
use Moose::Role;
use JSON::XS;
use Data::Dumper;

my $functions = {
  as_is       => sub { my $value = shift; return ($value); },
  encode_json => sub { my $value = shift; return ( encode_json($value) ); },
  encode_bool => sub { my $value = shift; return ( defined($value) ? ( $value ? 'true' : 'false' ) : $value ); },
};

sub _build_params( $self, $instance, $params, $type = 'url' ) {
  my $return = {};

  if ( exists( $params->{required} ) && exists( $params->{required}->{$type} ) ) {

    foreach my $param ( @{ $params->{required}->{$type} } ) {
      my $value = $instance->$param;
      my $enc   = $instance->meta->{attributes}->{$param}->{role_attribute}->{documentation}->{encode_func} // 'as_is';

      # I think this was nonsense and can be removed
      my $merge = $instance->meta->{attributes}->{$param}->{role_attribute}->{documentation}->{merge_hash_instead}
        // undef;

      # Die if required param is missing
      die( "Parameter: " . $param . " is required.\n" ) if !defined($value);
      die( "Parameter: " . $param . " is required.\n" )
        if ref($value) eq 'ARRAY' && !scalar( @{$value} );
      die( "Parameter: " . $param . " is required.\n" )
        if ref($value) eq 'HASH' && !keys( %{$value} );

      my $val = $self->_generate_value( $value, $enc );
      if ($merge) {
        $return->{ ( keys( %{$val} ) )[0] } = $val->{ ( keys( %{$val} ) )[0] };
      } else {
        $return->{$param} = $val if defined($val);
      }

      $instance->{$param} = undef if $self->clear_attrs;
    }

  } elsif ( exists( $params->{optional} ) && exists( $params->{optional}->{$type} ) ) {

    foreach my $param ( @{ $params->{optional}->{$type} } ) {
      my $value = $instance->$param;
      my $enc   = $instance->meta->{attributes}->{$param}->{role_attribute}->{documentation}->{encode_func} // 'as_is';

      # The (i named it like this) "query" parameter might have different "top-level"
      # Keys (i.e. query => {...} or bool => {...} etc. This way we just merge first
      # (hope that works) key of the hashref)
      my $merge = $instance->meta->{attributes}->{$param}->{role_attribute}->{documentation}->{merge_hash_instead}
        // undef;

      my $val = $self->_generate_value( $value, $enc );

      if ($merge) {
        $return->{ ( keys( %{$val} ) )[0] } = $val->{ ( keys( %{$val} ) )[0] };
      } else {
        $return->{$param} = $val if defined($val);
      }

      $instance->{$param} = undef if $self->clear_attrs;
    }

  }

# Clean all remaining attributes that are no direct url parameters handled above. i.e. index which is handled differently
  if ( $self->clear_attrs ) {
    $instance->can('index') ? $instance->{index} = undef : ();
    $instance->can('id')    ? $instance->{id}    = undef : ();
  }

  return ($return);
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
