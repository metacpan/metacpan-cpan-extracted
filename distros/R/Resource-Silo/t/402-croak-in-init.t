#!/usr/bin/env perl

=head1 DESCRIPTION

Check that croak() in resource definition points to where the resource
was used and not to internals of Resource::Silo

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::Project;
    use Resource::Silo -class;
    use Carp;

    resource foo => sub { croak "Resource unimplemented" };
}

my $file = quotemeta __FILE__;
my $line;
throws_ok {
    my $inst = My::Project->new;
    $line = __LINE__; $inst->foo;
} qr(Resource unimplemented), 'resource not available';
like $@, qr($file line $line), 'error attributed correctly';
note $@;

done_testing;
