# $Id: /mirror/Senna-Perl/lib/Senna/RC.pm 2879 2006-08-31T03:08:01.291533Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::RC;
use strict;
use Senna::Constants;
use overload
    '""'       => \&value,
    '0+'       => \&value,
    'bool'     => \&_to_bool,
    'fallback' => 1
;

sub new
{
    my $class = shift;
    my $value = shift;
    return bless \$value, $class;
}

sub value   { ${$_[0]} }
sub _to_bool { ${$_[0]} == &Senna::Constants::SEN_RC_SUCCESS }

1;

__END__

=head1 NAME

Senna::RC - Wrapper for sen_rc

=head1 SYNOPSIS

  use Senna::RC;
  use Senna::Constants qw(SEN_SUCCESS);

  my $rc = Senna::RC->new(SEN_SUCCESS);
  if ($rc) {
     print "success!\n";
  }

  $rc->value;

=head1 DESCRIPTION

Senna::RC is a simple wrapper around sen_rc that allows you to evaluate
results from Senna functions in Perl-ish boolean context, like

  if ($index->insert($query)) {
    ...
  }

Or, you can choose to access the internal sen_rc value:

  my $rc = $index->insert($query);
  if ($rc->value == SEN_SUCCESS) {
    ...
  }

=head1 METHODS

=head2 new

Creates a new Senna::RC object

=head2 value

Returns the internal sen_rc value

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut
