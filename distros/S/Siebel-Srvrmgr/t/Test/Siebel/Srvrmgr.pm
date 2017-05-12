package Test::Siebel::Srvrmgr;

use Test::More;
use File::Spec;
use parent qw(Test::Class Class::Data::Inheritable);
use Carp;
use Test::Siebel::Srvrmgr::Fixtures qw(data_from_file);

BEGIN {
    __PACKAGE__->mk_classdata('class');
}

sub new {
    my ( $class, $params_ref ) = @_;
    my $self;

    if ( defined($params_ref) ) {    # ones that use get_my_data
        confess "must receive an hash reference as parameter"
          unless ( ref($params_ref) eq 'HASH' );
        $params_ref->{output_file} =
          File::Spec->catfile( @{ $params_ref->{output_file} } );
        $self = $class->SUPER::new( %{$params_ref} );
    }
    else {
        $self = $class->SUPER::new();
    }

    return $self;
}

sub startup : Test( startup => 1 ) {
    my $test = shift;

# removes the Test:: from the child class package name, so it is expected that the resulting package name exists in @INC
    ( my $class = ref $test ) =~ s/^Test:://;
    return 1, "$class loaded" if $class eq __PACKAGE__;
    use_ok $class or die;
    $test->class($class);
}

sub get_output_file {
    my $test = shift;
    return $test->{output_file};
}

sub get_my_data {
    my $test = shift;
    return data_from_file( $test->get_output_file );
}

1;
