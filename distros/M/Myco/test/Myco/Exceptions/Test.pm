package Myco::Exceptions::Test;

################################################################################
# $Id: Test.pm,v 1.3 2006/03/17 22:41:32 sommerb Exp $
#
# See license and copyright near the end of this file.
################################################################################

=pod

=head1 NAME

Myco::Exceptions::Test - Myco::Exceptions unit tester.

=pod

=head1 DATE

$Date: 2006/03/17 22:41:32 $

=head1 SYNOPSIS

  use Test::Unit::TestRunner;

  my $tr = Test::Unit::TestRunner->new();
  $tr->start('Myco::UI::Cache::Test');

=head1 DESCRIPTION

This class tests the Myco::UI::Cache interface.

=cut

use strict;
use warnings;
use Myco::Exceptions;
use base qw(Test::Unit::TestCase);

my $class = 'Myco::Exception';

##############################################################################
# Test the constructor.
sub test_throw {
    my $test = shift;
    my $defex = $class->new;
    $test->assert(UNIVERSAL::isa($defex, $class), "It's a $class object");
    my $msg = 'Test Exception.';
    # List exception types here to test them all.
    for (qw(DB DataValidation Caching Session MNI IO Authz Stat
            DataProcessing NoSuchClass Meta)) {
        my $c = $class . "::$_";
        eval { $c->throw( error => $msg) };
        my $ex = $@;
        $test->assert(UNIVERSAL::isa($ex, $c), "It's a $c object ($_)");
        $test->assert(UNIVERSAL::isa($ex, $class), "It's a $class object");
        $test->assert( $ex->error eq $msg, "Correct message ($_)" );
    }
}

1;
__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Myco::UI::Cache|Myco::UI::Cache>

=cut
