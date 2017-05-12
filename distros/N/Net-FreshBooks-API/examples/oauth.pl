#!perl -w

use strict;
use warnings;

=head1 SYNOPSIS

Run this script to get your access token and secret.

=cut


use Find::Lib '.';

use OAuthDemo;

OAuthDemo->new_with_options->run;
