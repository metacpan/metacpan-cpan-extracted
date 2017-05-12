package Net::StackExchange::Role::Request;
BEGIN {
  $Net::StackExchange::Role::Request::VERSION = '0.102740';
}

# ABSTRACT: Common request methods

use Carp qw{ croak };
use Moose::Role;
use Moose::Util::TypeConstraints;

has 'type' => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {
        my ( $self, $type ) = @_;

        if ( $type ne 'jsontext' ) {
            confess q{the only valid value is 'jsontext'};
        }
    },
);

has [
    qw{
        key
        jsonp
      }
    ] => (
    is  => 'rw',
    isa => 'Str',
);

no Moose::Role;
no Moose::Util::TypeConstraints;

1;



=pod

=head1 NAME

Net::StackExchange::Role::Request - Common request methods

=head1 VERSION

version 0.102740

=head1 ATTRIBUTES

=head2 C<type>

The only valid value is C<jsontext>. Responds with mime-type text/json, if set.

=head2 C<key>

Accepts a key and validates this request to a specific application.

=head2 C<jsonp>

If set, the response returns JSON with Padding instead of standard JSON.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

