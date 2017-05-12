package Spreadsheet::Engine::Fn::text;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

use Encode;

sub signature   { 't' }
sub result_type { 't' }

sub result {
  my $self = shift;
  return Spreadsheet::Engine::Value->new(
    type  => $self->result_type,
    value => encode('utf8', $self->calculate($self->_opvals)),
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::text - base class for text functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::text';

  sub calculate { ... }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that operate on
text, such as UPPER(), LOWER(), REPLACE() etc.

=head1 INSTANCE METHODS

=head2 calculate

Subclasses should provide this as the workhorse. It should either return
the result, or die with an error message (that will be trapped and
turned into a spreadsheet error).

=head2 result_type

Most text functions return a text string, so we provide that as the
default value. Functions that return something different (e.g. LENGTH)
should override this.

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0


