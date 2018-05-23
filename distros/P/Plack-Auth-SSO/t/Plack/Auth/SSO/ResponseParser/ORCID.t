use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;
use JSON;

my $pkg;

BEGIN {
    $pkg = "Plack::Auth::SSO::ResponseParser::ORCID";
    use_ok $pkg;
}
require_ok $pkg;

my $json = <<EOF;
{
    "access_token": "89f0181c-168b-4d7d-831c-1fdda2d7bbbb",
    "token_type": "bearer",
    "refresh_token": "69e883f6-d84e-4ae6-87f5-ef0044e3e9a7",
    "expires_in": 631138518,
    "scope": "/authenticate",
    "orcid": "0000-0001-2345-6789",
    "name":"Sofia Garcia"
}
EOF

my $json2 = <<EOF;
{
   "name" : {
      "given-names" : {
         "value" : "Sofia"
      },
      "last-modified-date" : {
         "value" : "1465483061569"
      },
      "created-date" : {
         "value" : "1465483061569"
      },
      "family-name" : {
         "value" : "Garcia"
      },
      "source" : null,
      "visibility" : "PUBLIC",
      "path" : "0000-0001-2345-6789",
      "credit-name" : null
   },
   "addresses" : {
      "address" : [
         {
            "display-index" : 1,
            "path" : "/0000-0001-2345-6789/address/808458",
            "country" : {
               "value" : "BE"
            },
            "visibility" : "PUBLIC",
            "put-code" : 808458,
            "source" : {
               "source-orcid" : {
                  "uri" : "http://orcid.org/0000-0001-2345-6789",
                  "host" : "orcid.org",
                  "path" : "0000-0001-2345-6789"
               },
               "source-client-id" : null,
               "source-name" : {
                  "value" : "Sofia Garcia"
               }
            },
            "created-date" : {
               "value" : "1508420948989"
            },
            "last-modified-date" : {
               "value" : "1508420948989"
            }
         }
      ],
      "path" : "/0000-0001-2345-6789/address",
      "last-modified-date" : {
         "value" : "1508420948989"
      }
   },
   "path" : "/0000-0001-2345-6789/person",
   "emails" : {
      "email" : [
         {
            "verified" : true,
            "path" : null,
            "visibility" : "PUBLIC",
            "put-code" : null,
            "email" : "sofia.garcia\@nowhere.be",
            "source" : {
               "source-name" : {
                  "value" : "Sofia Garcia"
               },
               "source-client-id" : null,
               "source-orcid" : {
                  "uri" : "http://orcid.org/0000-0001-2345-6789",
                  "host" : "orcid.org",
                  "path" : "0000-0001-2345-6789"
               }
            },
            "created-date" : {
               "value" : "1506602103528"
            },
            "primary" : true,
            "last-modified-date" : {
               "value" : "1506602532135"
            }
         }
      ],
      "path" : "/0000-0001-2345-6789/email",
      "last-modified-date" : {
         "value" : "1506602532135"
      }
   },
   "researcher-urls" : {
      "researcher-url" : [
        {
           "display-index" : 1,
           "path" : "/0000-0001-2345-6789/researcher-urls/1419094",
           "source" : {
              "source-orcid" : {
                 "path" : "0000-0001-2345-6789",
                 "host" : "orcid.org",
                 "uri" : "http://orcid.org/0000-0001-2345-6789"
              },
              "source-client-id" : null,
              "source-name" : {
                 "value" : "Sofia Garcia"
              }
           },
           "visibility" : "PUBLIC",
           "last-modified-date" : {
              "value" : 1524746921116
           },
           "url-name" : "mysite",
           "created-date" : {
              "value" : 1524745677739
           },
           "put-code" : 1419094,
           "url" : {
              "value" : "https://mysite.com"
           }
        }
      ],
      "last-modified-date" : null,
      "path" : "/0000-0001-2345-6789/researcher-urls"
   },
   "keywords" : {
      "last-modified-date" : null,
      "keyword" : [],
      "path" : "/0000-0001-2345-6789/keywords"
   },
   "biography" : {
      "path" : "/0000-0001-2345-6789/biography",
       "created-date" : {
          "value" : 1524746816993
       },
       "visibility" : "PUBLIC",
       "content" : "My biography..",
       "last-modified-date" : {
          "value" : 1524746816994
       }
   },
   "other-names" : {
      "path" : "/0000-0001-2345-6789/other-names",
      "other-name" : [
         {
             "source" : {
                "source-orcid" : {
                   "path" : "0000-0001-2345-6789",
                   "uri" : "http://orcid.org/0000-0001-2345-6789",
                   "host" : "orcid.org"
                },
                "source-client-id" : null,
                "source-name" : {
                   "value" : "Sofia Garcia"
                }
             },
             "display-index" : 1,
             "path" : "/0000-0001-2345-6789/other-names/1095164",
             "last-modified-date" : {
                "value" : 1524746892437
             },
             "visibility" : "PUBLIC",
             "content" : "sgarcia",
             "created-date" : {
                "value" : 1524746892437
             },
             "put-code" : 1095164
         }
      ],
      "last-modified-date" : null
   },
   "last-modified-date" : {
      "value" : "1508420948989"
   },
   "external-identifiers" : {
      "last-modified-date" : null,
      "external-identifier" : [],
      "path" : "/0000-0001-2345-6789/external-identifiers"
   }
}
EOF

