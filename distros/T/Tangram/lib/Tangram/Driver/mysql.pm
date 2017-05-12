
package Tangram::Driver::mysql;

use Tangram::Driver::mysql::Storage;

use strict;
use Tangram::Core;

use vars qw(@ISA);
 @ISA = qw( Tangram::Relational );

sub connect
  {
      my ($pkg, $schema, $cs, $user, $pw, $opts) = @_;
      ${$opts||={}}{driver} = $pkg->new();
      my $storage = Tangram::Driver::mysql::Storage->connect
	  ( $schema, $cs, $user, $pw, $opts );
  }

# FIXME - this should be implemented in the same way as the
# IntegerExpr stuff, below.
sub dbms_date {
    my $self = shift;

    my $date = $self->SUPER::dbms_date(shift);

    # convert standard ISO-8601 to a format that MySQL natively
    # understands, dumbass that it is.
    $date =~ s{^(\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)$}
	{$1-$2-$3 $4:$5:$6};

    return $date;
}

sub sequence_sql {
    my $self = shift;

    my $sequence_name = shift;
    # from the MySQL manual
    # http://dev.mysql.com/doc/mysql/en/Information_functions.html
    return("UPDATE seq_$sequence_name SET id=LAST_INSERT_ID(id+1);\n"
	   ."SELECT LAST_INSERT_ID();");
}

sub mk_sequence_sql {
    my $self = shift;
    my $sequence_name = shift;

    return("CREATE TABLE seq_$sequence_name (id INT NOT NULL);\n"
	   ."INSERT INTO seq_$sequence_name VALUES (0);");
}

sub drop_sequence_sql {
    my $self = shift if ref $_[0] and UNIVERSAL::isa($_[0], __PACKAGE__);
    my $sequence_name = shift;
    return "DROP TABLE seq_$sequence_name";
}

sub limit_sql {
    my $self = shift;
    return (limit => shift);
}

1;

