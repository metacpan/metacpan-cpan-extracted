# wp-on-mojo.pl: run WordPress on Mojolicious in 34 lines of code
# (28 if you take out the stuff about bitches)
# morbo wp-on-mojo.pl [wp-dir]  or  hypnotoad wp-on-mojo.pl [wp-dir]
package MojoX::WordPress;
use Mojolicious::Lite;

# set this to the home dir of your already-configured WordPress installation
$WordPress::Home = $ARGV[0] || ".../wordpress";

plugin 'MojoX::Plugin::PHP', {
    use_index_php => 1,
    php_var_preprocessor => sub {
	$_[0]->{_SERVER}{BITCHES} = "Yeah, WordPress on Mojolicious, bitches!";
	PHP::call('set_include_path', $WordPress::Home);
    },
    php_stderr_processor => sub { app->log->error("PHP message: $_[0]"); },
    php_output_postprocessor => sub {
	my ($oref, $headers) = @_;
	$headers->header("X-wordpress-on-mojolicious", "That's right bitches");
    },
    php_header_processor => sub {
	$_[1] //= ""; # value
	app->log->debug("Header from WordPress: \t$_[0] => $_[1]");
	return 1;
    }
};

get '/bitches' => sub {
    $_[0]->render( text => "Hey! WordPress on Mojolicious, bitches!\n" );
};

push @{app->static->paths}, $WordPress::Home;

app->log( Mojo::Log->new( path => 'wp-on-mojo.log' ) );
my $secret = 'wordpress on mojolicious, bitches';
$Mojolicious::VERSION > 4.62 ? app->secrets([$secret]):app->secret($secret);
app->start;

=head1 NAME

wp-on-mojo.pl - WordPress on Mojolicious (bitches)

=head1 INSTRUCTIONS

=over 4

=item 0. Install the L<MojoX::Plugin::PHP> module on your system

=item 1. If you already have a working WordPress installation on your
host, skip ahead to step 3. Otherwise download and unpack some version
of WordPress from L<http://wordpress.org/>

=item 2. Configure a C<wp-config.php> file with database settings,
authentication keys, etc.

=item 3. Change the C<$WordPress::Home> variable near the top of
this script (line 8) to the root directory of your WordPress
installation.

=item 4. Launch the Mojolicious web app with

    morbo examples/wp-on-mojo.pl

or

    hypnotoad examples/wp-on-mojo.pl

=item 5. Blog with Mojolicious and WordPress like a boss.

=back

=cut
