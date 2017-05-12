use Test::More;
use Test::Mojo;
use strict;
use warnings;
use Data::Dumper;

sub array {
    return { @_ };
}

{

    my $z1 = sprintf "VAR%08x", rand(0x7FFFFFFF);
    my $z2 = sprintf "VAL%08x", rand(0x7FFFFFFF);
    $ENV{$z1} = $z2;

    my $t = Test::Mojo->new( 't::MojoTestServer' );
    $t->get_ok('/vars.php')->status_is(200);
    my $content = $t->tx->res->body;

    my ($env) = $content =~ /\$_ENV = array *\((.*)\)\s*\$_COOKIE/s;
    my @env = split /\n/, $env;

    my $key_count = 0;
    my @fail = ();
    while (my ($k,$v) = each %ENV) {
	$key_count++;
	$v //= "";
	next if $v =~ /\n/;
	ok( grep(/\Q$k\E.*=>.*\Q$v\E/,@env), "ENV $k ok" )
	    or push @fail, [$k, $v];
    }
    if (@fail) {
	diag "extracted \$_ENV is $env",
	     "Failed matches are:", Dumper(\@fail);
    }
    ok( $key_count > 2, "at least some env vars found ($key_count)" );
}

done_testing();
