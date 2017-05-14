package Net::HTTP::Knork::Role::Middleware; 
# ABSTRACT: Role implementing middleware capabilities for Knork main class
use Moo::Role; 
use Carp;
use Class::Method::Modifiers qw/install_modifier/;

requires qw/perform_request generate_response/;


sub add_middleware {
    my $self    = shift;
    my $mw_spec = shift;
    croak
      "A middleware should specify at least a action 'on_requests' or 'on_response'"
      unless ( defined( $mw_spec->{on_request} )
        || defined( $mw_spec->{on_response} ) );
    my $class = ref($self);
    if ( $mw_spec->{on_request} ) {
        install_modifier $class, 'around', 'perform_request', sub {
            my $orig = shift;
            my ( $self, $request ) = @_;
            my $meth        = $mw_spec->{on_request};
            my $new_request = $meth->($self,$request);
            $orig->( $self, $new_request );
          }
    }

    if ( $mw_spec->{on_response} ) {
        install_modifier $class, 'around', 'generate_response', sub {
            my $orig = shift;
            my ( $self, $resp ) = @_;
            my $meth        = $mw_spec->{on_response};
            my $old_resp = $resp->clone;
            my $new_resp = $meth->($self,$old_resp);
            $orig->( $self, $new_resp, $resp );
          }
    }
}

1; 

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Knork::Role::Middleware - Role implementing middleware capabilities for Knork main class

=head1 VERSION

version 0.20

=head1 AUTHOR

Emmanuel Peroumalnaïk

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by E. Peroumalnaik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
