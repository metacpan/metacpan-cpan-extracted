package Reddit::Client::SubReddit;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/
created
created_utc
description
display_name
header_img
header_size
header_title
over18
public_description
public_traffic
quarantine
subreddit_type
subscribers
title
url  
/;         

use constant type => "t5";

# thse functions are currently unavailable
sub get_links {
    my ($self, %param) = @_;
    return $self->{session}->get_links(subreddit => $self->{display_name}, %param);
}

sub submit_link {
    my ($self, %param) = @_;
    $param{subreddit} = $self->{display_name};
    return $self->{session}->submit_link(%param);
}

sub submit_text {
    my ($self, %param) = @_;
    $param{subreddit} = $self->{display_name};
    return $self->{session}->submit_text(%param);
}

1;
__END__

=pod

=head1 NAME

Reddit::Client::SubReddit

=head1 DESCRIPTION

Provides convenience methods for interacting with SubReddits.

=head1 SUBROUTINES/METHODS

=over

=item links(...)

Wraps C<Reddit::Client::fetch_links>, providing the subreddit parameter implicitly.

=item submit_link($title, $url)

Wraps C<Reddit::Client::submit_link>, providing the subreddit parameter implicitly.

=item submit_text($title, $text)

Wraps C<Reddit::Client::submit_text>, providing the subreddit parameter implicitly.

=back

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut
