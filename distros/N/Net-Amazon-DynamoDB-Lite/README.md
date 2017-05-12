# NAME

Net::Amazon::DynamoDB::Lite - DynamoDB Client

# SYNOPSIS

    use Net::Amazon::DynamoDB::Lite;

    my $dynamo = Amazon::DynamoDB::Lite->new(
        region => 'ap-northeast-1',
        access_key => 'XXXXX',
        secret_key => 'YYYYY',
    );
    my $tables = $dynamo->list_tables;

# DESCRIPTION

Net::Amazon::DynamoDB::Lite is simple DynamoDB Client.
It is really simple, fast, easy to use of the DynamoDB service.

THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.

# METHODS

## list\_tables

Returns an arrayref of table names associated with the current account and endpoint.

- Request Data

        {
            "ExclusiveStartTableName" => "string",
            "Limit" => "number"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_ListTables.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_ListTables.html)

## put\_item

Creates a new item, or replaces an old item with a new item.

- Request Data

        {
            "ConditionExpression" => "string",
            "ConditionalOperator" => "string",
            "Expected" => {
                "string" => {
                    "AttributeValueList": [
                    {
                        "B" => "blob",
                        "BOOL" => "boolean",
                        "BS" => [
                            "blob"
                        ],
                        "L" => [
                            AttributeValue
                        ],
                        "M" => {
                            "string" => AttributeValue
                        },
                        "N" => "string",
                        "NS" => [
                            "string"
                        ],
                        "NULL" => "boolean",
                        "S" => "string",
                        "SS" => [
                            "string"
                        ]
                    }
                ],
                    "ComparisonOperator" => "string",
                    "Exists" => "boolean",
                    "Value" => {
                        "B" => "blob",
                        "BOOL" => "boolean",
                        "BS" => [
                            "blob"
                        ],
                        "L" => [
                            AttributeValue
                        ],
                        "M" => {
                            "string" => AttributeValue
                        },
                        "N" => "string",
                        "NS" => [
                            "string"
                        ],
                        "NULL" => "boolean",
                        "S" => "string",
                        "SS" => [
                            "string"
                        ]
                    }
                }
            },
            "ExpressionAttributeNames" => {
                "string" => "string"
            },
            "ExpressionAttributeValues" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "Item" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "ReturnConsumedCapacity" => "string",
            "ReturnItemCollectionMetrics" => "string",
            "ReturnValues" => "string",
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_PutItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_PutItem.html)

## get\_item

Returns a set of attributes for the item with the given primary key.

- Request Data

        {
            "AttributesToGet" => [
                "string"
            ],
            "ConsistentRead" => "boolean",
            "ExpressionAttributeNames" => {
                "string" => "string"
            },
            "Key" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "ProjectionExpression" => "string",
            "ReturnConsumedCapacity" => "string",
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_GetItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_GetItem.html)

## update\_item

Edits an existing items attributes, or adds a new item to the table if it does not already exist.

- Request Data

        {
            "AttributeUpdates" => {
                "string" => {
                    "Action" => "string",
                    "Value" => {
                        "B" => "blob",
                        "BOOL" => "boolean",
                        "BS" => [
                            "blob"
                        ],
                        "L" => [
                            AttributeValue
                        ],
                        "M" => {
                            "string" => AttributeValue
                        },
                        "N" => "string",
                        "NS" => [
                            "string"
                        ],
                        "NULL" => "boolean",
                        "S" => "string",
                        "SS" => [
                            "string"
                        ]
                    }
                }
            },
            "ConditionExpression" => "string",
            "ConditionalOperator" => "string",
            "Expected" => {
                "string" => {
                    "AttributeValueList" => [
                        {
                            "B" => "blob",
                            "BOOL" => "boolean",
                            "BS" => [
                                "blob"
                            ],
                            "L" => [
                                AttributeValue
                            ],
                            "M" => {
                                "string" => AttributeValue
                            },
                            "N" => "string",
                            "NS" => [
                                "string"
                            ],
                            "NULL" => "boolean",
                            "S" => "string",
                            "SS" => [
                                "string"
                            ]
                        }
                    ],
                    "ComparisonOperator" => "string",
                    "Exists" => "boolean",
                    "Value" => {
                        "B" => "blob",
                        "BOOL" => "boolean",
                        "BS" => [
                            "blob"
                        ],
                        "L" => [
                            AttributeValue
                        ],
                        "M" => {
                            "string" => AttributeValue
                        },
                        "N" => "string",
                        "NS" => [
                            "string"
                        ],
                        "NULL" => "boolean",
                        "S" => "string",
                        "SS" => [
                            "string"
                        ]
                    }
                }
            },
            "ExpressionAttributeNames" => {
                "string" => "string"
            },
            "ExpressionAttributeValues" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "Key" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "ReturnConsumedCapacity" => "string",
            "ReturnItemCollectionMetrics" => "string",
            "ReturnValues" => "string",
            "TableName" => "string",
            "UpdateExpression" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_UpdateItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_UpdateItem.html)

