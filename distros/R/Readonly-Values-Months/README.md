# NAME

Readonly::Values::Months - Months Constants

# VERSION

Version 0.02

# SYNOPSIS

    use Readonly::Values::Months;

    # Simple month constants
    print "January is month number $JAN\n";    # January is month number 1
    print "December is month number $DEC\n";   # December is month number 12

    # Lookup a month number by name (case-insensitive keys)
    my $num = $months{'april'};     # 4
    print "April => $num\n";

    # Iterate full month names
    for my $name (@month_names) {
        printf "%-9s => %2d\n", ucfirst($name), $months{$name};
    }

    # Short names (first three letters)
    print 'Abbreviations: ', join(', ', @short_month_names), "\n";
    # Abbreviations: jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec

    # Exported symbols:
    #   $JAN ... $DEC
    #   %months
    #   @month_names
    #   @short_month_names

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-readonly-values-months at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Months](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Months).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Months

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Readonly-Values-Months](https://metacpan.org/dist/Readonly-Values-Months)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Months](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Months)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Readonly-Values-Months](http://matrix.cpantesters.org/?dist=Readonly-Values-Months)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Readonly::Values::Months](http://deps.cpantesters.org/?module=Readonly::Values::Months)

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
