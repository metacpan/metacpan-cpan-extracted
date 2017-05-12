package Net::StackExchange;
BEGIN {
  $Net::StackExchange::VERSION = '0.102740';
}

# ABSTRACT: Access Stack Exchange API from Perl

use Moose;
use Moose::Util::TypeConstraints;

use Carp qw{ confess };

use Net::StackExchange::Core;
use Net::StackExchange::Route;
use Net::StackExchange::Types;
use Net::StackExchange::Owner;
use Net::StackExchange::Answers;
use Net::StackExchange::Answers::Request;
use Net::StackExchange::Answers::Response;

has 'network' => (
    is  => 'ro',
    isa => enum( [
        qw{
            stackoverflow.com
            serverfault.com
            meta.stackoverflow.com
            superuser.com
            stackapps.com
            webapps.stackexchange.com
            gaming.stackexchange.com
            webmasters.stackexchange.com
            cooking.stackexchange.com
            gamedev.stackexchange.com
            gadgets.stackexchange.com
            photo.stackexchange.com
            stats.stackexchange.com
            math.stackexchange.com
            diy.stackexchange.com
            gis.stackexchange.com
            tex.stackexchange.com
            ubuntu.stackexchange.com
            money.stackexchange.com
            english.stackexchange.com
            ui.stackexchange.com
            unix.stackexchange.com
            wordpress.stackexchange.com
            cstheory.stackexchange.com
            apple.stackexchange.com
            rpg.stackexchange.com
          }
    ] ),
    required => 1,
);

has 'version' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '1.0',
);

has 'route' => (
    is  => 'rw',
    isa => 'Str',
);

around 'route' => sub {
    my ( $method, $self, $route ) = @_;

    # this is a workaround as enum() requires at least two values
    if ( $route ne 'answers' ) {
        confess q{'answers' is the only valid value'};
    }

    $route = "\u$route";
    return Net::StackExchange::Route->new( {
        '_NSE'   => $self,
        '_route' => $route,
    } );
};

__PACKAGE__->meta()->make_immutable();
no Moose;

1;



=pod

=head1 NAME

Net::StackExchange - Access Stack Exchange API from Perl

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

    use Net::StackExchange;

    my $se = Net::StackExchange->new( {
        'network' => 'stackoverflow.com',
        'version' => '1.0',
    } );

    my $answers_route   = $se->route('answers');
    my $answers_request = $answers_route->prepare_request( { 'id' => '1036353' } );

    $answers_request->body(1);

    my $answers_response = $answers_request ->execute( );
    my $answer           = $answers_response->answers(0);

    print "__Answer__\n";
    print "Title: ", $answer->title(), "\n";
    print "Body: ",  $answer->body (), "\n";

=head1 ATTRIBUTES

=head2 C<new>

Accepts a hash reference with C<network> and C<version> as keys. Returns a
L<Net::StackExchange> object.

=over 4

=item * C<network>

Sets the network to which API requests should be sent. Valid values are:

      stackoverflow.com
      serverfault.com
      meta.stackoverflow.com
      superuser.com
      stackapps.com
      webapps.stackexchange.com
      gaming.stackexchange.com
      webmasters.stackexchange.com
      cooking.stackexchange.com
      gamedev.stackexchange.com
      gadgets.stackexchange.com
      photo.stackexchange.com
      stats.stackexchange.com
      math.stackexchange.com
      diy.stackexchange.com
      gis.stackexchange.com
      tex.stackexchange.com
      ubuntu.stackexchange.com
      money.stackexchange.com
      english.stackexchange.com
      ui.stackexchange.com
      unix.stackexchange.com
      wordpress.stackexchange.com
      cstheory.stackexchange.com
      apple.stackexchange.com
      rpg.stackexchange.com

=item * C<version>

Sets the API version. Defaults to C<1.0>.

=back

=head2 C<route>

Returns a L<Net::StackExchange::Route> object depending on the route that is
passed to it. Valid routes are:

    answers

=head1 !!! WARNING !!!

Incomplete implementation. Interface may change.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

