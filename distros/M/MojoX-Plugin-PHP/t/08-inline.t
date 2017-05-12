package t08;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use strict;
use warnings;

plugin 'MojoX::Plugin::PHP' => {
    php_var_preprocessor => sub {
	my $params = shift;
	$params->{time} = "13 o'clock";
    }
};

my $tm = Test::Mojo->new('t08');
$tm->get_ok('/inline-template.php')
    ->status_is(200)
    ->content_is( "The time is 13 o'clock\n" );

$tm->get_ok('/inline-template2.php')
    ->status_is(200)
    ->content_like( qr/13 o'clock/ )
    ->content_like( qr/time to get a new clock/ );

done_testing();

__DATA__
@@ inline-template.php.html.php
<?php
    echo "The time is $time\n";
?>
@@ inline-template2.php.html.php
When the clock says <?php echo $time; ?>,
it's time to get a new clock.
