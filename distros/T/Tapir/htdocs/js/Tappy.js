require(["dojo/_base/array"], function (array) {

var fieldHeader = ['index', 'name', 'optional', 'type', 'validateSpec'];

// Custom types

function _table2objects (data, columns) {
    if (columns === undefined) {
        columns = data.shift();
    }
    var objects = [], i, j, obj;
    for (i = 0; i < data.length; i++) {
        obj = {};
        for (j = 0; j < columns.length; j++) {
            obj[ columns[j] ] = data[i][j];
        }
        objects.push(obj);
    }
    return objects;
}


array.forEach(
    _table2objects([
   [
      "name",
      "type",
      "validateSpec"
   ],
   [
      "coupon_code",
      "string",
      [
         {
            "pattern" : "^[0-9A-Z]{0,}$",
            "type" : "regex"
         }
      ]
   ],
   [
      "coupon_group_id",
      "i64",
      []
   ],
   [
      "coupon_id",
      "i64",
      []
   ],
   [
      "coupon_prefix",
      "string",
      [
         {
            "pattern" : "^[A-Z][A-Z0-9]{0,4}$",
            "type" : "regex"
         }
      ]
   ],
   [
      "coupon_site",
      "string",
      []
   ],
   [
      "coupon_triggers",
      {
         "keyType" : "SSThrift.trigger_key",
         "valType" : "SSThrift.trigger_value",
         "type" : "map"
      },
      []
   ],
   [
      "date",
      "string",
      [
         {
            "pattern" : "^\\d{4}-\\d{2}-\\d{2}$",
            "type" : "regex"
         }
      ]
   ],
   [
      "trigger_key",
      "string",
      []
   ],
   [
      "trigger_value",
      {
         "valType" : "string",
         "type" : "list"
      },
      []
   ],
   [
      "unix_time",
      "i32",
      [
         {
            "high" : null,
            "low" : "0",
            "type" : "range"
         }
      ]
   ]
]
),
    function (type, i) {
        dojo.declare('SSThrift.' + type.name, Tapir.Type.Custom, type);
    }
);

// Custom Enum


// Custom exceptions and structures

dojo.declare('SSThrift.coupon', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "id",
      false,
      "SSThrift.coupon_id",
      []
   ],
   [
      "2",
      "site",
      false,
      "SSThrift.coupon_site",
      []
   ],
   [
      "3",
      "code",
      false,
      "SSThrift.coupon_code",
      []
   ],
   [
      "4",
      "description",
      false,
      "string",
      []
   ],
   [
      "5",
      "amount",
      false,
      "SSThrift.coupon_amount",
      []
   ],
   [
      "6",
      "expires",
      false,
      "SSThrift.date",
      []
   ],
   [
      "7",
      "use_once",
      false,
      "bool",
      []
   ],
   [
      "8",
      "triggers",
      false,
      "SSThrift.coupon_triggers",
      []
   ],
   [
      "9",
      "creator",
      false,
      "string",
      []
   ],
   [
      "10",
      "created_epoch",
      false,
      "SSThrift.unix_time",
      []
   ],
   [
      "11",
      "is_valid",
      false,
      "bool",
      []
   ],
   [
      "12",
      "used_epoch",
      true,
      "SSThrift.unix_time",
      []
   ]
]
)
});
dojo.declare('SSThrift.coupon_amount', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "percent",
      true,
      "byte",
      []
   ],
   [
      "2",
      "amount",
      true,
      "double",
      []
   ],
   [
      "4",
      "currency",
      true,
      "string",
      []
   ],
   [
      "3",
      "gift",
      true,
      "string",
      []
   ]
]
)
});
dojo.declare('SSThrift.coupon_group', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "site",
      false,
      "SSThrift.coupon_site",
      []
   ],
   [
      "2",
      "id",
      false,
      "SSThrift.coupon_group_id",
      []
   ],
   [
      "3",
      "code_prefix",
      true,
      "SSThrift.coupon_prefix",
      []
   ],
   [
      "4",
      "code",
      true,
      "SSThrift.coupon_code",
      []
   ],
   [
      "5",
      "description",
      false,
      "string",
      []
   ],
   [
      "6",
      "count",
      false,
      "i32",
      []
   ],
   [
      "7",
      "amount",
      false,
      "SSThrift.coupon_amount",
      []
   ],
   [
      "8",
      "expires",
      false,
      "SSThrift.date",
      []
   ],
   [
      "9",
      "triggers",
      false,
      "SSThrift.coupon_triggers",
      []
   ],
   [
      "10",
      "use_once",
      false,
      "bool",
      []
   ],
   [
      "11",
      "number_of_used",
      true,
      "i32",
      []
   ]
]
)
});
dojo.declare('SSThrift.coupon_groups_result', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "pagination",
      false,
      "SSThrift.pagination_result",
      []
   ],
   [
      "2",
      "groups",
      false,
      {
         "valType" : "SSThrift.coupon_group",
         "type" : "list"
      },
      []
   ]
]
)
});
dojo.declare('SSThrift.generic_result', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "is_success",
      false,
      "bool",
      []
   ],
   [
      "2",
      "message",
      true,
      "string",
      []
   ]
]
)
});
dojo.declare('SSThrift.get_coupons_result', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "pagination",
      false,
      "SSThrift.pagination_result",
      []
   ],
   [
      "2",
      "coupons",
      false,
      {
         "valType" : "SSThrift.coupon",
         "type" : "list"
      },
      []
   ]
]
)
});
dojo.declare('SSThrift.pagination_request', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "records_per_page",
      false,
      "i32",
      []
   ],
   [
      "2",
      "page",
      false,
      "i32",
      []
   ]
]
)
});
dojo.declare('SSThrift.pagination_result', Tapir.Type.Struct, {
    fieldSpec: _table2objects([
   [
      "index",
      "name",
      "optional",
      "type",
      "validateSpec"
   ],
   [
      "1",
      "records",
      false,
      "i32",
      []
   ],
   [
      "2",
      "total_records",
      false,
      "i32",
      []
   ],
   [
      "3",
      "page",
      false,
      "i32",
      []
   ],
   [
      "4",
      "total_pages",
      false,
      "i32",
      []
   ],
   [
      "5",
      "records_per_page",
      false,
      "i32",
      []
   ]
]
)
});

