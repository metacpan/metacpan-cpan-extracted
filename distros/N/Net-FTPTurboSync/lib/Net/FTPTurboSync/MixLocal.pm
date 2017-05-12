package Net::FTPTurboSync::MixLocal;

use Exception::Class::Base;
use Exception::Class::TryCatch;
use Exception::Class ('FileNotFound' => { fields => [ 'fileName' ] });

sub load {
    my ( $class, $path ) = @_;
    my @stat = lstat $path;
    if ( ! @stat ){
        FileNotFound->throw( $path );
    }        
    my $self = $class->instantiateObject( $path, \@stat );
    return $self;
}    

1;
