#! perl -w

use PANT;

StartPant("Test", style=>"td#fail { background:red } \ntd#pass { background:green }" );

RunTests(tests=>["t/fake/fake.t"]);
RunTests(tests=>["t/fake/fake.t", "t/fake/fake2.t"]);

EndPant();