// Services

dojo.declare('SSThrift.Commerce', Tapir.Service, {
    name: 'Commerce',
    methods: [ "create_coupon", "get_coupons", "get_coupon_groups", "get_coupon_by_code", "get_coupon_by_id", "update_coupon" ],
    baseName: 'SSThrift.Commerce'
});

TapirClient.services.push('SSThrift.Commerce');

array.forEach(
    _table2objects([
   [
      "name",
      "serviceName",
      "fieldSpec",
      "spec"
   ],
   [
      "create_coupon",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "code",
            true,
            "SSThrift.coupon_code",
            []
         ],
         [
            "3",
            "code_prefix",
            true,
            "SSThrift.coupon_prefix",
            []
         ],
         [
            "4",
            "description",
            false,
            "string",
            []
         ],
         [
            "6",
            "count",
            false,
            "i32",
            [
               {
                  "high" : null,
                  "low" : "1",
                  "type" : "range"
               }
            ]
         ],
         [
            "7",
            "amount",
            false,
            "SSThrift.coupon_amount",
            []
         ],
         [
            "8",
            "expires",
            false,
            "SSThrift.date",
            []
         ],
         [
            "9",
            "use_once",
            false,
            "bool",
            []
         ],
         [
            "10",
            "triggers",
            false,
            "SSThrift.coupon_triggers",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.coupon_group_id"
      }
   ],
   [
      "get_coupons",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "id",
            false,
            "SSThrift.coupon_group_id",
            []
         ],
         [
            "3",
            "pagination",
            true,
            "SSThrift.pagination_request",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.get_coupons_result"
      }
   ],
   [
      "get_coupon_groups",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "pagination",
            true,
            "SSThrift.pagination_request",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.coupon_groups_result"
      }
   ],
   [
      "get_coupon_by_code",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "code",
            false,
            "SSThrift.coupon_code",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.coupon"
      }
   ],
   [
      "get_coupon_by_id",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "id",
            false,
            "SSThrift.coupon_id",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.coupon"
      }
   ],
   [
      "update_coupon",
      "Commerce",
      [
         [
            "1",
            "site",
            false,
            "SSThrift.coupon_site",
            []
         ],
         [
            "2",
            "code",
            false,
            "SSThrift.coupon_code",
            []
         ],
         [
            "3",
            "is_used",
            false,
            "bool",
            []
         ]
      ],
      {
         "exceptions" : [],
         "returns" : "SSThrift.generic_result"
      }
   ]
]
),

    function (method, i) {
        method.fieldSpec       = _table2objects(method.fieldSpec, fieldHeader);
        method.spec.exceptions = _table2objects(method.spec.exceptions, fieldHeader);
        dojo.declare('SSThrift.' + method.serviceName + '.' + method.name, Tapir.Method, method);
    }
);

});



