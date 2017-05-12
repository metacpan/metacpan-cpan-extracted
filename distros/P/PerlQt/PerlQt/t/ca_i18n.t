BEGIN { print "1..1\n" }

use Qt;

$a = Qt::Application();
$pb=Qt::PushButton("Foooo", undef);

{
  use bytes;
  $pb->setText( "élégant" );

  $b = $pb->text();
  $b2 = Qt::Widget::tr("élégant");
}


$c = $pb->text();
$c2= Qt::Widget::tr("élégant");

{
  use bytes;
  print +($b ne $c and $b2 ne $c2) ? "ok 1\n":"not ok\n";
}
