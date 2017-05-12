package Myco::Config::Test;

################################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
# See license and copyright near the end of this file.
################################################################################

=pod

=head1 NAME

Myco::Config::Test - Myco::Config unit tester.

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=pod

=head1 DATE

$Date: 2004/11/22 19:16:05 $

=head1 SYNOPSIS

  use Myco::UI::Cache::Test;
  use Test::Unit::TestRunner;

  my $tr = Test::Unit::TestRunner->new();
  $tr->start('Myco::UI::Cache::Test');

=head1 DESCRIPTION

This class tests the Myco::UI::Cache interface.

=cut

use strict;
use warnings;
use Myco::Config;
use base qw(Test::Unit::TestCase);

sub test_randy {
    my $test = shift;
    package Myco::Config::randytest;
    use Myco::Config qw(:randy);
    $test->assert(RANDY_PORT == 6288, "Check RANDY_PORT" );
    $test->assert(RANDY_HOST eq 'localhost', "Check RANDY_HOST" );
    eval "APACHE_USER";
    $test->assert($@, "APACHE_USER not imported" );
}

sub test_apache {
    my $test = shift;
    package Myco::Config::apachetest;
    use Myco::Config qw(:apache);
    $test->assert(APACHE_USER eq 'www', "Got apache User" );
    $test->assert(APACHE_GROUP eq 'www', "Got apache Group" );
    eval "RANDY_PORT";
    $test->assert($@, "RANDY_PORT not imported" );
}

sub test_all {
    my $test = shift;
    package Myco::Config::alltest;
    use Myco::Config qw(:all);
    $test->assert(RANDY_PORT == 6288, "Check RANDY_PORT" );
    $test->assert(APACHE_USER eq 'www', "Got apache User" );
    $test->assert(APACHE_GROUP eq 'www', "Got apache Group" );
}

1;
__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Myco::UI::Cache|Myco::UI::Cache>

=cut
