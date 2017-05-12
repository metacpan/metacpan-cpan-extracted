This directory contains test scripts
and configuration data for ServiceNow::SOAP.

Most of the tests in this directory require access
to a non-production ServiceNow instance.

You can use a corporate development instance
if you have one available,
or you can request a personal developer instance
at https://developer.servicenow.com

To run the full test suite you must copy the file
`test.sample.conf` 
to either
`test.config` or `.test.config`
and then modify the file.

Most test scripts will be skipped if the
config file cannot be located.
