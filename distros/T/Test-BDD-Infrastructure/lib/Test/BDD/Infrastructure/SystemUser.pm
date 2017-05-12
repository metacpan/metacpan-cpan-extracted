package Test::BDD::Infrastructure::SystemUser;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for checking passwd/groups
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }


Given qr/^the system user (\S+) exists$/, sub {
  my @user = CORE::getpwnam($1);
  if( ! @user ) {
    fail('system user '.$1.' does not exist!');
    return;
  }
  pass("system user $1 does exist.");
  S->{'system_user'} = \@user;
};

Then qr/^the system users uid must be (\d+)$/, sub {
  cmp_ok( S->{'system_user'}->[2], '==', $1, 'must have correct uid');
};

Then qr/^the system users primary group must be (\d+)$/, sub {
  cmp_ok( S->{'system_user'}->[3], '==', $1, 'must have correct gid');
};

Then qr/^the system users comment must be like (.*)$/, sub {
  like( S->{'system_user'}->[6], qr/$1/, "system users comment must match: $1");
};

Then qr/^the system users home directory must be (.*)$/, sub {
  cmp_ok( S->{'system_user'}->[7], 'eq', $1, "home directory must be $1");
};

Then qr/^the system users shell must be (.*)$/, sub {
  cmp_ok( S->{'system_user'}->[8], 'eq', $1, "shell must be $1");
};

Given qr/^the system group (\S+) exists$/, sub {
  my @group;
  @group = CORE::getgrnam($1);
  if( ! @group ) {
    fail('system group '.$1.' does not exist!');
    return;
  }
  pass("system group $1 does exist.");
  S->{'system_group'} = \@group;
};

Then qr/^the system groups gid must be (\d+)$/, sub {
  cmp_ok( S->{'system_group'}->[2], '==', $1, 'must have correct group id');
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::SystemUser - cucumber step definitions for checking passwd/groups

=head1 VERSION

version 1.005

=head1 Synopsis

=head1 Step definitions

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
