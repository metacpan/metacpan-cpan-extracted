package Review::Helper::CLI::Iterate;
use v5.36;

our $VERSION = '0.001';

use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::VCS;

use Getopt::Yath;

option_group {group => 'iterate', category => 'Iterate Options'} => sub {
    option base => (type => 'Scalar', description => "The commit the work starts from. Default: the previous iteration's base.");
    option head => (type => 'Scalar', description => 'The last commit to review. Default: HEAD.');
};

sub run($class, $settings, @args) {
    die "Usage: review-helper iterate FILE [--base REV] [--head REV]\n" unless @args == 1;
    my ($file) = @args;
    my $opts = $settings->iterate;

    my $db      = Review::Helper::DB->open($file);
    my $builder = Review::Helper::Builder->new(repo => Review::Helper::VCS->detect($file), db => $db);
    print $builder->iterate(map { ($_ => $opts->$_) } grep { defined $opts->$_ } qw/base head/), "\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Iterate - The review-helper iterate subcommand.

=head1 DESCRIPTION

    review-helper iterate FILE [--base REV] [--head REV]

Adds the next iteration to a review, pins it, and prints its number. The
base defaults to the previous iteration's base, the head to C<HEAD>. A
squashed or path-limited review stays so.

=head1 SYNOPSIS

    Review::Helper::CLI->run(iterate => $file);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Iterate->run($settings, $file)

Add an iteration to the review in C<$file>. Dies unless exactly one file is
given.

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
