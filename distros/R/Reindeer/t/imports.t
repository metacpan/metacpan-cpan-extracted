use Test::More;
use Test::Moose::More;
use Test::Fatal;

for my $import(qw{ try catch finally file dir class_type role_type }) {

    subtest "checking $import" => sub {

        # the library should already be loaded by virtue of Util

        #for my $type ($library->type_names) {

            #note $type;
            #check_type_from_reindeer($library, $type);
            #check_type_from_library($library, $type);
            check_import_in_reindeer($import);
        #}
    };
}

done_testing;  # <========

my $class = 'Class001';

sub check_import_in_reindeer {
    my ($import) = @_;

    $class++;

    my $lives = exception { eval qq{
        {
            package TestClass::$class;
            use Reindeer;
            $import;
        }
    } };

    is $lives, undef, "No blowing up on $import";

    $lives = exception { eval qq{
        {
            package TestClass::Role::$class;
            use Reindeer::Role;
            $import;
        }
    } };

    is $lives, undef, "No blowing up on $import() for roles";
}
