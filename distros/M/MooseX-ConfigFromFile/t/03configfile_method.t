use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

my %config_from_file_args;
{
    package A;
    use Moose;
    with qw(MooseX::ConfigFromFile);

    sub configfile { die 'should not ever be here' }

    sub get_config_from_file {
        my ($class, $file) = @_;
        $config_from_file_args{$class} = $file;
        return {};
    }
}

{
    package B;
    use Moose;
    extends qw(A);

    sub configfile { die; }
    has configfile => ( is => 'bare', default => 'bar' );
}

{
    package C;
    use Moose;
    extends qw(A);

    sub configfile { die; }
    has configfile => (
        is => 'bare',
        default => sub {
            my $class = shift;
            $class = blessed($class) || $class;
            '/dir/' . $class;
        },
    );
}

is(exception { A->new_with_config() }, undef, 'A->new_with_config lives');
is($config_from_file_args{A}, undef, 'there is no configfile for A');

is(exception { B->new_with_config() }, undef, 'B->new_with_config lives');
is($config_from_file_args{B}, 'bar', 'B configfile attr default sub is called');

is(exception { C->new_with_config() }, undef, 'C->new_with_config lives');
is($config_from_file_args{C}, '/dir/C', 'C configfile attr default sub is called, with classname');

done_testing;
