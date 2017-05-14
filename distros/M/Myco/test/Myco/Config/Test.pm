package Myco::Config::Test;

################################################################################
# $Id: Test.pm,v 1.7 2006/03/31 15:19:41 sommerb Exp $
#
# See license and copyright near the end of this file.
################################################################################

=pod

=head1 NAME

Myco::Config::Test - Myco::Config unit tester.

=pod

=head1 DATE

$Date: 2006/03/31 15:19:41 $

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
use File::Spec::Functions qw(catfile);

sub test_database {
    my $test = shift;
    package Myco::Config::database;
    use Myco::Config qw(:database);
    $test->assert( defined(DB_DSN), "Check DB_DSN" );
    $test->assert( defined(DB_USER), "Check DB_USER" );
    $test->assert( defined(DB_PASSWORD), "Check DB_PASSWORD" );
    eval "EVLOG";
    $test->assert($@, "EVLOG not imported" );
}

sub test_all {
    my $test = shift;
    package Myco::Config::alltest;
    use Myco::Config qw(:all);
    $test->assert( defined(DB_DSN), "Got database group" );
}

sub test_splitting_string_into_multivalued_item {
    my $test = shift;
    package Myco::Config::evlog;
    use Myco::Config qw(:evlog);
    $test->assert( defined(EVLOG_CLASSES), "Got an evlog constant" );
    $test->assert( ref EVLOG_CLASSES eq 'ARRAY', "Got an array of classes" );
    
}

sub test_include_file_with_all_key {
    my $test = shift;
    # Load the included configuration file
    my $conf_file = catfile($ENV{MYCO_ROOT}, 'conf', 'include.conf-exaasdasda');
    eval {
        open INCLUDE, $conf_file or
            Myco::Exception::IO->throw(error => "Cannot open $conf_file: $!\n");
    };
    $test->assert( $@ and $@ =~ /Cannot open/,
                  'oops - misspelled include file');
    
    $conf_file = catfile($ENV{MYCO_ROOT}, 'conf', 'my_myco_app.conf-example');
    $test->assert( -f $conf_file, 'got our include file');
    
    # Now see if include data gets sucked in through myco.conf with ':all' tag
    use Myco::Config qw(:all);
    my $got_doodad = eval { eval 'defined(DOODAD1)' };
    $test->assert( $got_doodad, "Got DOODAD1 from include file");
    $test->assert( DOODAD1 eq 'yo!', "DOODAD1 says yo!");
    $test->assert( DOODAD2 eq 'doo!', "DOODAD2 says doo!");
    $test->assert( DOODAD3 eq 'dad!', "DOODAD3 says dad!");
}

sub test_include_file_with_doodads_key {
    my $test = shift;
    
    # Now see if include data gets sucked in with myco.conf with ':doodads' tag
    use Myco::Config qw(:doodads);
    my $got_doodad = eval { eval 'defined(DOODAD1)' };
    $test->assert( $got_doodad, "Got DOODAD1 from include file");
    $test->assert( DOODAD1 eq 'yo!', "DOODAD1 says yo!");
    $test->assert( DOODAD2 eq 'doo!', "DOODAD2 says doo!");
    $test->assert( DOODAD3 eq 'dad!', "DOODAD3 says dad!");

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
