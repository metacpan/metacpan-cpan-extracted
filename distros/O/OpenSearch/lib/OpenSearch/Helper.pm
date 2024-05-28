package OpenSearch::Helper;
use strict;
use warnings;
use feature qw(signatures);
use Moose::Role;
use JSON::XS;
use Data::Dumper;
use Carp qw/croak/;
$Carp::Verbose = 1;

my $functions = {
  as_is        => sub { my $value = shift; return ($value); },
  encode_json  => sub { my $value = shift; return ( encode_json($value) ); },
  encode_bool  => sub { my $value = shift; return ( defined($value) ? ( $value ? 'true' : 'false' ) : $value ); },
  concat_comma => sub { my $value = shift; return ( join( ',', @{$value} ) ); },
};

sub _generate_params( $self, $instance ) {
  my $parsed = { url => {}, body => {} };
  my $forced = undef;

  foreach my $param ( keys( %{ $instance->meta->{attributes} } ) ) {
    my $value = $instance->$param;

    # Skip "private" attributes starting with _
    # TODO: This might conflice with attributes starting with _.
    #       ie. _source, _source_includes, _source_excludes
    #       Since these are optional we dont care about them for now.
    next if ( $param =~ m/^_/ );
    my $desc = $instance->meta->{attributes}->{$param}->description;
    my $enc  = $desc->{encode_func} // 'as_is';
    my $req  = $desc->{required};
    my $type = $desc->{type};
    my $fb   = $desc->{forced_body};

    # Skipp all other body params if forced_body is already set
    next if ( $forced && ( $type eq 'body' ) );

    if ($req) {
      my $caller = ( caller(4) )[3];

      croak( "Parameter: '" . $param . "' is required for " . $caller . ":\n\n" )
        if ( !defined($value)
        || ( ref($value) eq 'ARRAY' && !scalar( @{$value} ) )
        || ( ref($value) eq 'HASH'  && !keys( %{$value} ) ) );
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

  #print Dumper $parsed;

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
