package Test::BDD::Infrastructure::Compare;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for comparsion checks
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_cmp_operator $CMP_OPERATOR_RE lookup_config);

use File::Slurp;


Then qr/the value (\S+) must be like (.*)/, sub {
	my $value = lookup_config( $1 );
	my $regex = $2;
	like( $value, qr/$regex/, "the value $value must be like $regex");
};
Then qr/the value (\S+) must be unlike (.*)/, sub {
	my $value = lookup_config( $1 );
	my $regex = $2;
	unlike( $value, qr/$regex/, "the value $value must be unlike $regex");
};

Then qr/the value (\S+) must be $CMP_OPERATOR_RE (.*)/, sub {
	my $value = lookup_config( $1 );
	my $op = convert_cmp_operator( $2 );
	my $count = $3;
	cmp_ok( $value, $op, $count, "the value $value $op $count");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Compare - cucumber step definitions for comparsion checks

=head1 VERSION

version 1.005

=head1 Description

This checks could be used to test configuration variables.

It could be used with a configuration backend like Augeas
to check values in configuration files.

=head1 Synopsis

Load/register configurations in your step files:

  use File::Basename;
  use Test::BDD::Infrastructure::Config;
  use Test::BDD::Infrastructure::Config::Augeas;
  
  my $c = Test::BDD::Infrastructure::Config->new;
  $c->load_config( dirname(__FILE__)."/config.yaml" );
  $c->register_config(
          'a' => Test::BDD::Infrastructure::Config::Augeas->new,
  );

Also load the Compare step definitions:

  use Test::BDD::Infrastructure::Compare;

Then test your configuration:

  Scenario: Resolver must point local resolver
    Then the value $a:/files/etc/resolv.conf/nameserver must be the string 127.0.0.1

=head1 Step definitions

  Then the value <$var> must be like <regex>
  Then the value <$var> must be unlike <regex>
  Then the value <$var> must be <compare> <value>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