## delete\_item

Deletes a single item in a table by primary key.

- Request Data

        {
            "ConditionExpression" => "string",
            "ConditionalOperator" => "string",
            "Expected" => {
                "string" => {
                    "AttributeValueList" => [
                        {
                            "B" => "blob",
                            "BOOL" => "boolean",
                            "BS" => [
                                "blob"
                            ],
                            "L" => [
                                AttributeValue
                            ],
                            "M" => {
                                "string" => AttributeValue
                            },
                            "N" => "string",
                            "NS" => [
                                "string"
                            ],
                            "NULL" => "boolean",
                            "S" => "string",
                            "SS" => [
                                "string"
                            ]
                        }
                    ],
                    "ComparisonOperator" => "string",
                    "Exists" => "boolean",
                    "Value" => {
                        "B" => "blob",
                        "BOOL" => "boolean",
                        "BS" => [
                            "blob"
                        ],
                        "L" => [
                            AttributeValue
                        ],
                        "M" => {
                            "string" => AttributeValue
                        },
                        "N" => "string",
                        "NS" => [
                            "string"
                        ],
                        "NULL" => "boolean",
                        "S" => "string",
                        "SS" => [
                            "string"
                        ]
                    }
                }
            },
            "ExpressionAttributeNames" => {
                "string" => "string"
            },
            "ExpressionAttributeValues" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "Key" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" =>  AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "ReturnConsumedCapacity" => "string",
            "ReturnItemCollectionMetrics" => "string",
            "ReturnValues" => "string",
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_DeleteItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_DeleteItem.html)

## create\_table

Adds a new table to your account.

- Request Data

        {
            "AttributeDefinitions" => [
                {
                    "AttributeName" => "string",
                    "AttributeType" => "string",
                }
            ],
            "GlobalSecondaryIndexes" => [
                {
                    "IndexName" => "string",
                    "KeySchema" => [
                        {
                            "AttributeName" => "string",
                            "KeyType" => "string"
                        }
                    ],
                    "Projection" => {
                        "NonKeyAttributes" => [
                            "string"
                        ],
                        "ProjectionType" => "string"
                    },
                    "ProvisionedThroughput" => {
                        "ReadCapacityUnits" => "number",
                        "WriteCapacityUnits" => "number"
                    }
                }
            ],
            "KeySchema" => [
                {
                    "AttributeName" => "string",
                    "KeyType" => "string"
                }
            ],
            "LocalSecondaryIndexes" => [
                {
                    "IndexName" => "string",
                    "KeySchema" => [
                        {
                            "AttributeName" => "string",
                            "KeyType" => "string"
                        }
                    ],
                    "Projection" => {
                         "NonKeyAttributes" => [
                             "string"
                         ],
                         "ProjectionType" => "string"
                     }
                }
            ],
            "ProvisionedThroughput" => {
                "ReadCapacityUnits" => "number",
                "WriteCapacityUnits" => "number"
            },
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_CreateTable.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_CreateTable.html)

## delete\_table

Deletes a table and all of its items.

- Request Data

        {
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_DeleteTable.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_DeleteTable.html)

## describe\_table

