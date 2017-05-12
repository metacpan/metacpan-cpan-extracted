package Rose::DB::Constants;

use strict;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(IN_TRANSACTION);

use constant IN_TRANSACTION => -1;

1;

__END__

=head1 NAME

Rose::DB::Constants - Symbolic names for important Rose::DB constants.

=head1 SYNOPSIS

  use Rose::DB::Constants qw(IN_TRANSACTION);
  ...

  $ret = $db->begin_work or die $db->error;
  ...
  unless($ret == IN_TRANSACTION)
  {
    $db->commit or die $db->error;
  }

=head1 DESCRIPTION

This module contains and optionally exports symbolic names for important L<Rose::DB> constants.  The only constant defined so far is C<IN_TRANSACTION>.  See the documentation for L<Rose::DB>'s C<begin_work()> object method for more information on this constant.

This module inherits from C<Exporter>.  No symbols are exported by default.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
