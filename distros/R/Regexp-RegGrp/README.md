# NAME

Regexp::RegGrp - Groups a regular expressions collection

<div>

    <a href='https://travis-ci.org/leejo/regexp-reggrp-perl?branch=master'><img src='https://travis-ci.org/leejo/regexp-reggrp-perl.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/leejo/regexp-reggrp-perl'><img src='https://coveralls.io/repos/leejo/regexp-reggrp-perl/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

Version 2.00

# DESCRIPTION

Groups regular expressions to one regular expression

# SYNOPSIS

    use Regexp::RegGrp;

    my $reggrp = Regexp::RegGrp->new(
        {
            reggrp          => [
                {
                    regexp => '%name%',
                    replacement => 'John Doe',
                    modifier    => $modifier
                },
                {
                    regexp => '%company%',
                    replacement => 'ACME',
                    modifier    => $modifier
                }
            ],
            restore_pattern => $restore_pattern
        }
    );

    $reggrp->exec( \$scalar );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $reggrp->exec( \$scalar );

The first argument must be a hashref. The keys are:

- reggrp (required)

    Arrayref of hashrefs. The keys of each hashref are:

    - regexp (required)

        A regular expression

    - replacement (optional)

        Scalar or sub.

        A replacement for the regular expression match. If not set, nothing will be replaced except "store" is set.
        In this case the match is replaced by something like sprintf("\\x01%d\\x01", $idx) where $idx is the index
        of the stored element in the store\_data arrayref. If "store" is set the default is:

            sub {
                return sprintf( "\x01%d\x01", $_[0]->{store_index} );
            }

        If a custom restore\_pattern is passed to to constructor you MUST also define a replacement. Otherwise
        it is undefined.

        If you define a subroutine as replacement an hashref is passed to this subroutine. This hashref has
        four keys:

        - match

            Scalar. The match of the regular expression.

        - submatches

            Arrayref of submatches.

        - store\_index

            The next index. You need this if you want to create a placeholder and store the replacement in the
            $self->{store\_data} arrayref.

        - opts

            Hashref of custom options.

    - modifier (optional)

        Scalar. The default is 'sm'.

    - store (optional)

        Scalar or sub. If you define a subroutine an hashref is passed to this subroutine. This hashref has
        three keys:

        - match

            Scalar. The match of the regular expression.

        - submatches

            Arrayref of submatches.

        - opts

            Hashref of custom options.

        A replacement for the regular expression match. It will not replace the match directly. The replacement
        will be stored in the $self->{store\_data} arrayref. The placeholders in the text can easily be rereplaced
        with the restore\_stored method later.

- restore\_pattern (optional)

    Scalar or Regexp object. The default restore pattern is

        qr~\x01(\d+)\x01~

    This means, if you use the restore\_stored method it is looking for \\x010\\x01, \\x011\\x01, ... and
    replaces the matches with $self->{store\_data}->\[0\], $self->{store\_data}->\[1\], ...

# EXAMPLES

- Example 1

    Common usage.

        #!/usr/bin/perl

        use strict;
        use warnings;

        use Regexp::RegGrp;

        my $reggrp = Regexp::RegGrp->new(
            {
                reggrp          => [
                    {
                        regexp => '%name%',
                        replacement => 'John Doe'
                    },
                    {
                        regexp => '%company%',
                        replacement => 'ACME'
                    }
                ]
            }
        );

        open( INFILE, 'unprocessed.txt' );
        open( OUTFILE, '>processed.txt' );

        my $txt = join( '', <INFILE> );

        $reggrp->exec( \$txt );

        print OUTFILE $txt;
        close(INFILE);
        close(OUTFILE);

- Example 2

    A scalar is requested by the context. The input will remain unchanged.

        #!/usr/bin/perl

        use strict;
        use warnings;

        use Regexp::RegGrp;

        my $reggrp = Regexp::RegGrp->new(
            {
                reggrp          => [
                    {
                        regexp => '%name%',
                        replacement => 'John Doe'
                    },
                    {
                        regexp => '%company%',
                        replacement => 'ACME'
                    }
                ]
            }
        );

        open( INFILE, 'unprocessed.txt' );
        open( OUTFILE, '>processed.txt' );

        my $unprocessed = join( '', <INFILE> );

        my $processed = $reggrp->exec( \$unprocessed );

        print OUTFILE $processed;
        close(INFILE);
        close(OUTFILE);

# AUTHOR

Merten Falk, `<nevesenin at cpan.org>`. Now maintained by LEEJO

# BUGS

Please report any bugs or feature requests through the web interface at
[http://github.com/leejo/regexp-reggrp-perl/issues](http://github.com/leejo/regexp-reggrp-perl/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Regexp::RegGrp

# COPYRIGHT & LICENSE

Copyright 2010, 2011 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
