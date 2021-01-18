package Rewire::Ruleset;

{
  "\$id" => "https://raw.githubusercontent.com/cpanery/rewire/master/ruleset.yaml",
  "\$schema" => "https://json-schema.org/draft/2019-09/schema",
  definitions => {
    Argument => {
      anyOf => [
        {
          "\$ref" => "#/definitions/ArgumentNumber",
        },
        {
          "\$ref" => "#/definitions/ArgumentString",
        },
        {
          "\$ref" => "#/definitions/ArgumentObject",
        },
        {
          "\$ref" => "#/definitions/ArgumentArray",
        },
        {
          "\$ref" => "#/definitions/ArgumentBoolean",
        },
        {
          "\$ref" => "#/definitions/ArgumentNull",
        },
      ],
    },
    ArgumentArray => {
      items => {
        "\$ref" => "#/definitions/Argument",
      },
      minItems => 1,
      type => "array",
    },
    ArgumentAs => {
      enum => [
        "array",
        "hashmap",
        "list",
      ],
    },
    ArgumentBoolean => {
      type => "boolean",
    },
    ArgumentNull => {
      type => undef,
    },
    ArgumentNumber => {
      minLength => 1,
      type => "number",
    },
    ArgumentObject => {
      additionalProperties => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
      minProperties => 1,
      patternProperties => {
        "^\\\$[A-Za-z_][A-Za-z0-9_]*\$" => {
          "\$ref" => "#/definitions/Argument",
        },
      },
      type => "object",
    },
    ArgumentString => {
      minLength => 1,
      type => "string",
    },
    Service => {
      additionalProperties => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
      minProperties => 1,
      not => {
        anyOf => [
          {
            required => [
              "function",
              "method",
            ],
          },
          {
            required => [
              "function",
              "routine",
            ],
          },
          {
            required => [
              "method",
              "routine",
            ],
          },
        ],
      },
      properties => {
        argument => {
          "\$ref" => "#/definitions/Argument",
        },
        argument_as => {
          "\$ref" => "#/definitions/ArgumentAs",
        },
        builder => {
          items => {
            additionalProperties => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
            anyOf => [
              {
                required => [
                  "function",
                ],
              },
              {
                required => [
                  "method",
                ],
              },
              {
                required => [
                  "routine",
                ],
              },
            ],
            minProperties => 1,
            properties => {
              argument => {
                "\$ref" => "#/definitions/Argument",
              },
              argument_as => {
                "\$ref" => "#/definitions/ArgumentAs",
              },
              function => {
                type => "string",
              },
              method => {
                type => "string",
              },
              return => {
                enum => [
                  "class",
                  "none",
                  "result",
                  "self",
                ],
              },
              routine => {
                type => "string",
              },
            },
            required => [
              "return",
            ],
            type => "object",
          },
          minItems => 1,
          type => "array",
        },
        constructor => {
          type => "string",
        },
        extends => {
          type => "string",
        },
        function => {
          type => "string",
        },
        lifecycle => {
          enum => [
            "eager",
            "factory",
            "singleton",
          ],
        },
        method => {
          type => "string",
        },
        package => {
          type => "string",
        },
        routine => {
          type => "string",
        },
      },
      required => [
        "package",
      ],
      type => "object",
    },
  },
  properties => {
    metadata => {
      patternProperties => {
        "^[A-Za-z_][A-Za-z0-9_]*\$" => {
          "\$ref" => "#/definitions/Argument",
        },
      },
      type => "object",
    },
    services => {
      patternProperties => {
        "^[A-Za-z_][A-Za-z0-9_]*\$" => {
          "\$ref" => "#/definitions/Service",
        },
      },
      type => "object",
    },
  },
  required => [
    "services",
  ],
  type => "object",
}
