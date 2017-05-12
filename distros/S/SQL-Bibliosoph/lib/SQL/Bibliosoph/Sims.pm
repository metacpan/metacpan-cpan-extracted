#
#===============================================================================
#         FILE:  Bibliosoph::Sims.pm
#      CREATED:  07/05/2009 01:59:31 PM
#===============================================================================
#
#

=head1 NAME

SQL::Bibliosoph::Sims - A SQL::Bibliosoph Tester library


=head1 SYNOPSIS

    my $bs = SQL::Bibliosoph::Sims();

    my $array_of_hashes = $bs->h_ANYQUERY();
    my $hash            = $bs->rowh_ANYQUERY();
    my $array_of_arrays = $bs->ANYQUERY();

    This is a simple class to replace SQL::Bibliosoph in unit test. This generate random data and does not need a catalog file. (Methods are handled on request with AUTOLOAD). The returned value is in concordance with the requested resulset( e.g.: If you ask for that hash (with the prefix rowh_) you will get a hashref).
        

=head1 DESCRIPTION

Will generate random date when you call any subrotine on it.  This module is inspired on Test::Sims.


=head1 Constructor parameters

=head3 rows

    This controls how many rows will be returned in the resultset. Defaults to 10.

=head3 presets 

    You can costumize the return of some particular query by using preset, like this:

    my $bs = SQL::Bibliosoph::Sims(
                    presets => {
                        rowh_user       => '{ name => "juan", age => "42" }',
                        rowh_costumer   => '{ 
                                    name => "rand_words( size=>10 )", 
                                    age =>  "rand_chars( size=>2 )",
                        }',
                    }
    );

    Values in the array will be evaluated. You can use rand_ functions from Data::Random to generate your values.. presets queries have preference over presets_catalog quieres.


=head3 presets_catalog

    You can also define catalog for tests. In this case, the queries not defined in the catalog will be random generated. The defined, will be evaluated:

    my $bs = SQL::Bibliosoph::Sims->new(
                    presets_catalog => 'tests.bb',
    );

    tests.bb:
--[ TITo ]
    { a=>1, b=>2 }
--[ rowh_RANDy ]    
    {name => join "", rand_chars( set=> "alpha", min=>5, max=>7) } 
--[ rowh_RAND2y ]
     {name => join "", rand_chars( set=> "numeric", min=>5, max=>7) }
--[ h_RAND3 ]
    [ { id => (join '',rand_chars(set=>"numeric")), name => join ('', rand_chars(set=>"alpha")), role_code => 1 }, ],
--[ h_RAND4 ]
    [ { id =>1 }, { id => 2 }, { id => 3 } , ],

=head1 BUGS
    
    If you use presets_catalog, arrays references [] rows MUST BE ended with a ',' (comma), like in:

--[ h_RAND4 ]
    [ { id =>1 }, { id => 2 }, { id => 3 } , ],


 

=cut

package SQL::Bibliosoph::Sims; {
    use Moose;
    use Carp;
    use Data::Dumper;

	our $VERSION = "2.0";
    our $AUTOLOAD;

    use SQL::Bibliosoph::CatalogFile;

    use Tie::Array::Random;
    use Tie::Hash::Random;
    use Data::Random qw(:all);
    use feature qw/switch/;
    use Data::Dumper;

    has rows    => (is => 'rw', isa => 'Int', default=> '10');
    has presets => (is => 'rw', isa => 'HashRef', default=> sub { return {};  } );
    has presets_catalog => (is => 'rw', isa => 'Str');

    sub BUILD {
        my ($self) = @_;
        my $qs;

        # Add catalog's presets, if any.

        my $file = $self->presets_catalog();
        if ($file) {

            die "$file: $!" if ! -e $file;

            my  $qs = SQL::Bibliosoph::CatalogFile->new( file => $file )->read();

            while (my ($k, $v) = each %$qs) {
                $self->presets()->{$k} = $v;

            }
        }

        return $self;
    }


    sub AUTOLOAD {
        my $self        = shift;
        (my $method_name = $AUTOLOAD ) =~ s/^.*:://;
        my $ret;

        my $rows = $self->rows();


        die "no method name @_" if ! $method_name;

        if (my $return = $self->presets()->{$method_name}) {
            my $ret = eval $return;
            if ($@) {
                die "Error in \"$method_name\": $@\n $return \n";
            }
            return $ret;
        }


        given ($method_name) {
            when (/\browh_/)  {
                my %hash;
                tie %hash, 'Tie::Hash::Random';
                $ret = \%hash;

                return $ret;
            }
            when (/\brow_/)  {
                my @array;
                tie @array, 'Tie::Array::Random';
                $ret = \@array;

                return $ret;
            }
            when (/\bh_/)  {
                my $ret = [];
                foreach (1..$rows) {
                    my %hash;
                    tie %hash, 'Tie::Hash::Random';
                    push @$ret, \%hash;
                }
                return wantarray  ? ($ret,$rows) : $ret;
            }
            default {
                my $ret = [];
                foreach (1..$rows) {
                    my @array;
                    tie @array, 'Tie::Array::Random';
                    push @$ret, \@array;
                }
                return wantarray  ? ($ret,$rows) : $ret;
            }
        };
    }

}


1;

__END__