my $hash = +{
    uid => "0000-0001-2345-6789",
    info => {
        name => "Sofia Garcia",
        first_name => "Sofia",
        last_name => "Garcia",
        email => "sofia.garcia\@nowhere.be",
        location => "BE",
        description => "My biography..",
        other_names => [ "sgarcia" ],
        urls => [ { mysite => "https://mysite.com" } ],
        external_identifiers => []
    },
    extra => {
        access_token => "89f0181c-168b-4d7d-831c-1fdda2d7bbbb",
        token_type => "bearer",
        refresh_token => "69e883f6-d84e-4ae6-87f5-ef0044e3e9a7",
        expires_in => 631138518,
        scope => "/authenticate",
       "name" => {
          "given-names" => {
             "value" => "Sofia"
          },
          "last-modified-date" => {
             "value" => "1465483061569"
          },
          "created-date" => {
             "value" => "1465483061569"
          },
          "family-name" => {
             "value" => "Garcia"
          },
          "source" => undef,
          "visibility" => "PUBLIC",
          "path" => "0000-0001-2345-6789",
          "credit-name" => undef
       },
       "addresses" => {
          "address" => [
             {
                "display-index" => 1,
                "path" => "/0000-0001-2345-6789/address/808458",
                "country" => {
                   "value" => "BE"
                },
                "visibility" => "PUBLIC",
                "put-code" => 808458,
                "source" => {
                   "source-orcid" => {
                      "uri" => "http://orcid.org/0000-0001-2345-6789",
                      "host" => "orcid.org",
                      "path" => "0000-0001-2345-6789"
                   },
                   "source-client-id" => undef,
                   "source-name" => {
                      "value" => "Sofia Garcia"
                   }
                },
                "created-date" => {
                   "value" => "1508420948989"
                },
                "last-modified-date" => {
                   "value" => "1508420948989"
                }
             }
          ],
          "path" => "/0000-0001-2345-6789/address",
          "last-modified-date" => {
             "value" => "1508420948989"
          }
       },
       "path" => "/0000-0001-2345-6789/person",
       "emails" => {
          "email" => [
             {
                "verified" => JSON::true,
                "path" => undef,
                "visibility" => "PUBLIC",
                "put-code" => undef,
                "email" => "sofia.garcia\@nowhere.be",
                "source" => {
                   "source-name" => {
                      "value" => "Sofia Garcia"
                   },
                   "source-client-id" => undef,
                   "source-orcid" => {
                      "uri" => "http://orcid.org/0000-0001-2345-6789",
                      "host" => "orcid.org",
                      "path" => "0000-0001-2345-6789"
                   }
                },
                "created-date" => {
                   "value" => "1506602103528"
                },
                "primary" => JSON::true,
                "last-modified-date" => {
                   "value" => "1506602532135"
                }
             }
          ],
          "path" => "/0000-0001-2345-6789/email",
          "last-modified-date" => {
             "value" => "1506602532135"
          }
       },
       "researcher-urls" => {
          "researcher-url" => [
            {
               "display-index" => 1,
               "path" => "/0000-0001-2345-6789/researcher-urls/1419094",
               "source" => {
                  "source-orcid" => {
                     "path" => "0000-0001-2345-6789",
                     "host" => "orcid.org",
                     "uri" => "http://orcid.org/0000-0001-2345-6789"
                  },
                  "source-client-id" => undef,
                  "source-name" => {
                     "value" => "Sofia Garcia"
                  }
               },
               "visibility" => "PUBLIC",
               "last-modified-date" => {
                  "value" => 1524746921116
               },
               "url-name" => "mysite",
               "created-date" => {
                  "value" => 1524745677739
               },
               "put-code" => 1419094,
               "url" => {
                  "value" => "https://mysite.com"
               }
            }
          ],
          "last-modified-date" => undef,
          "path" => "/0000-0001-2345-6789/researcher-urls"
       },
       "keywords" => {
          "last-modified-date" => undef,
          "keyword" => [],
          "path" => "/0000-0001-2345-6789/keywords"
       },
       "biography" => {
          "path" => "/0000-0001-2345-6789/biography",
           "created-date" => {
              "value" => 1524746816993
           },
           "visibility" => "PUBLIC",
           "content" => "My biography..",
           "last-modified-date" => {
              "value" => 1524746816994
           }
       },
       "other-names" => {
          "path" => "/0000-0001-2345-6789/other-names",
          "other-name" => [
             {
                 "source" => {
                    "source-orcid" => {
                       "path" => "0000-0001-2345-6789",
                       "uri" => "http://orcid.org/0000-0001-2345-6789",
                       "host" => "orcid.org"
                    },
                    "source-client-id" => undef,
                    "source-name" => {
                       "value" => "Sofia Garcia"
                    }
                 },
                 "display-index" => 1,
                 "path" => "/0000-0001-2345-6789/other-names/1095164",
                 "last-modified-date" => {
                    "value" => 1524746892437
                 },
                 "visibility" => "PUBLIC",
                 "content" => "sgarcia",
                 "created-date" => {
                    "value" => 1524746892437
                 },
                 "put-code" => 1095164
             }
          ],
          "last-modified-date" => undef
       },
       "last-modified-date" => {
          "value" => "1508420948989"
       },
       "external-identifiers" => {
          "last-modified-date" => undef,
          "external-identifier" => [],
          "path" => "/0000-0001-2345-6789/external-identifiers"
       }

    }
};

is_deeply(
    $pkg->new()->parse( $json, $json2 ),
    $hash,
    "cas:serviceResponse"
);

done_testing;
