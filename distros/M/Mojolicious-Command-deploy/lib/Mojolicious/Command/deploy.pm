package Mojolicious::Command::deploy;
use Mojo::Base 'Mojolicious::Commands';

our $VERSION = '0.02';

has description => "Deploy Mojolicious apps to the cloud.\n";
has hint        => <<"EOF";

See '$0 deploy help DEPLOYMENT' for more information on a specific deployment.
EOF
has message => <<"EOF";
usage: $0 deploy DEPLOYMENT [OPTIONS]

These deployments are currently available:
EOF
has namespaces =>
  sub { [qw/Mojolicious::Command::deploy Mojo::Command::deploy/] };
has usage => "usage: $0 deploy DEPLOYMENT [OPTIONS]\n";

1;

__END__

=head1 NAME

Mojolicious::Command::deploy - Deployment command

=head1 SYNOPSIS

  use Mojolicious::Command::deploy;

  my $deployment = Mojolicious::Command::deploy->new;
  $deployment->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::deploy> lists available deployments.

This command provides the structure for other modules.  
It is not intended to be used directly.

=head1 ATTRIBUTES

L<Mojolicious::Command::deploy> inherits all attributes from
L<Mojolicious::Commands> and implements the following new ones.

=head2 C<description>

  my $description = $deployment->description;
  $deployment      = $deployment->description('Foo!');

Short description of this command, used for the command list.

=head2 C<hint>

  my $hint   = $deployment->hint;
  $deployment = $deployment->hint('Foo!');

Short hint shown after listing available deployment commands.

=head2 C<message>

  my $message = $deployment->message;
  $deployment  = $deployment->message('Bar!');

Short usage message shown before listing available deployment commands.

=head2 C<namespaces>

  my $namespaces = $deployment->namespaces;
  $deployment     = $deployment->namespaces(['Mojo::Command::deploy']);

Namespaces to search for available deployment commands, defaults to
L<Mojolicious::Command::deploy> and L<Mojo::Command::deploy>.

=head1 METHODS

L<Mojolicious::Command::deploy> inherits all methods from
L<Mojolicious::Commands>.

=head1 CREDITS

Chankey Pathak

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
