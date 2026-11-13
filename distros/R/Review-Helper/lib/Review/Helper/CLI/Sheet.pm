package Review::Helper::CLI::Sheet;
use v5.36;

our $VERSION = '0.001';

use Cpanel::JSON::XS();

use Review::Helper::DB;
use Review::Helper::VCS;
use Review::Helper::Sheet;

use Getopt::Yath;

option_group {group => 'sheet', category => 'Sheet Options'} => sub {
    option all => (type => 'Bool', description => 'Also list items already filled, with their current values, so they can be replaced.');
};

sub run($class, $settings, @args) {
    die "Usage: review-helper sheet [--all] FILE\n" unless @args == 1;
    my ($file) = @args;

    my $sheet = Review::Helper::Sheet->new(repo => Review::Helper::VCS->detect($file), db => Review::Helper::DB->open($file));
    # 'all' is also a method of the settings group, so it is read by name.
    print Cpanel::JSON::XS->new->canonical->utf8->pretty->encode($sheet->sheet(all => $settings->sheet->option('all')));
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Sheet - The review-helper sheet subcommand.

=head1 DESCRIPTION

    review-helper sheet [--all] FILE

Prints the fill sheet of the review's latest iteration as JSON: every item
still needing agent input. With C<--all>, also lists the items already
filled, with their current values and revs, so C<fill> can replace them.

=head1 SYNOPSIS

    Review::Helper::CLI->run(sheet => $file);

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Sheet->run($settings, $file)

Print the sheet for the review in C<$file>, every item with C<--all>. Dies
unless exactly one file is given.

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
