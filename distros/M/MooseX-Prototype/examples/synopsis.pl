use MooseX::Prototype;

my $Person = object {
	name       => undef,
};

my $Employee = $Person->new->extend({
	job        => undef,
	employer   => undef,
});

my $CivilServant = $Employee->new(
	employer   => 'Government',
);

$CivilServant->extend({
	department => undef,
});

my $bob = $CivilServant->new(
	name       => 'Robert',
	department => 'HMRC',
	job        => 'Tax Inspector',
);

print $bob->dump;

# $VAR1 = bless( {
#    name       => 'Robert',
#    job        => 'Tax Inspector',
#    department => 'HMRC',
#    employer   => 'Government'
# }, 'MooseX::Prototype::__ANON__::0006' );

