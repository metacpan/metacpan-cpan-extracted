#!perl
use strict;
use warnings;
use TAEB::Test tests => 1374;

degrade_ok  "Elbereth" => "Elbereth";
degrade_ok  "Elbereth" => "Flbereth";
degrade_nok "Flbereth" => "Elbereth";
degrade_ok  "Elbereth" => "";
degrade_ok  "Elbereth" => "????????";
degrade_ok  "Elbereth" => "       ?";
degrade_nok "Elbereth" => "        ?";

degrade_progression(
    "Elbereth" =>
    "Elbcret?" =>
    "E|b?re ?" =>
    "F| ???"   =>
    "F  ???"   =>
    "F    ?"   =>
    "F"        =>
    "-"        =>
    ""
);

degrade_progression(
    "Elbereth" =>
    "Elbe?eth" =>
    "El e?et?" =>
    "El e e??" =>
    "El c e?"  =>
    "El c e"   =>
    "E  c ?"   =>
    "E  c"     =>
    "E  ?"     =>
    "E"        =>
    ""
);

degrade_progression(
    "               x" =>
                   "x" =>
                   ""
);

degrade_progression(
    "E0E0E0E0E0E0E0E0E0ECE0" =>
    "E0E0E0E([0E0E0E0E?ECE0" =>
    "E0E0E0E([0E0E0E0E?EC?0" =>
    "E0E0?0E([0E0E?E0E?E(?0" =>
    "E0E? 0E([0E0E?E0E?E(?0" =>
    "E0L? 0E([0E0E?E0E?E(?0" =>
    "F?L? 0E([0E?E?E(E?E(?0" =>
    "F?L? (E([0E?E?E(E?E(?0" =>
    "F?L? (F([0??E?E?E?E? 0" =>
    "F?L? (F([0? E?E?E?E? 0" =>
    "F L? ?F([(? E?E?E?E? 0" =>
    "F L? ?|([(? E?L?E?E  0" =>
    "F L  ?|([(? E?L?E?E  0" =>
    "- L  ?|([(? E?L?E?E  0" =>
    "- L  ?|([(? E???E?E  0" =>
    "- L  ?|([?? E???E?E  0" =>
    "- L   |([?? E???E?F  0" =>
    "- L   |(??? E???|?F  0" =>
    "- L   |(??? E ??|?|  0" =>
    "- L   |( ?? E ??| |  0" =>
    "- |   |( ?? E ? | |  0" =>
      "|   |(  ? E ? | |  0" =>
      "|   |(  ? E   | |  0" =>
      "|   |?    E   | |  0" =>
      "|   |?    L   | |  0" =>
      "|   |?    L     |  0" =>
      "|   |?    L        0" =>
          "|?    L        0" =>
           "?    L        0" =>
           "?    L        C" =>
                "L        C" =>
                "L        ?" =>
                "L"          =>
                ""
);

