# MongoHosting

## INSTALL 

```
  $ git clone git@github.com:ovntatar/MongoHosting.git
  $ cd MongoHosting
  # apt-get install make gcc carton dialog libio-socket-ssl-perl libxml-parser-lite-perl libxml-dom-perl libxml-parser-perl libxml-xslt-perl libnet-ssleay-perl libcrypt-ssleay-perl libnet-https-any-perl libpoe-filter-ssl-perl
  $ carton install # install deps

```

## ENV VARS
In order for the script to work you'll need to set 3 environment variables:

```
  ##  API Key for provider (eg. DigitalOcean, Linode, etc)
  $ export PROVIDER_API_KEY=121234123123213123123123123213123123123 
  ## Path to the private key you want to use to login into the machines
  $ export PRIVATE_KEY=/path/to/private/key/id_rsa
  ## Config file (defaults to config.yml)
  $ export DEPLOY_CONFIG=linode-config.yml
```

## SETUP CLUSTER

```
  ## edit config.yml, then:
  $ carton exec rex deploy
``` 

## REMOVE HOST
To remove a host from the cluster you need to run the following command

```
  $ carton exec rex remove
``` 

You'll be presented with a list of hosts to be removed. Pick as many as you want and hit `OK` and then confirm.


## TESTING

After deploy is done you can connect to any Mongo router from the host defined at `app_host` at the config file
and test it with something like this:

```
mongo router-ip:port/admin
use exampleDB
sh.enableSharding("exampleDB")
for (var i = 1; i <= 500; i++) db.exampleCollection.insert( { x : i } )
db.exampleCollection.findOne()

```
                        
                        
                        
                        
