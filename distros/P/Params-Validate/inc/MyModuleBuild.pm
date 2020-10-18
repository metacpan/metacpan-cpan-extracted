package inc::MyModuleBuild;

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::ModuleBuild';

has '+mb_version' => (
    default => 0.4227,
);

has '+mb_class' => ( default => 'MyMBClass' );

around module_build_args => sub {
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);

    $args->{allow_pureperl} = 1;
    $args->{get_options}    = { pp => {} };

    $args->{c_source} = 'c';
    if ( $ENV{TRAVIS} ) {

        # The declaration-after-statement warning is for constructs that break
        # old versions of MSVC.
        $args->{extra_compiler_flags}
            = [ '-Wdeclaration-after-statement', '-Werror' ];
    }

    return $args;
};

__PACKAGE__->meta()->make_immutable();

1;
