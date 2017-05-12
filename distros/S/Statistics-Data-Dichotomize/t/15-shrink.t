use Test::More tests => 3;
use constant EPS     => 1e-3;
use Array::Compare;

use Statistics::Data::Dichotomize;
my $ddat = Statistics::Data::Dichotomize->new();

my $data_aref;
my $cmp_aref = Array::Compare->new;
my $debug    = 0;

# shrink (windowize) method
my @raw_data = ( 1, 2, 3, 3, 3, 3, 4, 2, 1 );
my @res_data = ( 0, 1, 1 );
$ddat->load(@raw_data);
$data_aref = $ddat->shrink(
    winlen => 3,
    rule   => sub {
        require Statistics::Lite;
        my $data_aref = shift;
        return Statistics::Lite::mean( @{$data_aref} ) > 2 ? 1 : 0;
    }
);
diag(
    "shrink() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in shrink results" );

@raw_data = (qw/A B c e/);
@res_data = ( 1, 1, 0, 0 );

#$ddat->load(@raw_data);
$data_aref = $ddat->shrink(
    data   => [qw/A B c e/],
    winlen => 1,
    rule   => sub {
        { my $aref = shift; $aref->[0] =~ /[A-Z]/ ? 1 : 0; }
    }
);
diag(
    "shrink() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in shrink results" );

$data_aref = $ddat->shrink(
    data   => [qw/A B c e/],
    winlen => 2,
    rule   => sub {
        {
            my $aref = shift;
            my $str = join q{}, @{$aref};
            $str =~ /[A-Z]{2,}/ ? 1 : 0;
        }
    }
);
@res_data = ( 1, 0 );
diag(
    "shrink() method:\n\texpected\t=>\t",
    join( '', @res_data ),
    "\n\tobserved\t=>\t", join( '', @$data_aref )
) if $debug;
ok( $cmp_aref->simple_compare( \@res_data, $data_aref ),
    "Error in shrink results" );

1;
