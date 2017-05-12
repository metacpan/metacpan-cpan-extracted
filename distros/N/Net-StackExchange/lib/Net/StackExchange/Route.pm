package Net::StackExchange::Route;
BEGIN {
  $Net::StackExchange::Route::VERSION = '0.102740';
}

# ABSTRACT: Builds appropriate request object

use Moose;

has '_route' => (
    is  => 'ro',
    isa => 'Str',
);

has '_NSE' => (
    is       => 'ro',
    isa      => 'Net::StackExchange',
    required => 1,
);

sub prepare_request {
    my ( $self, $arg ) = @_;

    $arg->{'_NSE'} = $self->_NSE();
    my $route      = $self->_route();
    return "Net::StackExchange::${route}::Request"->new($arg);
}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::StackExchange::Route - Builds appropriate request object

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

    use Net::StackExchange;

    my $se = Net::StackExchange->new( {
        'network' => 'stackoverflow.com',
        'version' => '1.0',
    } );

    my $answers_route   = $se->route('answers');
    my $answers_request = $answers_route->prepare_request( { 'id' => 1036353 } );

=head1 METHODS

=head2 C<prepare_request>

Returns respective request object based on the route with which this object has
been created. The request object for the particular route will be constructed
using the hash reference that is passed to C<prepare_request>.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

