net-cloudstack-api
==================

API specific libraries for CloudStack ( http://cloudstack.org ).

There does not appear to be a WSDL or other schema for the available commands. I couldn't find anything at
https://github.com/cloudstack (or https://git-wip-us.apache.org/repos/asf/incubator-cloudstack-dev, which appears to be a copy)
either. Tsk. Get on the ball Citrix!

However, I downloaded the rpms found at http://cloudstack.org/download.html--specifically,
/home/harleypig/Downloads/CloudStack-2.2.14-1-rhel6.2.tar.gz--and found the following files:

 oss/cloud-cli/etc/cloud/cli/commands.xml

This appears to have the basics for each available command, but it has no information on what level of permissions and no data type
information.

 oss/cloud-client/etc/cloud/management/commands-ext.properties
 oss/cloud-client/etc/cloud/management/commands.properties

These appear to have the permission levels for each command.

I've copied these files to a local directory called 'stuff'.

Between these files I should be able to generate some code.
