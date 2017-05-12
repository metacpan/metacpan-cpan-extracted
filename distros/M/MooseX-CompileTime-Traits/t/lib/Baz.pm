use MooseX::Declare;
role Baz(Int :$baz) { method baz { $baz + 3 } }
1;
