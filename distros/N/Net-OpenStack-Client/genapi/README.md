# genapi

Generate the API perl modules from input JSON samples and minimal description


Format is similar to structure under Net::OpenStack::API

* every service is a directory
 * first letter uppercase
* a single file named <version>.ini is a version for that API
* file format
  * ini format
  * section name is method name
  * mandatory fields
    * description
    * method
    * url
      * without version prefix
      * templates in url have to be in `{name}` syntax
        * these will become mandatory options
  * optional
    * json (for POST): whole JSON on single line
    * result: select (part of) the JSON response
      * an absolute path: select that specific JSON subtree
      * anything else is interpreted as a response header

Produces the service/directory structure directly in lib/Net/OpenStack/API.

## Add service

Make new directory with service name. Add method <version>.ini file.

## Add method

In correct <Service>/<version>.ini file, add a section with mandatory and optional fields
as described above.
