package Task::Date::Holidays;

use strict;
use warnings;
use vars qw($VERSION);
use 5.006;

$VERSION = '0.11';

1;

__END__

=pod

=begin markdown

# Task::Date::Holidays

[![CPAN version](https://badge.fury.io/pl/Task-Date-Holidays.svg)](http://badge.fury.io/pl/Task-Date-Holidays)
[![Build Status](https://travis-ci.org/jonasbn/perl-Task-Date-Holidays.svg?branch=master)](https://travis-ci.org/jonasbn/perl-Task-Date-Holidays)

=end markdown

=head1 NAME

Task::Date::Holidays - Work distribution for holiday modules in the Date::Holidays namespace

=head1 SYNOPSIS

    $ tar xvzf Task-Date-Holidays-0.11.tgz

    $ cd Task-Date-Holidays-0.11

    $ perl Build.PL

    $ ./Build install

    # hack, hack, hack

    # take some holiday

=head1 DESCRIPTION

THis distribution is intended to provide an easy way to install all of the Date::Holidays::* distributions.

Bundling these makes it easier for me, in the work related to maintaining L<Date::Holidays>.

If your distribution is missing send me a pull request or just let me know.

If you want to provide a distribution to the namespace, please see Date::Holidays for more information.

Do note that because a distribution is listed in the below list, does not necessarily make it compatible with the Date::Holidays API. Distributions listed here indicate that a given distribution is either compatible or being considered for inclusion.

Please see L<Date::Holidays>

=head1 CONTENTS

=over

=item * L<Date::Holidays::AT>

=item * L<Date::Holidays::AU>

=item * L<Date::Holidays::AW>

=item * L<Date::Holidays::BR>

=item * L<Date::Holidays::BY>

=item * L<Date::Holidays::CA>

=item * L<Date::Holidays::CA_ES>

=item * L<Date::Holidays::CN>

=item * L<Date::Holidays::CZ>

=item * L<Date::Holidays::DE>

=item * L<Date::Holidays::DK>

=item * L<Date::Holidays::ES>

=item * L<Date::Holidays::FR>

=item * L<Date::Holidays::GB>

=item * L<Date::Holidays::KR>

=item * L<Date::Holidays::KZ>

=item * L<Date::Holidays::NL>

=item * L<Date::Holidays::NO>

=item * L<Date::Holidays::NZ>

=item * L<Date::Holidays::PL>

=item * L<Date::Holidays::PT>

=item * L<Date::Holidays::RU>

=item * L<Date::Holidays::SK>

=item * L<Date::Holidays::UA>

=item * L<Date::Holidays::UK>

=item * L<Date::Holidays::USFederal>

=item * L<Date::Japanese::Holiday>

=back

=head1 SEE ALSO

=over

=item * L<Date::Holidays>

=item * L<Date::Holidays::Adapter>

=item * L<Date::Holidays::Abstract>

=item * L<Date::Holidays::Super>

=back

=head1 CONFIGURATION AND ENVIRONMENT

No special configuration or environment is required.

=head1 ISSUE REPORTING

Please report any bugs or feature requests using Github

=over

=item * L<Github Issues|https://github.com/jonasbn/perl-task-date-holidays/issues>

=back

=head1 AUTHOR

Jonas B., (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=over

=item * Alexander Nalobin (NALOBIN), patch for inclusion of Date::Holidays::RU, 0.04

=item * Gabor Szabo (SZABGAB), patch assisting META data generation, 0.03

=item * Alberto Simoes (AMBS), for patching Date::Holidays::PT which was broken

=back

=head1 LICENSE AND COPYRIGHT

Task-Date-Holidays and related modules are (C) by Jonas B., (jonasbn)
2014-2022

Task-Date-Holidays and related modules are released under the Artistic License 2.0

=cut
