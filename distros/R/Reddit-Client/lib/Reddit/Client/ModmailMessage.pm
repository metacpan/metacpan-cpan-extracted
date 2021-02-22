package Reddit::Client::ModmailMessage;
use strict;
use warnings; 
use Carp;

require Reddit::Client::Thing; # base doesn't require. use parent does
use base qw/Reddit::Client::Thing/; 
use fields qw/
author
body
bodyMarkdown
date
isInternal
/;

# no type, apparently. None listed in docs. Message is t4, but no indication
# these are Messages


