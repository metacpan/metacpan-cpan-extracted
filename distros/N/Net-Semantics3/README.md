# semantics3-perl

Net::Semantics3 is a Perl client for accessing the Semantics3 Products API, which provides structured information, including pricing histories, for a large number of products.
See https://www.semantics3.com for more information.

API documentation can be found at https://www.semantics3.com/docs/

## Installation

Net::Semantics3 can be installed through the CPAN:
```
$ perl -MCPAN -e "install Net::Semantics3"
```
To build and install from the latest source:
```
$ git clone git@github.com:Semantics3/semantics3-perl.git
$ cd semantics3-perl
$ perl Makefile.PL
$ make
$ make test
$ make install
```

## Requirements

* LWP::UserAgent
* OAuth::Lite::Consumer
* JSON::XS

## Getting Started

In order to use the client, you must have both an API key and an API secret. To obtain your key and secret, you need to first create an account at
https://www.semantics3.com/
You can access your API access credentials from the user dashboard at https://www.semantics3.com/dashboard/applications

### Setup Work

Let's lay the groundwork.

```perl
use Net::Semantics3::Products;

# Your Semantics3 API Credentials
my $api_key = "SEM3xxxxxxxxxxxxxxxxxxxxxx";
my $api_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

# Set up a client to talk to the Semantics3 API
my $sem3 = Net::Semantics3::Products->new (
  api_key => $api_key,
  api_secret => $api_secret,
);
```

### First Query aka 'Hello World':

Let's make our first query! We are going to run a simple search fo the word "iPhone" as follows:

```perl
# Build the query
$sem3->products_field( "search", "iphone" );

# Make the query
my $productsRef = $sem3->get_products();

# View the results of the query
print STDERR Dumper( $productsRef );
```

## Sample Queries

The following queries show you how to interface with some of the core functionality of the Semantics3 Products API:

### Pagination

The example in our "Hello World" script returns the first 10 results. In this example, we'll scroll to subsequent pages, beyond our initial query:

```perl
# Build the query
$sem3->products_field( "search", "iphone" );

# Make the query
my $productsRef = $sem3->get_products();

# View the results of the query
print STDERR Dumper( $productsRef );

# Goto the next 'page'
my $page = 0;
while(my $productsRef = $sem3->iterate_products()) {
    $page++;
    print STDERR "We are at page = $page\n";
    print STDERR "The results for this page are:\n";
    print STDERR Dumper( $productsRef );
}
```

### UPC Query

Running a UPC/EAN/GTIN query is as simple as running a search query:

```perl
# Build the query
$sem3->products_field( "upc", "883974958450" );
$sem3->products_field( "field", ["name","gtins"] );

# Make the query
my $productsRef = $sem3->get_products();

# View the results of the query
print STDERR Dumper( $productsRef );
```

### URL Query

Get the picture? You can run URL queries as follows:

```perl
$sem3->products_field( "url", "http://www.walmart.com/ip/15833173" );
my $productsRef = $sem3->get_products();
print STDERR Dumper( $productsRef );
```

### Price Filter

Filter by price using the "lt" (less than) tag:

```perl
$sem3->products_field( "search", "iphone" );
$sem3->products_field( "price", "lt", 300 );
my $productsRef = $sem3->get_products();
print STDERR Dumper( $productsRef );
```

### Category ID Query

To lookup details about a cat_id, run your request against the categories resource:

```perl
# Build the query
$sem3->categories_field( "cat_id", 4992 );

# Make the query
my $categoriesRef = $sem3->get_categories();

# View the results of the query
print STDERR Dumper( $categoriesRef );
```

## Webhooks
You can use webhooks to get near-real-time price updates from Semantics3. 

### Creating a webhook

You can register a webhook with Semantics3 by sending a POST request to `"webhooks"` endpoint.
To verify that your URL is active, a GET request will be sent to your server with a `verification_code` parameter. Your server should respond with `verification_code` in the response body to complete the verification process.

```perl
my $params = {
    webhook_uri => "http://mydomain.com/webhooks-callback-url"
};

my $res = $sem3->run_query("webhooks", $params, "POST");
print STDERR Dumper( $res ), "\n";
```
To fetch existing webhooks
```perl
my $res = $sem3->run_query("webhooks", undef, "GET");
print STDERR Dumper( $res ), "\n";
```

To remove a webhook
```perl
my $webhook_id = "7JcGN81u";
my $endpoint = "webhooks/" . $webhook_id ;

my $res = $sem3->run_query( $endpoint, undef, "DELETE" );
print STDERR Dumper( $res );
```

### Registering events
Once you register a webhook, you can start adding events to it. Semantics3 server will send you notifications when these events occur.
To register events for a specific webhook send a POST request to the `"webhooks/{webhook_id}/events"` endpoint

```perl
my $params = {
    "type" => "price.change",
    "product" => {
        "sem3_id" => "1QZC8wchX62eCYS2CACmka"
    },
    "constraints" => {
        "gte" => 10,
        "lte" => 100
    }
};

my $webhook_id = "7JcGN81u";
my $endpoint = "webhooks/" . $webhook_id . "/events";

my $res = $sem3->run_query( $endpoint, $params, "POST" );
print STDERR Dumper( $res ), "\n";
```

To fetch all registered events for a give webhook
```perl
my $webhook_id = "7JcGN81u";
my $endpoint = "webhooks/" . $webhook_id . "/events";

my $res = $sem3->run_query($endpoint, undef, "GET");
print STDERR Dumper( $res ), "\n";
```

### Webhook Notifications
Once you have created a webhook and registered events on it, notifications will be sent to your registered webhook URI via a POST request when the corresponding events occur. Make sure that your server can accept POST requests. Here is how a sample notification object looks like
```javascript
{
    "type": "price.change",
    "event_id": "XyZgOZ5q",
    "notification_id": "X4jsdDsW",
    "changes": [{
        "site": "abc.com",
        "url": "http://www.abc.com/def",
        "previous_price": 45.50,
        "current_price": 41.00
    }, {
        "site": "walmart.com",
        "url": "http://www.walmart.com/ip/20671263",
        "previous_price": 34.00,
        "current_price": 42.00
    }]
}
```

## Additional utility methods

| method        | Description           
| ------------- |:-------------
| `$sem3->get_results_json()`     | returns the result json string from the previous query
| `$sem3->clear()`                | clears all the fields in the query
| `$sem3->run_query($endpoint, $rawJson, $method)`  | You can use this method to send raw JSON string in the request



## Contributing

Use GitHub's standard fork/commit/pull-request cycle.  If you have any questions, email <support@semantics3.com>.

## Author

* Sivamani VARUN <varun@semantics3.com>

## Copyright

Copyright (c) 2015 Semantics3 Inc.

## License

    The "MIT" License
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.


