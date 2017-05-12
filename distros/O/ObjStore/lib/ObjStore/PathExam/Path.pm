use strict;
package ObjStore::PathExam::Path;
use Carp;
use base 'ObjStore::AV';

sub new {
    use attrs 'method';
    my ($class, $near, $path) = @_;
    my @comp = split m",\s*", $path;
    croak "$class->new($path): invalid" if @comp==0;
    my $o = $class->SUPER::new($near, scalar @comp);
    for (my $x=0; $x < @comp; $x++) {
	my @c = split m"\/", $comp[$x];
	croak "$class->new($path): '$comp[$x]' too long" if @c > 7;
	$o->[$x] = [map { "$_\0" } @c];
    }
    $o;
}

sub stringify {
    use attrs 'method';
    my $paths = shift;
    my @ps;
    $paths->map(sub {
		    my $path = shift;
		    my @p;
		    $path->map(sub { chop(my $s = shift); push(@p, $s) });
		    push @ps, join('/', @p);
		});
    join ', ', @ps;
}

1;
