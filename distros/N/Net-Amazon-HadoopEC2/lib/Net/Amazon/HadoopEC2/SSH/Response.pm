package Net::Amazon::HadoopEC2::SSH::Response;
use Moose;
use Moose::Util::TypeConstraints;

has stdout => ( is => 'ro', isa => 'Maybe[Str]' );
has stderr => ( is => 'ro', isa => 'Maybe[Str]' );
has code   => ( is => 'ro', isa => 'Int' );

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

Net::Amazon::HadoopEC2::SSH::Response - Class representing Net::Amazon::HadoopEC2::SSH resopnse

=head1 DESCRIPTION

This module is a class representing Net::Amazon::HadoopEC2::SSH resopnse.

=head1 METHODS

=head2 new

Constructor. 

=head1 ATTRIBUTES

=head2 stdout

STDOUT of L<Net::SSH::Perl> cmd response.

=head2 stderr

STDERR of L<Net::SSH::Perl> cmd response.

=head2 code

exit code of L<Net::SSH::Perl> cmd response.

=head1 AUTHOR

Nobuo Danjou L<nobuo.danjou@gmail.com>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2>

L<Net::SSH::Perl>

=cut
