package Review::Helper::CLI::Feedback;
use v5.36;

our $VERSION = '0.001';

use Cpanel::JSON::XS();

use Review::Helper::DB;
use Review::Helper::Feedback;

use Getopt::Yath;

option_group {group => 'feedback', category => 'Feedback Options'} => sub {
    option open    => (type => 'Bool', description => 'Only feedback and requests that are still open.');
    option publish => (type => 'Bool', description => 'The feedback to post to the pull or merge request: the text and line anchor of each open item not posted yet, or of the items named by id.');
};

sub run($class, $settings, @args) {
    my $publish = $settings->feedback->publish;
    die "Usage: review-helper feedback FILE [--open | --publish [ID...]]\n" unless @args == 1 || ($publish && @args);
    die "--open and --publish do not combine\n" if $publish && $settings->feedback->open;
    my ($file, @ids) = @args;

    my $feedback = Review::Helper::Feedback->new(db => Review::Helper::DB->open($file));
    my $export   = $publish ? $feedback->publish(@ids) : $feedback->export(open => $settings->feedback->open);
    print Cpanel::JSON::XS->new->canonical->utf8->pretty->encode($export);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Feedback - The review-helper feedback subcommand.

=head1 DESCRIPTION

    review-helper feedback FILE [--open | --publish [ID...]]

Prints the review's feedback and requests as JSON. With C<--open>, only
those still open. With C<--publish>, what to post to the pull or merge
request instead: see C<publish> in L<Review::Helper::Feedback>.

=head1 SYNOPSIS

    Review::Helper::CLI->run(feedback => $file, '--open');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Feedback->run($settings, $file)

=item Review::Helper::CLI::Feedback->run($settings, $file, @ids)

Print the feedback export of the review in C<$file>, or with C<--publish>
the publish list, of the items C<@ids> when given. Dies unless exactly one
file is given, or a file and ids with C<--publish>, and on C<--open> with
C<--publish>.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
