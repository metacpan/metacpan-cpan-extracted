
package Tangram::Driver::mysql::Expr::Date;

use strict;
use vars qw(@ISA);
 @ISA = qw( Tangram::Expr );

my %autofun = (
			   dayofweek => 'Integer',
			   weekday => 'Integer',
			   dayofmonth => 'Integer',
			   dayofyear => 'Integer',
			   month => 'Integer',
			   dayname => 'String',
			   monthname => 'String',
			   quarter => 'Integer',
			   week => 'Integer',
			   year => 'Integer',
			   yearweek => 'Integer',
			   to_days => 'Integer',
			   unix_timestamp => 'Integer',
			  );

use vars qw( $AUTOLOAD );
use Carp;

sub AUTOLOAD
  {
   my ($self) = @_;

   my ($fun) = $AUTOLOAD =~ /\:\:(\w+)$/;

   croak "Unknown method '$fun'"
	 unless exists $autofun{$fun};

	eval <<SUBDEF;
sub $fun
{
	my (\$self, \$part) = \@_;
	my \$expr = \$self->expr();

	return Tangram\:\:$autofun{$fun}->expr("\U$fun\E(\$expr)", \$self->objects);
}
SUBDEF

  goto &$fun;
}

1;
