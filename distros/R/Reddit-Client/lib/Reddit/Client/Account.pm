package Reddit::Client::Account;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/has_mail inbox_count created modhash created_utc link_karma 
              comment_karma is_gold is_mod has_mod_mail
	      features gold_creddits gold_expiration 
	      new_modmail_exists pref_no_profanity pref_show_snoovatar
	      suspension_expiration_utc verified subreddit in_beta is_employee
	      is_sponsor is_suspended pref_geopopular pref_top_karma_subreddits
	      over_18 has_subscribed hide_from_robots has_verified_email
	   /;

use constant type => "t2";

1;

__END__

=pod

=head1 NAME

Reddit::Client::Account

=head1 DESCRIPTION

Stores information about the logged in user account.

=head1 AUTHOR

<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut
