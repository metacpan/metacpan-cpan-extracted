package Reddit::Client::SubReddit;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/over18 header_img created_utc header_title header_size
              description display_name created url title subscribers
              public_traffic public_description subreddit_type/;

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

<mailto:earth-tone@ubwg.net>

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
