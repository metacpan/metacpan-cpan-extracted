package Mojolicious::Plugin::Tree;
use Mojo::Base 'Mojolicious::Plugin';
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Tree;
use Mojo::Util qw(dumper);

sub register {
	my ($self, $app, $config) = @_;

	if($config->{'namespace'}){
		$config->{'namespace'} = 'tree.'.$config->{'namespace'};
	}
	else{
		$config->{'namespace'} = 'tree';
	}

	$config->{'mysql'} = $app->mysql;
	my $tree = MojoX::Tree->new(%{$config});

	# MojoX
	$app->helper($config->{'namespace'}=>sub {
		my ($self) = @_;
		return $tree;
	});

}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Tree - Mojolicious Plugin Tree

=head1 SYNOPSIS

    my %config = (
	    user=>'root',
	    password=>undef,
	    server=>[
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
	    ]
    );

    # Mojolicious
    $self->plugin('Mysql'=>\%config);
    $self->plugin('Tree'=>{namespace=>'obj', table=>'tree', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}});

    # Mojolicious::Lite
    plugin 'Mysql' => \%config;
    plugin 'Tree'=>{namespace=>'obj', table=>'tree', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}};

=head1 EXAMPLE

    use Mojo::Util qw(dumper);

    my %config = (
	    user=>'root',
	    password=>undef,
	    server=>[
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		    {dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
	    ]
    );

    # Mojolicious
    $self->plugin('Mysql'=>\%config);
    $self->plugin('Tree'=>{namespace=>'obj1', table=>'tree1', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}});
    $self->plugin('Tree'=>{namespace=>'obj2', table=>'tree2', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}});

    say dumper $self->tree->obj1; # return MojoX::Tree table tree1
    say dumper $self->tree->obj2; # return MojoX::Tree table tree2

=head1 HELPERS

=head2 tree

    $app->tree->obj;

Return L<MojoX::Tree> object.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
