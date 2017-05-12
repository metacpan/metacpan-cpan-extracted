use v5.16;
use warnings;

package Net::Minecraft::LoginResult {

  # ABSTRACT: Result info for a Minecraft Login.

  use Moo;

  with 'Net::Minecraft::Role::LoginResult';

  use Params::Validate qw( validate SCALAR );


  sub is_success { return 1 }


  has current_version => ( is => rwp =>, required => 1 );
  has download_ticket => ( is => rwp =>, required => 1 );
  has user            => ( is => rwp =>, required => 1 );
  has session_id      => ( is => rwp =>, required => 1 );
  has unique_id       => ( is => rwp =>, required => 1 );


  sub parse {
    my ( $class, $content ) = @_;
    state $field_order = [qw( current_version download_ticket user session_id unique_id )];
    my (@parts) = split /:/, $content;
    return $class->new( map { ( $field_order->[$_], $parts[$_] ) } 0 .. $#{$field_order} );
  }

};
BEGIN {
  $Net::Minecraft::LoginResult::AUTHORITY = 'cpan:KENTNL';
}
{
  $Net::Minecraft::LoginResult::VERSION = '0.002000';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Minecraft::LoginResult - Result info for a Minecraft Login.

=head1 VERSION

version 0.002000

=head1 METHODS

=head2 C<is_success>

Always returns a truth value for instance of this class.

=head2 C<parse>

Inflate a L<< C<::LoginResult>|Net::Minecraft::LoginResult >> from a content string supplied by the server.

	my $instance = Net::Minecraft::LoginResult->parse( $string );

This will ordinarily be a string like:

	1343825972000:deprecated:SirCmpwn:7ae9007b9909de05ea58e94199a33b30c310c69c:dba0c48e1c584963b9e93a038a66bb98

Which we simply split on ':' and store in the respective fields.

=head1 ATTRIBUTES

=head2 C<current_version>

The C<timestamp> in C<UnixTime> of the most recent Minecraft version ( the game itself, not the launcher )

=head2 C<download_ticket>

Will always return "deprecated" as this feature is no longer valid.

=head2 C<user>

The Case Corrected form of the supplied user name.

=head2 C<session_id>

A Unique Session Identifier

=head2 C<unique_id>

A (presently unused) unique User Identifier.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Minecraft::LoginResult",
    "inherits":"Moo::Object",
    "does":"Net::Minecraft::Role::LoginResult",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
