#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Test::Exception;
use Test::More 0.98;

subtest normalize_function_metadata => sub {
    dies_ok { normalize_function_metadata({}) }
        "doesn't accept v1.0";
    dies_ok { normalize_function_metadata({v=>1.1, foo=>1}) }
        "doesn't allow unknown properties";
    is_deeply(normalize_function_metadata({v=>1.1, foo=>1}, {allow_unknown_properties=>1}),
              {v=>1.1, foo=>1},
              "unknown properties allowed when using allow_unknown_properties=1");

    is_deeply(normalize_function_metadata({v=>1.1, args=>{}, "summary.alt.lang.id_ID"=>"tes"}),
              {v=>1.1, args=>{}, "summary.alt.lang.id_ID"=>"tes"},
              "properties and attributes not changed");
    is_deeply(normalize_function_metadata({v=>1.1, args=>{a=>{schema=>"int"}, b=>{schema=>["str*"], cmdline_aliases=>{al1=>{schema=>"bool"}}} }, result=>{schema=>"array"}}),
              {v=>1.1, args=>{a=>{schema=>["int",{}]}, b=>{schema=>["str",{req=>1}], cmdline_aliases=>{al1=>{schema=>[bool => {}]}}} }, result=>{schema=>["array",{}]}},
              'sah schemas normalized');
    is_deeply(normalize_function_metadata({v=>1.1, args=>{a=>{schema=>"int"}, b=>{schema=>["str*"]} }, result=>{schema=>"array"}}, {normalize_sah_schemas=>0}),
              {v=>1.1, args=>{a=>{schema=>"int"}, b=>{schema=>["str*"]}}, result=>{schema=>"array"}},
              'sah schemas not normalized when using normalize_sah_schemas=>0');

    is_deeply(normalize_function_metadata({v=>1.1, _a=>1, "a._b"=>2, "_a.b"=>3, "_a._b"=>4}),
              {v=>1.1, _a=>1, "a._b"=>2, "_a.b"=>3, "_a._b"=>4},
              'internal properties and attributes not removed');
    is_deeply(normalize_function_metadata({v=>1.1, _a=>1}, {remove_internal_properties=>1}),
              {v=>1.1},
              'internal properties removed when using remove_internal_properties=1');

    subtest "arg submeta" => sub {
        dies_ok { normalize_function_metadata({v=>1.1, args=>{a=>{meta=>{  }}}}) }
            "doesn't accept v1.0";
        dies_ok { normalize_function_metadata({v=>1.1, args=>{a=>{meta=>{ v=>1.1, foo=>1 }}}}) }
            "doesn't allow unknown properties";
        is_deeply(normalize_function_metadata({v=>1.1, args=>{a=>{meta=>{ v=>1.1, foo=>1 }}}}, {allow_unknown_properties=>1}),
                  {v=>1.1, args=>{a=>{meta=>{ v=>1.1, foo=>1 }}}},
                  "unknown properties allowed when using allow_unknown_properties=1");
        is_deeply(normalize_function_metadata({v=>1.1, args=>{a=>{meta=>
                                                                      {v=>1.1, args=>{a=>{schema=>"int"}, b=>{schema=>["str*"], cmdline_aliases=>{al1=>{schema=>"bool"}}} }, result=>{schema=>"array"}}
                                                                  }}}),
                  {v=>1.1, args=>{a=>{meta=>
                                          {v=>1.1, args=>{a=>{schema=>["int",{}]}, b=>{schema=>["str",{req=>1}], cmdline_aliases=>{al1=>{schema=>[bool => {}]}}} }, result=>{schema=>["array",{}]}},
                                  }}},
                  'sah schemas normalized');
    };

    is_deeply(normalize_function_metadata({v=>1.1, summary=>"foo", "summary(id)" => "fu"}),
              {v=>1.1, summary=>"foo", "summary.alt.lang.id"=>"fu"},
              'normalize prop(LANG) to prop.alt.lang.LANG (DefHash 1.0.10)');
    # regression in 0.10
    dies_ok { normalize_function_metadata({v=>1.1, "summary (id)" => "fu"}) } "property/attribute name still checked after normalization of prop(LANG)";
};

DONE_TESTING:
done_testing();
