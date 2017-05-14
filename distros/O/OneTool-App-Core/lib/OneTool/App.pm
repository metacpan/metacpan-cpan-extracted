package OneTool::App;

=head1 NAME

OneTool::App - Module for any OneTool onetool_*.pl program

=head1 DESCRIPTION

It defines default options for any onetool_*.pl program

Deafult options are:
  -D/--debug
  -h/--help
  -v/--version
  
=cut

use strict;
use warnings;

our @DEFAULT_OPTIONS = ('debug|D', 'help|h', 'version|v',);

1;

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut
