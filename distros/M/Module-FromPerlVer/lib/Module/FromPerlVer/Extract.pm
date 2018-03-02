########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Extract;
use 5.006;

use NEXT;

use Carp            qw( croak   );
use Scalar::Util    qw( blessed );

########################################################################
# package variables
########################################################################

our $VERSION    = '0.1';

my $nil = {};

########################################################################
# methods
########################################################################

sub value
{
    my ( $extract, $k, ) = splice @_, 0, 2;

    defined $k
    or croak "Bogus value: undefined key";

    if( @_ )
    {
        my $v   = shift;

        defined $v
        ? $extract->{ $k } = $v
        : delete $extract->{ $k }
    }
    else
    {
        $extract->{ $k }
    }
}

sub init
{
    my $extract = shift;

    if
    (
        my $argz
        = @_ > 1 ? { @_ }   # flat list -> hash
        : @_ > 0 ? shift    # hashref
        : ''                # nada
    )
    {
        while( my($k,$v) = each %$argz )
        {
            $extract->value( $k => $v )
        }
    }

    return
}

sub construct
{
    my $proto   = shift;

    bless +{}, blessed $proto || $proto
}

sub new
{
    my $extract = &construct;

    $extract->EVERY::LAST::init( @_ );
    $extract
}

# keep require happy
1
__END__
