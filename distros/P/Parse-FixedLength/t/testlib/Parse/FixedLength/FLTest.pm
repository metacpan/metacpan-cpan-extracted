# This is just for installation test and is not installed

package Parse::FixedLength::FLTest;

use vars qw(@ISA);

@ISA = qw(Parse::FixedLength);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $flags = shift || {};
    die "Options arg not a hash ref"
        unless UNIVERSAL::isa($flags,'HASH');
    $$flags{autonum} = ['filler'];
    bless $class->SUPER::new([qw(
        stuff:5
        filler:5
        more_stuff:5
        filler:5
    )], $flags), $class;
}
1;