Returns a information abount the table, including the current status of the table.

- Request Data

        {
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_DescribeTable.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_DescribeTable.html)

## update\_table

Updates the provisioned throughput for the given table, or manages the global secondary indexes on the table.

- Request Data

        {
            "AttributeDefinitions" => [
                {
                    "AttributeName" => "string",
                    "AttributeType" => "string"
                }
            ],
            "GlobalSecondaryIndexUpdates" => [
                {
                    "Create" => {
                        "IndexName" => "string",
                        "KeySchema" => [
                            {
                                "AttributeName" => "string",
                                "KeyType" => "string"
                            }
                        ],
                        "Projection" => {
                            "NonKeyAttributes" => [
                                "string"
                            ],
                            "ProjectionType" =>  "string"
                         },
                        "ProvisionedThroughput" => {
                            "ReadCapacityUnits" => "number",
                            "WriteCapacityUnits" => "number"
                        }
                    },
                    "Delete" => {
                        "IndexName" => "string"
                    },
                    "Update" => {
                        "IndexName" => "string",
                        "ProvisionedThroughput" => {
                            "ReadCapacityUnits" => "number",
                            "WriteCapacityUnits" => "number"
                        }
                    }
               }
            ],
            "ProvisionedThroughput" => {
                "ReadCapacityUnits" => "number",
                "WriteCapacityUnits" => "number"
            },
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_UpdateTable.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_UpdateTable.html)

## query

Uses the primary key of a table or a secondary index to directly access items from that table or index.

- Request Data

        {
            "AttributesToGet" => [
                "string"
            ],
            "ConditionalOperator" => "string",
            "ConsistentRead" => "boolean",
            "ExclusiveStartKey" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                     ],
                     "M" => {
                         "string" => AttributeValue
                     },
                     "N" => "string",
                     "NS" => [
                         "string"
                     ],
                     "NULL" => "boolean",
                     "S" => "string",
                     "SS" => [
                         "string"
                     ]
                }
            },
            "ExpressionAttributeNames" => {
               "string" => "string"
            },
            "ExpressionAttributeValues" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "FilterExpression" => "string",
            "IndexName" => "string",
            "KeyConditionExpression" => "string",
            "KeyConditions" => {
                "string" => {
                    "AttributeValueList" => [
                        {
                            "B" => "blob",
                            "BOOL" => "boolean",
                            "BS" => [
                                "blob"
                            ],
                            "L" => [
                                AttributeValue
                            ],
                            "M" => {
                                 "string" => AttributeValue
                            },
                            "N" => "string",
                            "NS" => [
                                "string"
                            ],
                            "NULL" => "boolean",
                            "S" => "string",
                            "SS" => [
                                "string"
                            ]
                        }
                    ],
                    "ComparisonOperator" => "string"
                }
            },
            "Limit" => "number",
            "ProjectionExpression" => "string",
            "QueryFilter" => {
                "string" => {
                    "AttributeValueList" => [
                        {
                            "B" => "blob",
                            "BOOL" => "boolean",
                            "BS" => [
                                "blob"
                            ],
                            "L" => [
                                AttributeValue
                            ],
                            "M" => {
                                "string" => AttributeValue
                            },
                            "N" => "string",
                            "NS" => [
                                "string"
                            ],
                            "NULL" => "boolean",
                            "S" => "string",
                            "SS" => [
                                "string"
                            ]
                        }
                    ],
                    "ComparisonOperator" => "string"
                }
            },
            "ReturnConsumedCapacity" => "string",
            "ScanIndexForward" => "boolean",
            "Select" => "string",
            "TableName" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_Query.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_Query.html)

## scan

Returns one or more items and item attributes by accessing every item in a table or a secondary index.

