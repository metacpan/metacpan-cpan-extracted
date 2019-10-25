package MongoHosting;
use strict;
use 5.008_005;
 
1;
__END__
 
=head1 NAME
 
  MongoHosting   deploy MongoDB shared cluster in the cloud at linode or digitalocean 
 
=head1 SYNOPSIS
 
  # INSTALL
  $ git clone git@github.com:ovntatar/MongoHosting.git
  $ cd MongoHosting
  $sudo apt-get install make gcc carton dialog libio-socket-ssl-perl libxml-parser-lite-perl libxml-dom-perl libxml-parser-perl libxml-xslt-perl libnet-ssleay-perl libcrypt-ssleay-perl libnet-https-any-perl libpoe-filter-ssl-perl
  $ carton install # install deps

  # ENV VARS - In order for the script to work you'll need to set 3 environment variables:
  ##  API Key for provider (eg. DigitalOcean, Linode, etc)
  $ export PROVIDER_API_KEY=121234123123213123123123123213123123123 

  ## Path to the private key you want to use to login into the machines
  $ export PRIVATE_KEY=/path/to/private/key/id_rsa

  ## Config file (defaults to config.yml)
  $ export DEPLOY_CONFIG=linode-config.yml

  # SETUP CLUSTER
  ## edit config.yml, then:
  $ carton exec rex deploy

  #REMOVE HOST - To remove a host from the cluster you need to run the following command

  $ carton exec rex remove
  # You'll be presented with a list of hosts to be removed. Pick as many as you want and hit OK and then confirm.

  #TESTING - After deploy is done you can connect to any Mongo router from the host defined at app_host at the config file and test it with something like this:

  mongo router-ip:port/admin
  use exampleDB
  sh.enableSharding("exampleDB")
  for (var i = 1; i <= 500; i++) db.exampleCollection.insert( { x : i } )
  db.exampleCollection.findOne()


 
=head1 DESCRIPTION
 
MongoHosting is a command line tool to set up a shared cluster at linode or digital ocean 

 
=head1 PERL VERSIONS

You can also specify the minimum perl required in C<cpanfile>:
 
  requires 'perl', '5.16.3';

=head1 AUTHOR
 
Ovidiu Tatar, Gabriel Andrade
 
=head1 COPYRIGHT
 
 3Ziele.de - ovntatar
 
=head1 LICENSE
 
This software is licensed under the same terms as Perl itself.
 
=head1 SEE ALSO
 
 
L<MongoHosting|https://github.com/ovntatar/MongoHosting>
 
 
=cut 

