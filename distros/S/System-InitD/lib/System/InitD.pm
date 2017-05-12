package System::InitD;

=head1 NAME

System::InitD

=head1 DESCRIPTION

Simple and cool toolkit for init.d scripts creation under linux systems. This distrubution includes toolkit itself
and generator tool, geninitd, which generates init.d perl script skeleton.

You can see perldoc for geninitd

    perldoc geninitd

Also, for available System::InitD API see perldoc for System::InitD::Runner

=head1 HISTORY

One day I tried to improve existing init.d bash script of some project and it was very painful.
I love perl, so I decided to create some useful toolkit for init.d scripts written in perl.

=cut

use strict;
use warnings;

use System::InitD::Runner;
use System::InitD::Const;

our $VERSION = '1.36';
our $ABSTRACT = "Toolkit for perl init.d manipulation";

1;

__END__