- Request Data

        {
            "AttributesToGet" => [
                "string"
            ],
            "ConditionalOperator" => "string",
            "ExclusiveStartKey" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                    "N" => "string",
                    "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }

            },
            "ExpressionAttributeNames" => {
                "string" => "string"
            },
            "ExpressionAttributeValues" => {
                "string" => {
                    "B" => "blob",
                    "BOOL" => "boolean",
                    "BS" => [
                        "blob"
                    ],
                    "L" => [
                        AttributeValue
                    ],
                    "M" => {
                        "string" => AttributeValue
                    },
                   "N" => "string",
                   "NS" => [
                        "string"
                    ],
                    "NULL" => "boolean",
                    "S" => "string",
                    "SS" => [
                        "string"
                    ]
                }
            },
            "FilterExpression" => "string",
            "IndexName" => "string",
            "Limit" => "number",
            "ProjectionExpression" => "string",
            "ReturnConsumedCapacity" => "string",
            "ScanFilter" => {
                "string" => {
                    "AttributeValueList" => [
                        {
                            "B" => "blob",
                            "BOOL" => "boolean",
                            "BS" => [
                                "blob"
                            ],
                            "L" => [
                                AttributeValue
                            ],
                            "M" => {
                                "string" => AttributeValue
                            },
                            "N" => "string",
                            "NS" => [
                                   "string"
                            ],
                            "NULL" => "boolean",
                            "S" => "string",
                            "SS" => [
                                "string"
                            ]
                        }
                    ],
                    "ComparisonOperator" => "string"
                }
           },
           "Segment" => "number",
           "Select" => "string",
           "TableName" => "string",
           "TotalSegments" => "number"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_Scan.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_Scan.html)

## batch\_get\_item

Returns the attributes of one or more items from one or more tables.

- Requset Data

        {
            "RequestItems" => {
                "string" => {
                    "AttributesToGet" => [
                        "string"
                    ],
                    "ConsistentRead" => "boolean",
                    "ExpressionAttributeNames" => {
                        "string" => "string"
                    },
                    "Keys" => [
                        {
                            "string" => {
                                "B" => "blob",
                                "BOOL" => "boolean",
                                "BS" => [
                                    "blob"
                                ],
                                "L" => [
                                    AttributeValue
                                ],
                                "M" => {
                                    "string" => AttributeValue
                                },
                                "N" => "string",
                                "NS" => [
                                     "string"
                                ],
                                "NULL" => "boolean",
                                "S" => "string",
                                "SS" => [
                                     "string"
                                ]
                            }
                        }
                    ],
                    "ProjectionExpression" => "string"
                }
            },
           "ReturnConsumedCapacity" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_BatchGetItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_BatchGetItem.html)

## batch\_write\_item

Puts or Deletes multiple items in one or more tables.

- Request Data

        {
            "RequestItems" => {
                "string" => [
                    {
                        "DeleteRequest" => {
                            "Key" => {
                                "string" => {
                                    "B" => "blob",
                                   "BOOL" => "boolean",
                                    "BS" => [
                                        "blob"
                                    ],
                                    "L" => [
                                        AttributeValue
                                    ],
                                    "M" => {
                                        "string" => AttributeValue
                                    }
                                    "N" => "string",
                                    "NS" => [
                                        "string"
                                    ],
                                    "NULL" => "boolean",
                                    "S" => "string",
                                    "SS" => [
                                        "string"
                                    ]
                                }
                            }
                        },
                        "PutRequest" => {
                            "Item" => {
                                "string" => {
                                    "B" => "blob",
                                    "BOOL" => "boolean",
                                    "BS" => [
                                        "blob"
                                    ],
                                    "L" => [
                                        AttributeValue
                                    ],
                                    "M" => {
                                        "string" => AttributeValue
                                    },
                                    "N" => "string",
                                    "NS" => [
                                        "string"
                                    ],
                                    "NULL" => "boolean",
                                    "S" => "string",
                                    "SS" => [
                                        "string"
                                    ]
                                }
                            }
                        }
                    }
                ]
            },
            "ReturnConsumedCapacity" => "string",
            "ReturnItemCollectionMetrics" => "string"
        }

- SEE [http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API\_BatchWriteItem.html](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference//API_BatchWriteItem.html)

# CONTRIBUTORS

kablamo

# LICENSE

Copyright (C) Kazuhiro Shibuya.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazuhiro Shibuya <stevenlabs at gmail.com>
