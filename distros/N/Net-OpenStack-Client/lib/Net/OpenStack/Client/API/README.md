# API

The API service modules and pods are generated using the `genapi/gen.pl` script.
See the `genapi/README` for details how to add new service and/or methods.

# Methods

Methods can be called as follows:
* directly from base auth, using `api_<service>_<method>` method name
* TODO: instantiate a service instance via `service`, and then call `method`

TODO: If no endpoint is found, try to discover it.
TODO: If no version is set, use `CURRENT` from version API

# Code Flow

* Call method with args
  * AUTOLOAD in Client::API
    * retrieve from Client::API::Magic
      * looks for description/api data in Client::API::<Service>::<version>
      * if not found, looks for function in Client::Client::<Service>::<version>
    * process_args from Client::API::Magic
      * if Client::API:: is used
        * preps request instance based on data and args
        * executes and returns the request with rest(request) call
      * if Client:: is used
        * calls function as if it were a method

# TODO

Generate / prefill the value list from the API documentation.
