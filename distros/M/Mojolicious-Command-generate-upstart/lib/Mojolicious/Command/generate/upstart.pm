package Mojolicious::Command::generate::upstart;
use Mojo::Base 'Mojolicious::Command';

use File::Spec;
use Getopt::Long 'GetOptions';
use Mojo::ByteStream 'b';
use Mojo::Util 'dumper';

has description => "Generate application upstart job\n";
has usage => <<EOF;
usage: $0 generate upstart [OPTIONS]

These options are available:
    --output <folder>   Set folder to output upstart job (default: .)
    --deploy            Deploy upstart into /etc/init
    --name <name>       Ovewrite name which is used for upstart job
EOF

=head1 NAME

Mojolicious::Command::generate::upstart - upstart job generator command

=head1 SYNOPSYS

	$ ./mojo_app.pl generate help upstart
	usage: ./mojo_app.pl generate upstart [OPTIONS]

	These options are available:
		--output <folder>   Set folder to output upstart job (default: .)
		--deploy            Deploy upstart into /etc/init
		--name <name>       Ovewrite name which is used for upstart job

=cut

our $VERSION = '0.02';

sub run {
  my ($self, @args) = @_;

  #$self->app->plugin('DefaultHelpers');

  GetOptions(
    'output=s' => \my $output,
    'deploy' => \my $deploy,
    'name=s' => \my $name,
  );

  if ( !$name ) {
    my (undef, undef, $filename) = File::Spec->splitpath($0);
    ($name) = $filename =~ m/^(.*?)(?:\.pl)?$/;
  }

  $self->app->moniker($name);

  if ( !( $deploy || $output ) ) {
    $output = '.';
  }
  if ( $deploy && $output ) {
    die qq{Either --deploy or --output <folder> should be specified but not both\n};
  }
  if ( $deploy && !$self->user_is_root ) {
    $output = '.';
    $deploy = 0;
  }

  my $file = $deploy
    ? File::Spec->join('', 'etc', 'init', $self->app->moniker.'.conf')
    : File::Spec->join($output, 'etc_init_'.$self->app->moniker.'.conf');
  $self->render_to_file('upstart', $file, $self->app);
  $self->chmod_file($file, 0755);

  # config file
  $file = $deploy
    ? File::Spec->join('', 'etc', 'default', $self->app->moniker)
    : File::Spec->join($output, 'etc_default_'.$self->app->moniker);
  $self->render_to_file('config', $file, $self->app);
  $self->chmod_file($file, 0644);
}

sub user_is_root { $> == 0 || $< == 0 }

__DATA__
@@ upstart
% my $app = shift;
# <%= $app->moniker %>

description	"<%= $app->moniker %> - <%= $app->moniker.' upstart job' %>"

start on runlevel [2345]
stop on runlevel [!2345]

pre-start exec hypnotoad <%= File::Spec->rel2abs($0) %>
post-stop exec hypnotoad <%= File::Spec->rel2abs($0) %> -s

@@ config
<%= Data::Dumper->new([shift->config])->Purity(1)->Terse(1)->Indent(1)->Dump %>

__END__

=head1 AUTHOR

Stefan Adams, C<< <s1037989 at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Command::generate::upstart


You can also look for information at:

=over 4

=item * github repository

L<http://github.com/s1037989/mojolicious-command-generate-upstart/>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Command-generate-upstart/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Stefan Adams.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
