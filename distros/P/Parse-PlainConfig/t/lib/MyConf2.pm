package MyConf2;

use strict;
use warnings;

use Parse::PlainConfig;
use Parse::PlainConfig::Constants;
use MyConf;
use base qw(MyConf);
use vars qw(%_globals %_parameters %_prototypes);

%_parameters = (
    'random thought' => PPC_SCALAR,
    );

%_prototypes = (
    'declare bar' => PPC_SCALAR
    );

1;

__DATA__
; This is a sample conf file that not only provides a reference config but
; also supplies the default values of any parameter not explicitly set below.
; 
; admin email:  email address of the admin
admin email root@yourhost   

random thought 3.14

declare foo bar roo
declare bar foo roo

__END__

=head2 POD STARTS HERE

Arg!
