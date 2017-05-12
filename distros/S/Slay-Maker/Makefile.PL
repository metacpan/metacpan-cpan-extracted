use ExtUtils::MakeMaker;

use strict ;
use vars qw( $VERSION ) ;

WriteMakefile(
    'NAME'          => 'Slay::Maker',
    'VERSION_FROM'  => 'lib/Slay/Maker.pm',
#    'EXE_FILES'     => [ 'bin/slaymake' ],
    'PREREQ_PM'     => {
        'IPC::Run'         => 0,
	'Class::Std'       => 0,
    },
);

sub MY::libscan {
   package MY ;
   my $self = shift ;
   my ( $path ) = @_ ;
   return '' if /\.sw[a-z]$/ ;
   return '' unless length $self->SUPER::libscan( $path ) ;
   return $path ;
}
