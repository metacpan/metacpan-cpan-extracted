package SimpleMock::ScopeGuard;
use strict;
use warnings;
use Scalar::Util qw(refaddr);                                                                                                                                            
                  
sub new {
    my ($class, $layer) = @_;
    return bless { layer => $layer }, $class;
}                                                                                                                                                                        
  
sub DESTROY {                                                                                                                                                            
    my $self = shift;
    my $id = refaddr($self->{layer});
    @SimpleMock::MOCK_STACK = grep { refaddr($_) != $id } @SimpleMock::MOCK_STACK;
} 

1;

=head1 NAME

SimpleMock::ScopeGuard

=head1 SYNOPSIS

    use SimpleMock qw(register_mocks_scoped);

    {
        my $guard = register_mocks_scoped(
            SUBS => {
                'My::Module' => {
                    my_sub => [{ returns => 'scoped value' }],
                },
            },
        );
        # scoped mocks are active here
    }
    # $guard goes out of scope, DESTROY fires, scoped layer is removed

=head1 DESCRIPTION

Helper module to manage scoped mocks via an object that uses DESTROY to remove
scoped mocks. The layer is identified by reference address (via
C<Scalar::Util::refaddr>), so nested scopes are safe regardless of exit order.

You should not need to use this module directly. Instead, use
C<register_mocks_scoped> from L<SimpleMock>, which returns a ScopeGuard object.

=cut
