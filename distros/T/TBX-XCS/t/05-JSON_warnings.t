#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::Base;
plan tests => 1*blocks();
use Test::Exception;
use TBX::XCS::JSON qw(xcs_from_json);
use JSON;

for my $block(blocks()){
  my $croak = $block->croak;
  throws_ok {xcs_from_json($block->json)}
  qr/$croak/,
  $block->name;
}
# {
#    "constraints" : {
#       "languages" : {
#          "en" : "English",
#          "fr" : "French",
#          "de" : "German"
#       },
#       "datCatSet" : {
#          "xref" : [
#             {
#                "name" : "xrefFoo",
#                "targetType" : "external",
#                "datatype" : "plainText"
#             }
#          ]
#       }
#    }
# }

__DATA__
=== no constraints
--- croak: no constraints key specified
--- json
{
  "name" : "foo",
  "title" : "bar"
}

=== bad name structure
--- croak: name value should be a plain string
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   },
   "name": []
}

=== bad title structure
--- croak: title value should be a plain string
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   },
   "title": []
}

=== bad language structure
--- croak: "languages" value should be a hash of language abbreviations and names
--- json
{
   "constraints" : {
      "languages" : [
        "English", "German"
      ],
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== missing languages
--- croak: no "languages" key in constraints value
--- json
{
   "constraints" : {
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== bad refObjects structure
--- croak: refObjects should be a hash
--- json
{
   "constraints" : {
      "refObjects" : [],
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== refObject not an array
--- croak: Reference object foo is not an array
--- json
{
   "constraints" : {
      "refObjects" : {
        "foo" : {}
      },
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== refObject array element not a scalar
--- croak: Reference object foo should refer to an array of strings
--- json
{
   "constraints" : {
      "refObjects" : {
        "foo" : [
          "data", {}
        ]
      },
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== missing data category set
--- croak: "constraints" is missing key "datCatSet"
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "d-cat-set" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== empty data cat set
--- croak: datCatSet should not be empty
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {}
   }
}

=== bad data category structure
--- croak: meta data category 'xref' should be an array
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : {}
      }
   }
}

=== bad meta data category name
--- croak: unknown meta data category: foo
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "foo" : [
            {

            }
         ]
      }
   }
}

=== bad data category structure
--- croak: data category for xref should be a hash
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            []
         ]
      }
   }
}

=== missing data category name
--- croak: missing name in data category of xref
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== termCompList with a datatype
--- croak: termCompList cannot contain datatype
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "termCompList" : [
            {
               "name" : "syllables",
               "targetType" : "external",
               "datatype" : "plainText"
            }
         ]
      }
   }
}

=== bad datatype
--- croak: Can't set datatype of xref to noteText. Must be picklist or plainText.
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "syllables",
               "targetType" : "external",
               "datatype" : "noteText"
            }
         ]
      }
   }
}

=== missing choices
--- croak: need choices for picklist in foo
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "foo",
               "targetType" : "external",
               "datatype" : "picklist"
            }
         ]
      }
   }
}

=== bad choices datatype
--- croak: foo choices should be an array
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "foo",
               "targetType" : "external",
               "datatype" : "picklist",
               "choices" : {}
            }
         ]
      }
   }
}

=== choice isn't a string
--- croak: foo choices array elements should be strings
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "foo",
               "targetType" : "external",
               "datatype" : "picklist",
               "choices" : [{}]
            }
         ]
      }
   }
}

=== missing levels
--- croak: missing levels for foo
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "descrip" : [
            {
               "name" : "foo",
               "targetType" : "external"
            }
         ]
      }
   }
}

=== bad levels
--- croak: Bad levels.*foo.*may only include term, termEntry, and langSet
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "descrip" : [
            {
               "name" : "foo",
               "targetType" : "external",
               "levels" : ["bar"]
            }
         ]
      }
   }
}

=== bad level element structure
--- croak: levels in foo should be single values
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "descrip" : [
            {
               "name" : "foo",
               "targetType" : "external",
               "levels" : [{}]
            }
         ]
      }
   }
}

=== bad targettype structure
--- croak: targetType of foo should be a string
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "foo",
               "targetType" : {}
            }
         ]
      }
   }
}

=== non-scalar forTermComp
--- croak: forTermComp isn't a single value in foo
--- json
{
   "constraints" : {
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "termNote" : [
            {
               "name" : "foo",
               "forTermComp" : {}
            }
         ]
      }
   }
}
