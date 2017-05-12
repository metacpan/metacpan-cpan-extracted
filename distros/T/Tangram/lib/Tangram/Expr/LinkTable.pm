
package Tangram::Expr::LinkTable;

use strict;

# This looks quite a bit like a Tangram::Expr::CursorObject

use Carp;

sub new
{
	my ($pkg, $name, $alias) = @_;
	bless [ $name, $alias ], $pkg;
}

sub from
{
	my ($name, $alias) = @{shift()};
	"$name t$alias"
}

sub where
{
	confess unless wantarray;
	()
}

1;
