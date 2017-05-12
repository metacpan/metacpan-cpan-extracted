use Test;

BEGIN { plan tests => 5 }

# first try to load it up and get pquota object

eval
{
  use Pquota;
  $pquota = Pquota->new ("test");
};

if ($@)
{
  ok(0);ok(0);ok(0);ok(0);ok(0);
}
else
{
  ok(1);
}

# now add a printer
if ($pquota->printer_add ("scud", 5, "daboys")) {
  # add another one to be removed
  $pquota->printer_add ("dummy", 10, "dummy");
  
  # now okay the test
  ok(1);
}
else {
  ok(0);
}

# remove the dummy printer
if ($pquota->printer_rm ("dummy")) {
  ok(1);
}
else {
  ok(0);
}

# add a user
if ($pquota->user_add ("drywall", "daboys", 450)) {
  ok(1);
}
else {
  ok(0);
}

# now get rid of him
if ($pquota->user_rm ("drywall", "daboys")) {
  ok(1);
}
else {
  ok(0);
}

exit (0);

