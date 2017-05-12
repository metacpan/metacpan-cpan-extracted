package Oracle::SQL;

use strict;

use POSIX qw(strftime);
use Carp;
use warnings;
use DBI;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(

);
our @EXPORT_OK = qw(
);
our %EXPORT_TAGS = (
    sql    => [qw(
              )],
    all    => [@EXPORT_OK],
);
our @IMPORT_OK   = qw(
    );

our $VERSION = '0.01';

# bootstrap Oracle::SQL::Builder $VERSION;

=head1 NAME

Oracle::SQL - Perl extension for building SQL statements.

=head1 SYNOPSIS

  use Oracle::SQL;

No automatically exported routines. You have to specifically to import
the methods into your package.

  use Oracle::SQL qw(:sql);
  use Oracle::SQL /:sql/;
  use Oracle::SQL ':sql';

=head1 DESCRIPTION

This is a package initializing object for Oracle::SQL::Builder.

=cut

=head3 new (%arg)

Input variables:

  any input variable and value pairs

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::SQL;      # or
   my $obj = Oracle::SQL->new;     # or

Return: new empty or initialized Oracle::SQL object.

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    foreach my $k ( keys %arg ) { $self->{$k} = $arg{$k}; }
    return $self;
}

1;

=head1 SEE ALSO (some of docs that I check often)

Oracle::Trigger, Oracle:DDL, Oracle::DML, Oracle::DML::Common,
Oracle::Loader, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut


