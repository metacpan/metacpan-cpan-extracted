=head1 NAME

Net::FCP::Key::SSK - manage SSK keys.

=head1 SYNOPSIS

 use Net::FCP::Key::SSK;

 my $key = new Net::FCP::Key::SSK $public, $private[, $crypto]
 my $key = new_from_file Net::FCP::Key::SSK $path;
 my $key = new_from_fcp Net::FCP::Key::SSK $fcp;
 my $key = new_from_string Net::FCP::Key::SSK $string;

 $key->as_string;
 $key->save ($path);

 my $ssk_public_uri  = $key->gen_pub  ($name);
 my $ssk_private_uri = $key->gen_priv ($name);

=head1 DESCRIPTION

=head2 THE Net::FCP::Key::SSK CLASS

=over 4

=cut

package Net::FCP::Key::SSK;

use Carp;

no warnings;

=item my $key = new Net::FCP::Key::SSK $public, $private[, $crypto]

=item my $key = new_from_file Net::FCP::Key::SSK $path;

=item my $key = new_from_fcp Net::FCP::Key::SSK $fcp;

Various way to create a SSK key object.

=cut

sub new {
   my $class = shift;

   bless {
      pub => $_[0],
      pri => $_[1],
      ent => $_[2],
   }, $class;
}

sub new_from_fcp {
   my ($class, $fcp) = @_;

   $class->new (@{ $fcp->generate_svk_pair })
}

sub new_from_string {
   my ($class, $string) = @_;

   $class->new ((split /[\x00-\x1f,]/, $string)[0,1,2])
}

sub new_from_file {
   my ($class, $path) = @_;

   open my $fh, "<", $path
      or croak "$path: $!";

   $class->new_from_string (scalar readline $fh);
}

=item $key->save ($path)

Write the key to the givne file. Unencrypted.

=cut

sub save {
   my ($self, $path) = @_;

   open my $fh, ">", $path
      or croak "$path: $!";

   print $fh $self->as_string, "\n";
}

=item $key->as_string

Returns a stringified version fo the key data (in no standard format).

=cut

sub as_string {
   my ($self) = @_;

   "$self->{pub},$self->{pri},$self->{ent}";
}

=item my $puburi = $key->gen_pub ($name)

Build a public SSK subkey with the given name and return it as a URI without
C<freenet:>-prefix.

=cut

sub gen_pub {
   my ($self, $name) = @_;

   "SSK\@$self->{pub}PAgM,$self->{ent}/$name";
}

=item my $privuri = $key->gen_priv ($name)

Build a private SSK subkey with the given name and return it as a URI without
C<freenet:>-prefix.

=cut

sub gen_priv {
   my ($self, $name) = @_;

   "SSK\@$self->{pri},$self->{ent}/$name";
}

=back

=head1 SEE ALSO

L<Net::FCP>.

=head1 BUGS

Not heavily tested.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;

