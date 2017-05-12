
package Tangram::Driver::Pg;

use strict;
use Tangram::Core;
use Tangram::Driver::Pg::Storage;

use vars qw(@ISA);
 @ISA = qw( Tangram::Relational );

sub connect
  {
      my ($pkg, $schema, $cs, $user, $pw, $opts) = @_;
      ${$opts||={}}{driver} = $pkg->new();
      my $storage = Tangram::Driver::Pg::Storage->connect
	  ( $schema, $cs, $user, $pw, $opts );
  }

sub blob {
    return "BYTEA";
}

sub date {
    return "DATE";
}

sub bool {
    return "BOOL";
}

use MIME::Base64;

sub to_blob {
    my $self = shift;
    my $value = shift;
    encode_base64($value);
}

sub from_blob {
    my $self = shift;
    my $value = shift;
    decode_base64($value);
}

sub sequence_sql {
    my $self = shift;
    my $sequence_name = shift;
    return "SELECT nextval('$sequence_name')";
}

sub limit_sql {
    my $self = shift;
    return (limit => shift);
}

1;
