package Mojolicious::Plugin::Mysql;
use Mojo::Base 'Mojolicious::Plugin';
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Mysql;

sub register {
	my ($self, $app, $config) = @_;

	$config->{'app'} = $app;
	my $mysql = MojoX::Mysql->new(%{$config});

	# MojoX
	$app->helper(mysql=>sub {
		my ($self) = @_;
		return $mysql;
	});

	# Hook Commit
	$app->hook(after_dispatch => sub {
		my $self = shift;
		my $exception = $self->stash('exception');
		if(defined $exception){
			$self->mysql->db->rollback();
		}
		else{
			$self->mysql->db->commit();
			$self->mysql->db->disconnect();
		}
	});
	return $mysql;
}

1;

=encoding utf8

=head1 SYNOPSIS

    my %config = (
	    user=>'root',
	    password=>undef,
	    server=>[
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	    ]
    );

    # Mojolicious
    $self->plugin('Mysql'=>\%config);

    # Mojolicious::Lite
    plugin 'Mysql' => \%config;

=head1 HELPERS

=head2 mysql

    $app->mysql;

Return L<MojoX::Mysql> object.

=cut

