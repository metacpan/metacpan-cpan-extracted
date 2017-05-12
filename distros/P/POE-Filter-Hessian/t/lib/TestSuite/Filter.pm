package  TestSuite::Filter;

use strict;
use warnings;
use base 'Test::Class';

use YAML;
use Test::More;
use Test::Deep;

use POE::Filter::Hessian;

__PACKAGE__->SKIP_CLASS(1);

sub t005_create_filter : Test(2) {    #{{{
    my $self       = shift;
    my $version = $self->{version};
    my $filter     = POE::Filter::Hessian->new( version => $version );
    my $translator = $filter->translator();
    isa_ok( $translator, 'Hessian::Translator',
        'Object received from translator accessor' );
    my @methods = qw/new clone get_one_start get_one get_pending get put /;
    can_ok( $filter, @methods );
    $self->{filter} = $filter;
}    #}}}



"one, but we're not the same";

__END__


=head1 NAME

TestSuite::Filter - Base class for testing POE::Filter::Hessian

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


