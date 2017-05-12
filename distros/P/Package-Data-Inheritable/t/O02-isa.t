#!perl -T
use warnings;
use strict;

use Test::More tests => 6;

use lib qw( t t/lib ./lib );
use OEmployee;
BEGIN { inherit OEmployee }

can_ok('OPerson',  'inherit');
can_ok('OWorker',  'inherit');
can_ok('OEmployee', 'inherit');

is( check_person_isa(),   'OK', 'OPerson::ISA        functional test');
is( check_worker_isa(),   'OK', 'OWorker::ISA        functional test');
is( check_employee_isa(), 'OK', 'OEmployee::ISA      functional test');

exit;


######################################################################

# Functional test
sub check_person_isa {
    return _check_class_isa('OPerson', ['Package::Data::Inheritable', 'Exporter', 'UNIVERSAL']);
}

# Functional test
sub check_worker_isa {
    return _check_class_isa('OWorker', ['OWorker', 'Package::Data::Inheritable', 'Exporter', 'UNIVERSAL']);
}

# Functional test
sub check_employee_isa {
    return _check_class_isa('OEmployee', ['OEmployee', 'OWorker', 'Package::Data::Inheritable', 'Exporter', 'UNIVERSAL']);
}


######################################################################
# TEST UTILITIES

sub _check_class_isa {
    my ($class, $isa_list) = @_;
    foreach my $upper (@$isa_list) {
        next if UNIVERSAL::isa($class, $upper);
        return "$class is not a $upper";
    }
    return 'OK';
}

