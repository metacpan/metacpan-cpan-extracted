package Net::Delicious::Constants::Config;
use strict;

# $Id: Config.pm,v 1.10 2008/03/03 16:55:04 asc Exp $

$Net::Delicious::Constants::Config::VERSION = '1.14';

=head1 NAME

Net::Delicious::Constants::Config - constant variables for Net::Delicious default configs.

=head1 SYNOPSIS

 use Net::Delicious::Constants qw (:config)

=head1 DESCRIPTION

Constant variables for Net::Delicious default configs.

=cut

use Net::Delicious::Constants qw(:uri);

=head1 CONSTANTS

=cut

=head2 DELICIOUS_CFG_STD

=cut

use constant DELICIOUS_CFG_STD => (endpoint          => URI_API,
                                   xml_parser        => 'simple',
                                   force_xml_objects => 0,
                                   debug             => 0,
                                   user              => '',
                                   pswd              => '',
                                   updates           => '');

=head2 DELICIOUS_CFG_API

=cut

use constant DELICIOUS_CFG_API => (tags => {"get"    => {},
                                            "rename" => {"old" => "required",
                                                         "new" => "required"}},

                                   "tags_bundles" => {"all"    => {},
                                                      "set"    => {"bundle" => "required",
                                                                   "tags" => "required"},
                                                      "delete" => {"bundle" => "required"}},

                                   update => {},

                                   posts => {"add"    => {"url"         => "required",
                                                          "description" => "",
                                                          "extended"    => "",
                                                          "tags"        => "",
                                                          "dt"          => "",
                                                          "shared"      => ";no",
                                                          "replace"     => ";no"},
                                             "delete" => {"url"         => "required"},
                                             "dates"  => {"tag" => ""},
                                             "recent" => {"tag" => "", "count" => ""},
                                             "get"    => { "tag" => "", "dt" => "", "url" => ""},
                                             "all"    => {},
                                             "update" => {}},
          );

=head2 DELICIOUS_CFG_PROPERTIES

=cut

use constant DELICIOUS_CFG_PROPERTIES => (date          => "tag,date,count,user",
                                          post          => "description,extended,href,time,parent,tag,others,shared",
                                          bundle        => "name, tag",
                                          user          => "name",
                                          subscriptions => "user, tag",
                                          tag           => "tag, count");
                                          
BEGIN {
    use vars qw (@EXPORT_OK);
    
    @EXPORT_OK = qw (DELICIOUS_CFG_STD
                     DELICIOUS_CFG_API
                     DELICIOUS_CFG_PROPERTIES);
}

=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Delicious>

L<Net::Delicious::Config>

L<Net::Delicious::Constants>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
