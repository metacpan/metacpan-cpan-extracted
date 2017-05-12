package Template::Plugin::DBM::Deep;

use 5.006;
use strict;
use warnings;

use base qw(Template::Plugin);

our $VERSION = '0.02';

sub new {
  my $class = shift;
  my $context = shift;		# passed by Template's USE

  my %ARGS;
  ## do we have any named args?
  if (ref $_[-1] and ref $_[-1] eq "HASH") {
    %ARGS = %{+pop};
  };
  ## do we have any positional args?
  if (@_) {
    $ARGS{"file"} = shift;
  }
  ## do we have too many?
  if (@_) {
    die "extra arguments to $class: @_";
  }

  die "$class: missing db file" unless $ARGS{"file"};

  ## now create the DBM::Deep object and return it:
  return $class->dbm_deep_class->new(%ARGS);
}

## lazy load DBM::Deep, and also return constant
## this permits overriding of the class
sub dbm_deep_class { require DBM::Deep; "DBM::Deep" }

1;
__END__

=head1 NAME

Template::Plugin::DBM::Deep - Template Toolkit plugin for DBM::Deep

=head1 SYNOPSIS

  [% USE db = DBM.Deep(file = "my.db" locking = 1 autoflush = 1);
     db.lock;
     db.flintstones = { "flintstone" = ["fred" "wilma"]
                        "rubble" = ["barney" "betty"] };
     db.castaways = ["gilligan" "skipper" "professor" "and the rest" ];
     db.unlock;
  -%]
  ...
  [% db.flintstones.rubble.0; %] -- barney
  [% db.castaways.3; %] -- and the rest

=head1 DESCRIPTION

This module permits the direct use of C<DBM::Deep>, a persistent
sharable store for nearly arbitrarily nested hashes and arrays, within
Template Toolkit code.

The initial constructor returns the top-level C<DBM::Deep> object.
All keyword arguments are passed to the C<DBM::Deep> constructor as a
flat list. Any single positional argument is presumed to be the
C<file> keyword parameter, permitting simple invocations like:

  USE db = DBM.deep("my.db");

All appropriate method calls described in L<DBM::Deep/OO Interface>
are available.  In addition, hash-like objects can use direct keys
to get at values:

  db.foo = "bar";
  db.foo; # gets "bar"

And array-like objects can use direct indicies:

  db.mylist = ["a" "b" "c"];
  db.mylist.2; # gets "c"

B<Caution:> VMethods do B<not> work against the hash-like or
array-like objects.  However, you can use the C<export> method to get
an unattached cloned copy of that portion of the database, and then
the normal vmethods work:

  "$key\n" FOR key IN db.export.keys;

Failure to C<export> first will result in attempting to access a hash
element called C<keys>, which doesn't exist.

There are probably other limitations.  If you find other weirdness,
let me know so I can update this document.

=head1 METHODS

=over 4

=item new

Used by Plugin interface.

=item dbm_deep_class

Used by Plugin interface.

=back

=head1 SEE ALSO

L<DBM::Deep>

=head1 AUTHOR

Randal L. Schwartz, E<lt>merlyn@stonehenge.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Randal L. Schwartz, Stonehenge Consulting Services, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
