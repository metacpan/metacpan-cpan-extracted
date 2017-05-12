

package Tangram::Driver::Oracle;

use strict;
use Tangram::Core;

use Tangram::Driver::Oracle::Storage;

use vars qw(@ISA);
 @ISA = qw( Tangram::Relational );

sub connect
  {
      my ($pkg, $schema, $cs, $user, $pw, $opts) = @_;
      ${$opts||={}}{driver} = $pkg->new();
      my $storage = Tangram::Driver::Oracle::Storage->connect
	  ( $schema, $cs, $user, $pw, $opts );
  }

sub blob {
    return "CLOB";
}

sub date {
    return "DATE";
}

sub bool {
    return "INT(1)";
}

# Oracle--
sub from_date {
    $_[1];
    #print STDERR "Converting FROM $_[1]\n";
    #(my $date = $_[1]) =~ s{ }{T};
    #$date;
 }
sub to_date {
    $_[1];
    #print STDERR "Converting TO $_[1]\n";
    #(my $date = $_[1]) =~ s{T}{ };
    #$date;
}

sub from_blob { $_[1] }
sub to_blob { $_[1] }

sub limit_sql {
    my $self = shift;
    my $spec = shift;
    if ( ref $spec ) {
	die unless ref $spec eq "ARRAY";
	die "Oracle cannot handle two part limits"
	    unless $spec->[0] eq "0";
	$spec = pop @$spec;
    }
    return (postfilter => ["rownum <= $spec"]);
}

1;
