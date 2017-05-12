####################################################################
#
#    This file was generated using Parse::Yapp version <<$version>>.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package <<$package>>;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
<<$driver>>

<<$head>>

sub new {
    my $class   = shift;
    my %options = @_;
    my $store   = delete $options{store} || new TM;       # the Yapp parser is picky and interprets this :-/

    ref($class) and $class=ref($class);

    my $self = $class->SUPER::new( 
##				   yydebug   => 0x01,
				   yyversion => '<<$version>>',
				   yystates  =>
<<$states>>,
				   yyrules   =>
<<$rules>>,
				   %options);
    $self->{USER}->{store}         = $store;
    return bless $self, $class;
}

<<$tail>>

1;
