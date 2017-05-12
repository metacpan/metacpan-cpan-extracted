#!/usr/bin/env perl
use utf8;

## Copyright (C) 2013-2017 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use Test::More tests => 6;
use Test::Differences;

use PPI::Document;
use Pod::Weaver;
use Pod::Elemental;
use Pod::Weaver::Config::Assembler;

my @tests = (
  {
    name => "basic usage",
    file_in => <<'ENDIN',
# AUTHOR:  Mary Jane <mary.jane@thisside.com>
# OWNER:   Mary Jane
# LICENSE: Perl_5
ENDIN
      file_out => <<'ENDOUT',
=pod

=head1 AUTHOR

Mary Jane <mary.jane@thisside.com>

=head1 COPYRIGHT

This software is copyright (c) by Mary Jane.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
ENDOUT
  },

  {
    name => "multiple authors and owners",
    file_in => <<'ENDIN',
# AUTHOR:  John Doe <john.doe@otherside.com>
# AUTHOR:  Mary Jane <mary.jane@thisside.com>
# OWNER:   University of Over Here
# OWNER:   Mary Jane
# LICENSE: GPL_3
ENDIN
    file_out => <<'ENDOUT',
=pod

=head1 AUTHORS

John Doe <john.doe@otherside.com>

Mary Jane <mary.jane@thisside.com>

=head1 COPYRIGHT

This software is copyright (c) by University of Over Here, and by Mary Jane.

This software is available under the GNU General Public License, Version 3, June 2007.

=cut
ENDOUT
  },

  {
    name => "test removal of trailing whitespace",
    file_in => <<'ENDIN',
# AUTHOR:  John Doe <john.doe@otherside.com>   
# AUTHOR:  Mary Jane <mary.jane@thisside.com>   
# OWNER:   University of Over Here    
# OWNER:   Mary Jane	
# LICENSE: GPL_3
ENDIN
    file_out => <<'ENDOUT',
=pod

=head1 AUTHORS

John Doe <john.doe@otherside.com>

Mary Jane <mary.jane@thisside.com>

=head1 COPYRIGHT

This software is copyright (c) by University of Over Here, and by Mary Jane.

This software is available under the GNU General Public License, Version 3, June 2007.

=cut
ENDOUT
  },
  {
    name => "multiple authors, owners, and licenses",
    file_in => <<'ENDIN',
# AUTHOR:  John Doe <john.doe@otherside.com>
# AUTHOR:  Mary Jane <mary.jane@thisside.com>
# OWNER:   University of Over Here
# OWNER:   Mary Jane
# LICENSE: GPL_3
# LICENSE: Perl_5
ENDIN
    file_out => <<'ENDOUT',
=pod

=head1 AUTHORS

John Doe <john.doe@otherside.com>

Mary Jane <mary.jane@thisside.com>

=head1 COPYRIGHT

This software is copyright (c) by University of Over Here, and by Mary Jane.

This software is available under the GNU General Public License, Version 3, June 2007, and the same terms as the perl 5 programming language system itself.

=cut
ENDOUT
  },
  {
    name => "test dealing with years",
    file_in => <<'ENDIN',
# AUTHOR:  Mary Jane <mary.jane@thisside.com>
# OWNER:   2005-2007 University of Over Here
# OWNER:   2006, 2010-2012 Mary Jane
# LICENSE: GPL_3
ENDIN
    file_out => <<'ENDOUT',
=pod

=head1 AUTHOR

Mary Jane <mary.jane@thisside.com>

=head1 COPYRIGHT

This software is copyright (c) 2005-2007 by University of Over Here, and 2006, 2010-2012 by Mary Jane.

This software is available under the GNU General Public License, Version 3, June 2007.

=cut
ENDOUT
  },
  {
    name => "big test with many people, year and licenses",
    file_in => <<'ENDIN',
# AUTHOR:  John Doe <john.doe@otherside.com>
# AUTHOR:  Mary Jane <mary.jane@thisside.com>
# AUTHOR:  Darcy <darcy@zombies.com>
# OWNER:   2005-2007 University of Over Here
# OWNER:   2006, 2010-2012 Mary Jane
# OWNER:   Darcy
# LICENSE: MIT
# LICENSE: GPL_3
# LICENSE: Perl_5
ENDIN
    file_out => <<'ENDOUT',
=pod

=head1 AUTHORS

John Doe <john.doe@otherside.com>

Mary Jane <mary.jane@thisside.com>

Darcy <darcy@zombies.com>

=head1 COPYRIGHT

This software is copyright (c) 2005-2007 by University of Over Here, 2006, 2010-2012 by Mary Jane, and by Darcy.

This software is available under the MIT (X11) License, the GNU General Public License, Version 3, June 2007, and the same terms as the perl 5 programming language system itself.

=cut
ENDOUT
  },
);

sub weave
{
  ## This is in part copied from t/legal_section.t in
  ## Pod-Weaver-3.101638
  my $perl_source   = shift;
  my $ppi_document  = PPI::Document->new(\$perl_source);

  ## prepare the weaver
  my $assembler = Pod::Weaver::Config::Assembler->new;
  $assembler->sequence->add_section(
    $assembler->section_class->new({ name => '_' })
  );
  $assembler->change_section('Legal::Complicated');
  my $weaver = Pod::Weaver->new_from_config_sequence( $assembler->sequence );

  my $woven = $weaver->weave_document({
    pod_document => Pod::Elemental->read_string("=pod\n=cut"),
    ppi_document => $ppi_document,
  });

  return $woven->as_pod_string;
}

foreach my $test (@tests)
  {
    my $observed = weave ($test->{file_in});
    eq_or_diff ($observed, $test->{file_out}, $test->{name});
  }
